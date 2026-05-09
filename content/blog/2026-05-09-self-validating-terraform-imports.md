---
title: "Self-validating Terraform imports: detecting regressions at plan time"
date: 2026-05-09
tags:
- terraform
- iac
- testing
thumbnail: terraform4_thumb.png
teaser: How can a Terraform configuration prove — at plan time, before any apply — that importing an existing live resource does not change its behavior?
display_toc: true
intro: |
  When bringing existing cloud infrastructure under Terraform control via
  [`import` blocks](https://developer.hashicorp.com/terraform/language/import),
  it's often necessary to verify that the authored configuration perfectly
  matches live state. For smaller configurations, eyeballing the plan
  output is feasible. For large configurations with hundreds of resources -- or
  for resources whose state is opaque JSON -- it isn't.

  How can we automate assurances that an import-only Terraform change doesn't
  introduce regressions? In my experience, a few creative techniques may help:
  lifecycle postconditions on data sources, the Cloud Control API for resources
  whose typed schema is incomplete, and [conftest](https://www.conftest.dev/)
  policies on the plan JSON.
draft: true
---

## The problem

You're importing an existing collection of live cloud resources into Terraform
via `import` blocks. The desired outcome:

- `terraform apply` is a behavioral no-op against live infrastructure.
- The authored configuration matches live state in every way that
  matters.
- Future drift is detected on every subsequent plan.

`terraform plan` alone won't get you there. Plan output shows _Terraform's_
view of the diff between authored config and refreshed state, but:

- The provider's import codepath may populate state from one schema
  representation while authored config uses another, masking real drift.
- Some resource attributes (e.g., complex JSON blobs) are easy to glance
  over in plan output even when they encode meaningful behavior.
- A "no changes" plan only proves that _Terraform_ thinks nothing
  changes — not that the authored config truly mirrors live.

The techniques below shift verification _into the plan itself_, ensuring a CI
plan job fails on any drift between authored config and live state.

## Layer 1: native data sources + lifecycle postconditions

For attributes a typed data source already exposes, the simplest gate is
a [lifecycle
postcondition](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#preconditions-and-postconditions)
that compares the authored value against the live value, returned by a
data source.

Consider an [`aws_wafv2_ip_set`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set)
being adopted via an `import` block. The corresponding [`aws_wafv2_ip_set` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/wafv2_ip_set) exposes
`addresses`, so the postcondition can perform a pure-HCL set comparison:

```terraform
# Adopt the existing live IP set into Terraform state.
import {
  to = aws_wafv2_ip_set.main
  id = "my-allowlist/abc123-def456-.../REGIONAL"
}

# Live state, fetched fresh on every plan.
data "aws_wafv2_ip_set" "live" {
  name  = "my-allowlist"
  scope = "REGIONAL"
}

resource "aws_wafv2_ip_set" "main" {
  name               = "my-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.allowed_cidrs

  lifecycle {
    postcondition {
      condition = toset(self.addresses) == toset(data.aws_wafv2_ip_set.live.addresses)
      error_message = format(
        "IPv4 allowlist drift: only-authored=%v only-live=%v",
        setsubtract(toset(self.addresses), toset(data.aws_wafv2_ip_set.live.addresses)),
        setsubtract(toset(data.aws_wafv2_ip_set.live.addresses), toset(self.addresses)),
      )
    }
  }
}
```

The plan fails if `var.allowed_cidrs` doesn't match the live IP set,
with a diff in the error message surfacing the discrepancy.

The same pattern works for any resource whose typed data source offers
the relevant field — regex pattern sets via
[`aws_wafv2_regex_pattern_set`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/wafv2_regex_pattern_set), security group rules via
[`aws_security_group`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group),
DNS records via [`aws_route53_record`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_record), and so on.

For example, applied to a regex pattern set:

```terraform
import {
  to = aws_wafv2_regex_pattern_set.main
  id = "my-excluded-paths/abc123-def456-.../REGIONAL"
}

data "aws_wafv2_regex_pattern_set" "live" {
  name  = "my-excluded-paths"
  scope = "REGIONAL"
}

resource "aws_wafv2_regex_pattern_set" "main" {
  name  = "my-excluded-paths"
  scope = "REGIONAL"

  dynamic "regular_expression" {
    for_each = var.regex_excludes
    content {
      regex_string = regular_expression.value
    }
  }

  lifecycle {
    postcondition {
      condition = (
        toset(var.regex_excludes)
        == toset([for r in data.aws_wafv2_regex_pattern_set.live.regular_expression : r.regex_string])
      )
      error_message = format(
        "Regex pattern set drift: only-authored=%v only-live=%v",
        setsubtract(
          toset(var.regex_excludes),
          toset([for r in data.aws_wafv2_regex_pattern_set.live.regular_expression : r.regex_string]),
        ),
        setsubtract(
          toset([for r in data.aws_wafv2_regex_pattern_set.live.regular_expression : r.regex_string]),
          toset(var.regex_excludes),
        ),
      )
    }
  }
}
```

## Layer 2: Cloud Control API as an escape hatch

What if the typed AWS provider data source doesn't expose the field
you need to compare? The [`aws_wafv2_web_acl` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/wafv2_web_acl), for instance,
currently returns only `arn`, `description`, and `id` — not the rule body that
defines what the ACL actually _does_.

This matters more than it first sounds. The plan diff alone is a poor
"does authored config match live state?" signal for two compounding reasons:

- **Refreshed state isn't live state.** The plan shows authored config vs.
  refreshed _Terraform state_, which is the provider's interpretation
  of live AWS — not live AWS itself. When the provider stores a value
  under a different attribute than the one being authored (more on
  this in the [`rule_json` challenges](#rule_json-is-empty-in-state-on-first-import)
  section below), the plan can show a giant diff that's a
  representational artifact rather than a real authored-vs-live
  delta — or, conversely, hide a real delta the provider didn't
  surface.
- **Byte-level noise.** Even when refreshed state _does_ track live,
  two API representations of the same logical content can differ on
  key ordering, default-empty fields, casing, and auto-managed
  entries that rotate over time. Eyeballing thousands of lines of
  plan output for behaviorally-meaningful changes is impractical.

A separate live-state read, independent of TF state's representation,
sidesteps both. The
[`aws_cloudcontrolapi_resource`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudcontrolapi_resource)
data source helps. It wraps the
[AWS Cloud Control API](https://docs.aws.amazon.com/cloudcontrolapi/),
which exposes any CloudFormation-modeled resource as a generic
properties JSON string.

```terraform
data "aws_cloudcontrolapi_resource" "live_web_acl" {
  type_name  = "AWS::WAFv2::WebACL"
  identifier = "my-acl|abc123-def456-...|REGIONAL"
}

locals {
  live_rules = jsondecode(data.aws_cloudcontrolapi_resource.live_web_acl.properties).Rules
}
```

`local.live_rules` now holds the live rule body — the same data the
WAFv2 API's `GetWebACL` returns — accessible to a postcondition. For
example:

```terraform
import {
  to = aws_wafv2_web_acl.main
  id = "abc123-def456-.../my-acl/REGIONAL"
}

resource "aws_wafv2_web_acl" "main" {
  name  = "my-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule_json = local.authored_rule_json

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "my-acl"
  }

  lifecycle {
    postcondition {
      condition = jsonencode(local.live_rules) == jsonencode(jsondecode(local.authored_rule_json))
      error_message = "Web ACL rule body diverges from authored rule_json."
    }
  }
}
```

However, sometimes raw `jsonencode` equality is too brittle (key order,
default-empty fields, and casing differences trip it up); see
[Layer 3](#layer-3-canonicalize-before-comparing) for the
canonicalization steps that make the comparison reliable.

The same pattern is applicable any time the legacy AWS provider's
typed schema is incomplete: pivot to Cloud Control via
`type_name = "AWS::Service::ResourceType"` and project just the field
of interest out of `properties`.

The [`hashicorp/awscc`](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs)
provider — auto-generated from the same CloudFormation registry — is
another option, often with friendlier ergonomics. Its plural data
sources (e.g., `awscc_shield_protections`) are particularly useful for
enumerating all instances of a resource type for out-of-band drift
detection (see "Out-of-band resources" below).

## Layer 3: canonicalize before comparing

When the comparison target is a JSON blob rather than a flat set, raw
equality is rarely enough. Two byte-different JSON strings can encode
the same logical content if any of the following differ:

- Map key ordering.
- Whitespace and indentation.
- Default-empty fields one side includes and the other omits.
- Casing of structural keys (e.g., `Arn` vs `ARN`).
- Auto-managed entries that rotate over time.

In my experience, ~three normalization techniques tend to handle the bulk of these:

**1. Name-key, then `jsonencode`.** Reshape both sides into a map keyed by
some stable identifier (e.g., a rule's `Name`) and `jsonencode` the
result. `jsonencode` produces deterministic key ordering, so two
logically-equal maps produce byte-equal strings.

```terraform
locals {
  live_canonical = jsonencode({
    for r in local.live_rules : r.Name => r
  })

  authored_canonical = jsonencode({
    for r in jsondecode(local.rule_json) : r.Name => r
  })
}
```

**2. Strip default-empty fields.** CloudFormation (and therefore Cloud
Control) tends to populate fields like `RuleLabels: []` and
`ExcludedRules: []` even when they're empty, while the underlying
service API (and authored config) omits them entirely. A regex strip on
the JSON encoding handles every depth uniformly:

```terraform
locals {
  _empty_pattern = "(?:RuleLabels|ExcludedRules|ManagedRuleGroupConfigs)"

  stripped = replace(
    replace(jsonencode(thing), "/,\"${local._empty_pattern}\":\\[\\]/", ""),
    "/\"${local._empty_pattern}\":\\[\\],/", "",
  )
}
```

Two passes handle either comma placement (`,"FIELD":[]` mid-object,
`"FIELD":[],` start-of-object). HCL's `for` expressions can't recurse
into arbitrary nested structures, so a string-level regex on the
serialized form is the practical approach.

**3. Normalize representational differences.** When two APIs disagree on
casing or naming for the same field — Cloud Control uses PascalCase
`Arn`, the WAFv2 API uses uppercase `ARN`, etc. — rewrite the JSON-key
syntax before comparison:

```terraform
locals {
  normalized = replace(stripped, "\"Arn\":", "\"ARN\":")
}
```

Anchoring the rewrite to JSON key syntax (`"Arn":`) prevents collisions
with values that happen to contain the same substring.

The postcondition then becomes a simple string equality on the
canonical forms:

```terraform
resource "aws_wafv2_web_acl" "main" {
  # ...
  rule_json = local.authored_rule_json

  lifecycle {
    postcondition {
      condition = local.live_canonical == local.authored_canonical
      error_message = format(
        "rule body diverges from authored rule_json (live sha256=%s, authored sha256=%s)",
        sha256(local.live_canonical),
        sha256(local.authored_canonical),
      )
    }
  }
}
```

## Layer 4: out-of-band resource detection

Consider a separate failure mode: someone (or some automation) creates a
resource directly in AWS that the Terraform root module _doesn't_ manage but
_should_ — adjacent to the resources it does manage, in the blast
radius of any future change.

The pattern: enumerate every live instance of a resource type, then
assert via postcondition that each one is either Terraform-managed or
explicitly allowlisted as known unmanaged.

```terraform
data "awscc_shield_protections" "live_ids" {}

data "awscc_shield_protection" "live" {
  for_each = data.awscc_shield_protections.live_ids.ids
  id       = each.key

  lifecycle {
    postcondition {
      condition = (
        # FMS-managed protections are auto-named — passes.
        startswith(coalesce(self.name, ""), "FMManagedShieldProtection")
        # Explicit allowlist of known direct protections — passes.
        || contains(var.expected_outofband_protection_ids, self.protection_id)
      )
      error_message = format(
        "Out-of-band Shield protection: protection_id=%s name=%s. Either bring under Terraform, remove from AWS, or add to the allowlist.",
        self.protection_id, self.name,
      )
    }
  }
}
```

Each protection is one Cloud Control GetResource call at refresh time,
bounded by the count of protections in the account. The cost is
proportional to live state, paid once per plan.

This functions as an _ongoing_ gate, not a first-import one: it catches new
out-of-band resources on every future plan.

## Layer 5: conftest policies on the plan JSON

Native Terraform postconditions guard the resource lifecycle but can't
see properties of the plan itself: how many resources are being
destroyed, whether a sensitive resource is being modified, whether a
specific attribute changed value. For that, [`conftest`](https://www.conftest.dev/) — wrapping
[OPA](https://www.openpolicyagent.org/) Rego — evaluates policies
against the plan JSON.

In my experience, there are three useful policy shapes for import-and-validate work:

**1. Drift detection across a JSON-encoded attribute.** A `warn` rule
that surfaces add/remove/modify deltas between `change.before` and
`change.after` for a JSON-encoded attribute, summarized by stable
identifier:

```rego
package main

import rego.v1

warn_rule_body_drift contains msg if {
  some r in input.resource_changes
  r.type == "aws_wafv2_web_acl"
  is_update_or_replace(r.change.actions)

  before := json.unmarshal(r.change.before.rule_json)
  after  := json.unmarshal(r.change.after.rule_json)
  before != after

  msg := sprintf(
    "WAF Web ACL '%s' rule body changed — added: %v, removed: %v, modified: %v",
    [
      r.address,
      added_rules(before, after),
      removed_rules(before, after),
      modified_rules(before, after),
    ],
  )
}

added_rules(b, a) := {n | some rule in a; n := rule.Name; not name_in(n, b)}
removed_rules(b, a) := {n | some rule in b; n := rule.Name; not name_in(n, a)}
modified_rules(b, a) := {n | some rb in b; some ra in a; rb.Name == ra.Name; rb != ra; n := rb.Name}
```

`warn` rather than `deny` because rule body changes are routinely
intentional. The goal is to make sure a reviewer sees the structural
diff, the same way a manual diff tool would surface it.

**2. Fingerprint-tag transition warnings.** A SHA-256 of the JSON-encoded
attribute, written into the resource as a tag, gives a one-line
fingerprint that flips on any meaningful change. Conftest can warn on
transitions:

```terraform
resource "aws_wafv2_web_acl" "main" {
  # ...
  rule_json = local.rule_json

  tags = {
    "rule-json-sha256" = sha256(local.rule_json)
  }
}
```

```rego
warn_fingerprint_changed contains msg if {
  some r in input.resource_changes
  before := object.get(r.change.before, ["tags", "rule-json-sha256"], "")
  after  := object.get(r.change.after, ["tags", "rule-json-sha256"], "")
  before != ""
  after != ""
  before != after
  msg := sprintf("WAF '%s' rule body fingerprint flipped %s → %s", [r.address, before, after])
}
```

**3. Provider-bug-trip prevention.** Some provider bugs only surface
under specific authoring shapes. Encode the constraint as a `deny` rule
on the plan JSON so it's caught at policy time rather than at refresh
time:

```rego
deny contains msg if {
  some r in input.resource_changes
  r.type == "aws_wafv2_web_acl"
  some rule in json.unmarshal(r.change.after.rule_json)
  depth_three_or_more(rule.Statement)
  msg := sprintf(
    "WAF '%s' rule %q has 3+ chained logical operators — trips provider state-flatten bug",
    [r.address, rule.Name],
  )
}
```

(Bounded unrolling — Rego forbids recursive rules, so chains beyond a
fixed depth need explicit unrolled checks.)

## The unique challenges of `rule_json`

Most of the above techniques apply broadly. A few wrinkles are specific
to AWS WAFv2's
[`rule_json`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl#rule_json-1)
attribute, where the resource's authoritative behavior lives in a JSON
blob rather than typed HCL blocks.

### `rule_json` is empty in state on first import

When the AWS provider imports a WAFv2 Web ACL, it populates the typed
`rule { }` block schema from the API response — _not_ `rule_json`. So
on the first plan after `import`, `change.before.rule_json` is empty,
even when live AWS has a fully-populated rule body.

Two consequences follow, both important:

- **The plan diff is misleading.** The plan shows a giant
  `+ rule_json = jsonencode([...])` block for every imported Web ACL —
  not because the authored body differs from live AWS, but because TF
  state has no `rule_json` to compare against. The diff is a
  representational artifact, not an authored-vs-live delta. Eyeballing
  it can't tell a reviewer whether the authored config actually
  matches live behavior.
- **Conftest is vacuously true.** Any policy comparing
  `change.before.rule_json` to `change.after.rule_json` passes
  trivially because `before` is empty.

This is the central reason the Cloud Control postconditions in
[Layer 2](#layer-2-cloud-control-api-as-an-escape-hatch) matter most
on first import: they read live state directly — independently of TF
state's representation — and assert authored ≡ live byte-for-byte
after canonicalization. With the lifecycle postconditions in place,
the plan fails if they diverge, regardless of how the plan diff looks.

The order of operations inverts across the import lifecycle:

- **Before first apply:** the lifecycle postconditions in
  `web_acls.tf` (Layer 3 above) are the authoritative gate. They
  compare authored `rule_json` against live state fetched via Cloud
  Control, ignoring what's in Terraform state entirely.
- **After first apply:** `rule_json` lands in state, and from that
  point on, `change.before.rule_json` is populated with what
  Terraform last wrote. The conftest `rule_body_drift` policy
  becomes the operative steady-state gate.

The Cloud Control postconditions can be removed as a follow-up cleanup
once steady state is reached — or kept as belt-and-suspenders against
out-of-band edits.

### The SHA-256 tag postcondition is tautological

It's tempting to gate via `self.tags["rule-json-sha256"] ==
sha256(local.rule_json[k])` in a postcondition. This _looks_ like it
asserts something — and it does, but tautologically. In a postcondition,
`self` is the planned value, which already includes the planned tag,
which is by definition `sha256(local.rule_json[k])`. The check
self-references and always passes.

For the SHA tag to be a meaningful gate, compare it against a separate
data source's view of live state — at which point it adds nothing
beyond a direct rule body comparison via Cloud Control. The tag is most
useful as a _signal_ in plan diffs and console UIs, with the actual
gate elsewhere.

### Auto-managed rule entries

Some service features add rules out-of-band that aren't authorable via
`rule_json`. AWS Shield Advanced, for example, injects
`ShieldMitigationRuleGroup_*` rules at priority 10000000 with rotating
UUIDs during active mitigations. These would surface as rule-body
drift on every plan unless filtered. Strip them at canonicalization
time, in both the live-vs-authored postcondition and the conftest
drift policy:

```rego
filter_aws_managed(rules) := [r |
  some r in rules
  not is_aws_managed(r)
]

is_aws_managed(rule) if {
  rule.Priority >= 10000000
  contains(rule.Statement.RuleGroupReferenceStatement.ARN, ":<aws-internal-account-id>:")
}
```

The same pattern -- strip rotating, service-managed entries before
comparing -- applies any time the live shape includes things the author
can't (or shouldn't) own.

### Provider bug `#44009`: nesting depth ≥ 3

The AWS provider's WAFv2 typed `rule { }` schema currently fails to
refresh `Not(Or(IPv4, IPv6))` and other depth-≥-3 logical-operator
trees correctly (see [`hashicorp/terraform-provider-aws#44009`](https://github.com/hashicorp/terraform-provider-aws/issues/44009)).
`rule_json` sidesteps this by avoiding the typed schema entirely on
the write path, but only if the live rule body is also at depth ≤ 2.

If live state has a depth-3 statement that pre-dates the import, the
options are: (1) flatten it live via `update-web-acl` before importing
(De Morgan's laws give logical equivalents — `!(A ∨ B) ≡ !A ∧ !B`);
(2) accept refresh failures until the provider bug is fixed.

The `scope_down_depth.rego` policy above guards the authored side
against future regressions: a contributor who edits the rule builder
to emit a depth-3 statement gets a deny in CI rather than a refresh
failure six months later.

## Putting it together

| Layer | Mechanism | What it catches |
|---|---|---|
| 1 | Native data source + lifecycle postcondition | Drift on attributes the typed data source exposes (IP set addresses, regex patterns) |
| 2 | Cloud Control API data source | Drift on attributes the typed schema doesn't expose (WAFv2 rule body) |
| 3 | JSON canonicalization (name-key, strip empties, casing normalization) | False-positive diffs from representation differences |
| 4 | Plural Cloud Control data source + per-instance postcondition | Out-of-band resources adjacent to managed ones |
| 5 | conftest policies on plan JSON | Plan-level drift, fingerprint transitions, provider-bug-tripping shapes |

Each layer compensates for the others' gaps. Postconditions catch
authored-vs-live drift; conftest catches plan-level patterns
postconditions can't see; out-of-band gates catch what the configuration
explicitly _doesn't_ manage but lives next to what it does.

The result is a Terraform plan that _proves_ — at plan time, before
apply — that the import-only change is behaviorally inert against live
infrastructure. This simplifies the reviewer's job to confirming that
the gates themselves are sound, rather than visually diffing thousands
of lines of plan output (and PS - [the gates' correctness can even be tested](/blog/verifying-and-validating-terraform-techniques-for-testing-infrastructure-as-code/#terraform-test-with-mock-providers)).

## Further reading

- [Terraform custom conditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions)
- [Terraform import blocks](https://developer.hashicorp.com/terraform/language/import)
- [AWS Cloud Control API](https://docs.aws.amazon.com/cloudcontrolapi/)
- [Open Policy Agent Terraform support](https://www.openpolicyagent.org/docs/latest/terraform/)
- [conftest](https://www.conftest.dev/)
- [Verifying and validating Terraform: techniques for testing infrastructure-as-code](/blog/verifying-and-validating-terraform-techniques-for-testing-infrastructure-as-code/)
- [Terraform: self-validating plan-time permissions checks](/blog/terraform-self-validating-plan-time-permissions-checks/)
- [Terraform Plan Validation With Open Policy Agent](/blog/terraform-plan-validation-with-open-policy-agent/)

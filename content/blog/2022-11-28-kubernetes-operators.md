---
title: What is the Kubernetes Operator Pattern?
date: 2022-11-28
tags:
- kubernetes
- platform engineering
thumbnail: kubernetes_thumb.png
teaser: An introduction to the Kubernetes operator pattern.
---

_An overview of the [Kubernetes operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) and the use of custom resources and custom controllers in extending [Kubernetes](https://kubernetes.io/) functionality._

## What?

Broadly speaking, Kubernetes operators seek to abstract, codify, and automate operational tasks beyond what out-of-the-box Kubernetes itself provides.

As summarized in the [CNCF Operator Whitepaper](https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md#executive-summary):

> In Kubernetes, an operator provides intelligent, dynamic management capabilities by extending the functionality of the API.
>
> These operator components allow for the automation of common processes as well as reactive applications that can continually adapt to their environment. This in turn allows for more rapid development with fewer errors, lower mean-time-to-recovery, and increased engineering autonomy.

## Why?

By default, the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/) enables querying and manipulating common, built-in [API objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/), such as Pods, Namespaces, Deployments, ConfigMaps, etc. However, through operators, the core Kubernetes API can be extended -- and enhanced -- beyond these core objects to support higher level abstractions pertaining to more specific, less generic workloads.

In effect, operators enable platform engineers to codify and automate the operational logic associated with an application or workload, thereby abstracting features like resilience, deployment behavior, autoscaling, advanced routing, configuration, etc. into discreet software components. These discreet components -- _operators_ -- may have their own develop, build, test, version, and release lifeycle, and offer operational solutions that can be repeatably installed into underlying Kubernetes clusters to enhance those clusters' capabilities.

Arguably, this is especially compelling considering the growing ubiquity of Kubernetes, and operators' natural, low friction compatibility with teams' existing Kubernetes platform tooling (CI/CD pipelines, [helm](http://helm.sh), [kustomize](https://kustomize.io/), `kubectl`, observability tools, platform [RBAC](https://en.wikipedia.org/wiki/Role-based_access_control), etc.)

A few examples:

* [GlooEdge](https://github.com/solo-io/gloo) offers an ingress controller and API gateway
* [operatorhub.io](https://operatorhub.io/) offers numerous operator examples
* The [operator-sdk tutorial](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/) offers an example of an operator that abstracts a [memcached](https://memcached.org/) deployment

## How?

The operator pattern leverages two constructs:

1. custom resources
1. custom controllers

## Custom Resources

* A resource is a Kubernetes API endpoint pertaining a collection of a certain **kind** of object. Pods, Services, ConfigMaps, and Namespaces are common, core examples.
* A custom resource enhances the built-in Kubernetes API via a **Custom Resource Definition** or via **API aggregation**

Custom resources can be created via the [CustomResourceDefinition API](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) by specifying the custom resource in YAML; a subsequent `kubectl apply` of this YAML installs the resource into the cluster.

For example, consider a contrived `Foo` custom resource definition saved to a `foo-crd.yaml` file:

```yaml
# foo-crd.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: foos.stable.mikeball.info
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: stable.mikeball.info
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v1
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                foo:
                  type: string
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: foos
    # singular name to be used as an alias on the CLI and for display
    singular: foo
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: Foo
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - f
```

To install the `Foo` custom resource definition to a cluster:

```
kubectl apply -f foo-crd.yaml
customresourcedefinition.apiextensions.k8s.io/foos.stable.mikeball.info created
```

Once created, authorized users can create instances of the `kind: Foo` resource type and perform CRUD actions against those instances, just as can be done for the built-in resources.

For example, consider an instance of a `Foo` specified in YAML and saved to a `foo.yaml` file:

```yaml
# foo.yaml
apiVersion: "stable.mikeball.info/v1"
kind: Foo
metadata:
  name: my-foo
spec:
  foo: "bar"
```

To create the `my-foo` instance of the `Foo` resource on a cluster where the `kind: Foo` custom resource has been installed:

```
kubectl apply -f foo.yaml
foo.stable.mikeball.info/my-foo created
```

Subsequently, instances of `Foo` can be read from the cluster:

```txt
kubectl get foos
NAME     AGE
my-foo   3s
```

See [Extend the Kubernetes API with CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) for more details on the specifics.

Optionally, Kubernetes' [aggregation layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) accommodates further, more flexible extension of the Kubernetes API via API aggregation. While Custom Resources make Kubernetes recognize new kinds of objects, the aggregation layer supports the registration of "add-on" extension API servers in association with URL paths. For example, when an extension API server is registered in association with `/apis/stable.mikeball.info/v1/*` paths, the aggregation layer proxies requests to these paths to the associated extension API server. Typically, the underlying extension API server is running on pods within the cluster and is itself associated with one or more _custom controllers_.

## Custom Controllers

* Custom controllers are programs installed on a Kubernetes cluster that use the Kubernetes API to reconcile -- and transform -- installed resources' actual state with the desired state specified by the resource. This is referred to as the _controller pattern_.
* In the context of an operator, custom controllers reconcile the desired and actual state of _custom_ resources (On their own -- in absence of an associated controller -- custom resources merely expose a way to set the desired state and read the actual state, but offer no mechanism by which the actual state is actually transformed to the desired state).
* Controllers leverage the [Reconciler Pattern](https://www.oreilly.com/library/view/cloud-native-infrastructure/9781491984291/ch04.html), just as core Kubernetes does in managing built-in, non-custom resources too.
* Controllers often use methods exposed by the Kubernetes API to watch for key events pertaining to resources and act accordingly based on their business logic.

While the specific implementation details are a bit beyond the scope of this introduction, [kubebuilder](https://book.kubebuilder.io/cronjob-tutorial/controller-overview.html) -- a framework for building Kubernetes APIs using CRDs in Go -- offers a useful overview of [What's in a Controller?](https://book.kubebuilder.io/cronjob-tutorial/controller-overview.html) Considering this overview, a Go-based `Foo` controller built using `kubebuilder` might start looking something like the following (big disclaimer: this is a crude and incomplete example that glosses over lotsa details):

```golang
package controllers

import (
	"context"

	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

// FooReconciler reconciles a Foo object.
type FooReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// Reconcile performs the reconciling for a single named Foo object.
// The Reconcile function compares the state specified by the Foo object
// against the actual cluster state, and then performs operations to make
// the cluster state reflect the state specified by the user.
func (f *FooReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)

  // fetch the Foo using the client
	var foo Foo
	if err := f.Get(ctx, req.NamespacedName, &foo); err != nil {
		log.Error(err, "unable to fetch Foo")
		return ctrl.Result{}, err
	}

	// reconciliation logic would live here

	return ctrl.Result{}, nil
}

// SetupWithManager ensures the FooReconciler is started when the manager
// is started. The manager keeps track of running all of the controllers.
// NOTE: In this crude example, the Foo type is undefined.
// A real-world implementation would would define Foo, and SetupWithManager
// would be invoked from the program's main function as hinted at in..
// https://book.kubebuilder.io/cronjob-tutorial/empty-main.html
// ...and in...
// https://book.kubebuilder.io/cronjob-tutorial/main-revisited.html
func (f *FooReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&Foo{}).
		Complete(r)
}
```

For other, relatively simple controller examples:

* [Tutorial: Building CronJob](https://book.kubebuilder.io/cronjob-tutorial/cronjob-tutorial.html) explains the use of `kubebuilder` to build a `CronJob` custom resource and controller.
* [Writing a Controller for Pod Labels](https://kubernetes.io/blog/2021/06/21/writing-a-controller-for-pod-labels/) is a helpful tutorial that illustrates the controller pattern's use operating on core Kubernetes resources, in absence of _custom_ resources.

See the [Kubernetes controller documentation](https://kubernetes.io/docs/concepts/architecture/controller/) for more on controllers and the controller pattern.

## Summary: Operators, CRDs, Controllers, and Terminology

While operators, controllers, and custom resources are distinct constructs, the terms are frequently conflated and used somwhat interchangeably. After all, their conceptual boundaries are somewhat blurry; in practice, one's existence often implies the others' existence.

However, Kubernetes custom resources don't _require_ a corresponding controller, though a custom resource without a controller reconciling desired and actual resource state is arguably little more than a data store. Similarly, a custom controller doesn't need to operate on a custom resource; custom controllers may exercise custom logic on built-in Kubernetes resources (For example, [Caddy Ingress Controller](https://github.com/caddyserver/ingress/tree/v0.1.3) uses existing, core resources to enable [caddy](https://github.com/caddyserver/caddy)-based ingress via a custom, purpose-built controller. Similarly, [Writing a Controller for Pod Labels](https://kubernetes.io/blog/2021/06/21/writing-a-controller-for-pod-labels/) shows how the [operator-sdk](https://sdk.operatorframework.io/) could be used to write a single controller in absence of a custom resource).

Nonetheless, the _operator pattern_ -- strictly speaking -- typically relies on one or more custom controllers operating on one or more custom resources towards the goal of codifying operational knowledge pertaining to a specific application or workload (Or at least that's my conception. Disagree? [Submit a PR](http://github.com/mdb/mdb.github.io) if you feel I've misprepresented something).

That said, it's worth noting the [Kubernetes documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/#combining-new-apis-with-automation) itself articulates all this a bit differently:

> A combination of a custom resource API and a control loop is called the controllers pattern. If your controller takes the place of a human operator deploying infrastructure based on a desired state, then the controller may also be following the operator pattern. The Operator pattern is used to manage specific applications; usually, these are applications that maintain state and require care in how they are managed.

Plus, many of the [operatorhub.io](https://operatorhub.io/) listings aren't especially strict in their adherence to this definition, either.

In closing, beware: these terms can be a bit confusing and tend to mean slightly different things to different audiences in different contexts in nuanced ways.

## Further reading

* Kubernetes documentation of the [operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) is worth reading.
* The [CNCF Operator Whitepaper](https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md) summarizes the operator pattern.
* The Kubernetes documentation on [Extending Kubernetes](https://kubernetes.io/docs/concepts/extend-kubernetes/) is helpful.
* [Kubebuilder](https://book.kubebuilder.io/) is a framework for building Kubernetes APIs using CRDs in Go.
* The [Operator SDK](https://sdk.operatorframework.io/) provides a toolkit for building, testing, and packaging operators (and uses `kubebuilder` itself, under the hood).
* [Writing a Controller for Pod Labels](https://kubernetes.io/blog/2021/06/21/writing-a-controller-for-pod-labels/) illustrates the use of the controller pattern in absence of corresonding custom resources.
* [Controllers and Operators](https://joshrosso.com/docs/2019/2019-10-13-controllers-and-operators/) offers a good overview of the controller pattern and when a controller qualifies as an operator.
* As an interesting reference, [Oxidizing the Kubernetes Operator](https://www.pavel.cool/rust/rust-kubernetes-operators/) illustrates a pattern for authoring Rust-based operators.

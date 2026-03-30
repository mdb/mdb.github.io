---
title: "Testing JavaScript with node:test"
date: 2026-03-29
tags:
- nodejs
- testing
- javascript
thumbnail: blue_tree_branches_thumb.png
teaser: Using Node.js's built-in test runner and assertion library to avoid third-party test dependencies.
---

_Node.js ships with a built-in test runner, assertion library, and mocking
framework. For some projects -- simple GitHub Actions, minimal CLI tools, and
lightweight scripts -- these built-ins eliminate the need for Jest, Mocha, or
other third-party test dependencies._

## The problem

You want to test some JavaScript, but are wary of adding dependency management
complexity. For a focused, minimal utility third party test framework dependencies
can dwarf the code it tests.

For example, the popular [jest](https://jestjs.io/) framework has about ~200
transitive dependencies.

```
devDependencies:
  jest: ^29.7.0          # ~200 transitive packages
  @types/jest: ^29.5.0
```

## Solution: `node:test`

Since version 20, Node.js ships with a built-in `node:test` module. It provides `describe`,
`it`, and `test` functions, lifecycle hooks, mocking, snapshot testing, watch
mode, and code coverage. Usage requires no `package.json`, no `npm install`, and
no configuration files.

### A minimal example

```js
const { describe, it } = require('node:test');
const assert = require('node:assert');

describe('add', () => {
  it('adds two numbers', () => {
    assert.strictEqual(1 + 2, 3);
  });

  it('returns NaN for non-numeric input', () => {
    assert.ok(Number.isNaN(Number('x') + 1));
  });
});
```

Run it:

```
node --test add.test.js
```

```
▶ add
  ✔ adds two numbers (0.3ms)
  ✔ returns NaN for non-numeric input (0.1ms)
▶ add (1.2ms)

ℹ tests 2
ℹ suites 1
ℹ pass 2
ℹ fail 0
```

### Assertions

`node:assert` covers common assertion patterns:

```js
const assert = require('node:assert');

// Strict equality
assert.strictEqual(actual, expected);

// Deep equality for objects and arrays
assert.deepStrictEqual({ a: 1 }, { a: 1 });

// Truthy check
assert.ok(someValue);

// Error assertions
assert.throws(() => { throw new Error('boom'); }, /boom/);
await assert.rejects(asyncFn(), { code: 'ERR_INVALID_ARG' });
```

### Mocking

`node:test`'s `mock` object provides function spies, method stubs, module mocking,
and timer control:

```js
const { describe, it, mock } = require('node:test');
const assert = require('node:assert');

describe('mocking', () => {
  it('spies on function calls', () => {
    const fn = mock.fn((a, b) => a + b);

    fn(1, 2);
    fn(3, 4);

    assert.strictEqual(fn.mock.callCount(), 2);
    assert.deepStrictEqual(fn.mock.calls[0].arguments, [1, 2]);
  });

  it('stubs object methods', () => {
    const obj = { greet: () => 'hello' };
    mock.method(obj, 'greet', () => 'mocked');

    assert.strictEqual(obj.greet(), 'mocked');
  });
});
```

Each test context (`t.mock`) automatically restores mocks after the test
completes, avoiding the manual teardown often required by other frameworks.

Timer mocking is also built in:

```js
it('advances timers', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const fn = mock.fn();

  setTimeout(fn, 1000);
  t.mock.timers.tick(1000);

  assert.strictEqual(fn.mock.callCount(), 1);
});
```

### Test discovery and CLI flags

`node --test` auto-discovers test files matching common patterns
(`**/*.test.js`, `**/test-*.js`, `**/test/**/*.js`). Useful flags:

| Flag | Purpose |
|---|---|
| `--test` | Enable the test runner |
| `--test-name-pattern` | Filter tests by name (regex) |
| `--test-only` | Run only tests marked `{ only: true }` |
| `--watch` | Re-run tests on file change |
| `--experimental-test-coverage` | Collect V8 code coverage |
| `--test-reporter=spec` | Choose output format (`spec`, `tap`, `dot`) |
| `--test-concurrency` | Control parallel execution |

## Further reading

- [Node.js test runner documentation](https://nodejs.org/api/test.html)
- [Node.js assert documentation](https://nodejs.org/api/assert.html)

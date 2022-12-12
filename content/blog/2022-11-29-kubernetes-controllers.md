---
title: What is the Kubernetes controller pattern?
date: 2022-11-29
tags:
- kubernetes
- platform engineering
thumbnail: kubernetes2_thumb.png
teaser: An introduction to the Kubernetes controller pattern.
---

_A colleague recently relayed to me their vision for a microservices architecture involving the automatic injection of sidecar containers to all [Deployments'](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) Pods within a Kubernetes namespace. Naive to Kubernetes' support for custom controllers, the colleague hoped to proof-of-concept the idea via enhanced CI/CD pipeline logic that opaquely extended Kubernetes Deployment manifest YAML prior to each application deployment. As an alternative, the following offers an overview of the Kubernetes controller pattern, as well as a tour of a basic reference implementation._

_This intro also serves as a followup to [What is the Kubernetes Operator Pattern?](/blog/what-is-the-kubernetes-operator-pattern/) The example `sidecar-injector` referenced throughout this introduction can be viewed at [github.com/mdb/sidecar-injector](https://github.com/mdb/sidecar-injector). This overview is not intended as a final authority on the most appropriate implementation; see the open questions outlined in the final summary for thoughts on alternative approaches, undiscussed topics, and followup research items._

## What? Why? How?

In Kubernetes, controllers monitor the state of a cluster and make changes according to their implementation logic, as described by [Kubernetes documentation](https://kubernetes.io/docs/concepts/architecture/controller/). Through the controller pattern, Kubernetes functionality can be extended to also support custom, non-built-in use cases. A controller following in this pattern can be implemented in any language or runtime that can act as a client to the Kubernetes API. However, technologies such as [kubebuilder](https://kubebuilder.io/), [controller-gen](https://kubebuilder.io/reference/controller-gen.html), and [operator-sdk](https://sdk.operatorframework.io) offer tools to help controller development.

The following provides an overview of how the [operator-sdk](https://sdk.operatorframework.io) might be leveraged to build a Kubernetes controller that injects sidecar containers to each Deployment pod within a targeted Kubernetes namespace (Note that `operator-sdk` itself leverages both `kubebuilder` and `controller-gen` under the hood; these more minimal tools can also be used independent of the `operator-sdk`). Again, all disclaimers apply: the following is largely intended as an overview and tour of my own introductory experience using the `operator-sdk`. It's not intended as an authority on controller implementation best practices; alternative approaches exist.

## Implementing a Custom Controller

Back to my colleague's original vision, as noted above:

> A colleague recently relayed to me their vision for a microservices architecture involving the automatic injection of sidecar containers to all deployments' pods within a Kubernetes namespace.

How might a custom controller be developed to satisfy this architecture? The [operator-sdk](https://sdk.operatorframework.io/) offers a toolkit for building such Kubernetes native applications. Once installed, the `operator-sdk` CLI can bootstrap a customer controller codebase and kickstart the development process.

While often used to build full-on Kubernetes _operators_ -- controllers that interact with _custom resources_ (see [What is the Kubernetes Operator Pattern?](/blog/what-is-the-kubernetes-operator-pattern/) for more on all that) -- `operator-sdk` can also be used to build controllers that interact with core, non-custom Kubernetes resources, as is a bit more appropriate for the above-described sidecar injector use case (at least in its simple, demo-appropriate MVP form).

To get started, first create a directory to home the controller codebase:

```txt
mkdir sidecar-injector
cd sidecar-injector
```

Next, use the `operator-sdk` to scaffold a controller codebase. For the purposes of this example, the controller will be built in Go (though other options exist; a controller can be implemented using any language that can act as a client for the Kubernetes API). As seen below, the `--domain` option specifies a path prefix for the controller's custom resources' [API group](https://kubernetes.io/docs/reference/using-api/#api-groups). Because `sidecar-injector` will feature no custom resources, this value isn't super important. The `--repo` option specifies the name of the `sidecar-injector` Go module.

```
operator-sdk init \
  --domain=mikeball.info \
  --repo=github.com/mdb/sidecar-injector
```

Before proceeding, it's worth consulting the `operator-sdk` [project layout documentation](https://sdk.operatorframework.io/docs/overview/project-layout/), which offers an overview of the typical Operator SDK project layout. Compare the [project layout documentation](https://sdk.operatorframework.io/docs/overview/project-layout/) to what's been templated by `operator-sdk` so far. Perhaps most relevant to `sidecar-injector`, note...

* `Dockerfile` - used to package and publish the controller as an [OCI](https://opencontainers.org/) image
* `Makefile` - used to build and test controller, among various other helper utility targets
* `bin/` - will home the compiled `manager` binary, which offers an executable CLI for running the controller
* `config/` - various configuration files for installing the project on a cluster. Most notably, perhaps...
    * `config/manager/` - the manifests to install the project as pods on a cluster
    * `config/rbac/` - the RBAC permissions required by the project when it's installed on a cluster
* `main.go` - the entry point program for running the controller
* `controllers/` - homes the project's actual controllers and their business logic

With all that in mind, scaffold a controller. `--kind` specifies the controller will handle [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) (that is, it will monitor Deployment resources, ensuring the presence of a sidecar container). `--resource=false` specifies the controller does not deal with any custom resources:

```
operator-sdk create api \
  --group=apps \
  --version=v1 \
  --kind=Deployment \
  --controller=true \
  --resource=false
```

The `operator-sdk create api` command creates a `controllers/deployment_controller.go`, which will serve as the backbone of the `sidecar-injector` controller. Most notably, the `DeploymentReconciler#Reconcile` method will home the core of relevant control loop, _reconciling_ desired and actual state on Deployment resources by injecting a sidecar container to each Pod template (stay tuned on `controllers/suite_test.go`; more on that later):

```
tree controllers
controllers
├── deployment_controller.go
└── suite_test.go

0 directories, 2 files

cat controllers/deployment_controller.go | grep 'Reconcile('
func (r *DeploymentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
...
```

However, before proceeding, note the following in `controllers/deployment_controller.go`:

```
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps,resources=deployments/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=apps,resources=deployments/finalizers,verbs=update
```

These annotations are used by `sidecar-injector`'s underling Make targets (see `Makefile` for details and clues) to generate and scaffold relevant code pertaining to the controller's required runtime [RBAC](https://en.wikipedia.org/wiki/Role-based_access_control) permissions. However, in `sidecar-injector`'s case, not all these permissions are necessary. Remove the unnecessary annotations, leaving only...

```
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
```

Now, run `make manifests` to generate a `config/rbac/role.yaml` file from the modified annotations. This `config/rbac/role.yaml` file specifies `sidecar-injector`'s RBAC requirements such that it's authorized to perform the necessary actions against Deployments:

```
cat config/rbac/role.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: manager-role
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
```

Next, it's necessary to begin iterating on `Reconcile`, as demonstrated by the following. Note the in-context code comment explanations:

```golang
package controllers

import (
  ...
  apierrors "k8s.io/apimachinery/pkg/api/errors"
  ...
)

...

//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// It's called each time a Deployment is created, updated, or deleted.
// When a Deployment is created or updated, it makes sure the Pod template features
// the desired sidecar container. When a Pod is deleted, it ignores the deletion.
func (r *DeploymentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    // Fetch the Deployment from the Kubernetes API.
    var deployment appsv1.Deployment
    if err := r.Get(ctx, req.NamespacedName, &deployment); err != nil {
      if apierrors.IsNotFound(err) {
        // Ignore not-found errors that occur when Deployments are deleted.
        return ctrl.Result{}, nil
      }

      log.Error(err, "unable to fetch Deployment")

      return ctrl.Result{}, err
    }

    return ctrl.Result{}, nil
}
...
```

After each code edit, run `make` to ensure `sidecar-injector` continues to successfullly compile to a `bin/manager` binary (again, this `manager` binary is the controller "manager;" an executable program and CLI responsible for running the controller itself; more on that later on):

```
make
/Users/mdb/dev/go/src/github.com/mdb/sidecar-injector/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
go fmt ./...
go vet ./...
go build -o bin/manager main.go
```

Now, add real logic to `Reconcile`, ensuring that a `busybox` sidecar container is present in every Deployment Pod:

```golang
import (
  ...
  "fmt"
  corev1 "k8s.io/api/core/v1"
  ...
)

...

//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// It's called each time a Deployment is created, updated, or deleted.
// When a Deployment is created or updated, it makes sure the Pod template features
// the desired sidecar container. When a Deployment is deleted, it ignores the deletion.
func (r *DeploymentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
  log := log.FromContext(ctx)

  // Fetch the Deployment from the Kubernetes API.
  var deployment appsv1.Deployment
  if err := r.Get(ctx, req.NamespacedName, &deployment); err != nil {
    if apierrors.IsNotFound(err) {
      // Ignore not-found errors that occur when Deployments are deleted.
      return ctrl.Result{}, nil
    }

    log.Error(err, "unable to fetch Deployment")

    return ctrl.Result{}, err
  }

  // sidecar is a simple busybox-based container that sleeps for 36000.
  // The sidecar container is always named "<deploymentname>-sidecar".
  sidecar := corev1.Container{
    Name:    fmt.Sprintf("%s-sidecar", deployment.Name),
    Image:   "busybox",
    Command: []string{"sleep"},
    Args:    []string{"36000"},
  }

  // This is a crude way to ensure the controller doesn't attempt to add
  // redundant sidecar containers, which would result in an error a la:
  // Deployment.apps \"foo\" is invalid: spec.template.spec.containers[2].name: Duplicate value: \"foo-sidecar\"
  for _, c := range deployment.Spec.Template.Spec.Containers {
    if c.Name == sidecar.Name && c.Image == sidecar.Image {
      return ctrl.Result{}, nil
    }
  }

  // Otherwise, add the sidecar to the deployment's containers.
  deployment.Spec.Template.Spec.Containers = append(deployment.Spec.Template.Spec.Containers, sidecar)

  if err := r.Update(ctx, &deployment); err != nil {
    // The Deployment has been updated or deleted since initially readiing it.
    if apierrors.IsConflict(err) || apierrors.IsNotFound(err) {
      // Requeue the Deployment to try to reconciliate again.
      return ctrl.Result{Requeue: true}, nil
    }

    log.Error(err, "unable to update Deployment")

    return ctrl.Result{}, err
  }

  return ctrl.Result{}, nil
}
```

Finally, edit `main.go` -- the controller program's entrypoint that ultimately compiles to the `bin/manager` executable -- and ensure the controller only injects sidecars in the specified Kubernetes [Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/). By default, `sidecar-injector` targets the `default` namespace, but also accommodates overrides via the specification of a `-namespace` command line option when running `sidecar-injector` via its `manager` binary.

```golang
func main() {
  var metricsAddr string
  var enableLeaderElection bool
  var probeAddr string
  var namespace string
  flag.StringVar(&namespace, "namespace", "default", "The namespace in which to inject sidecars.")
...

  mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
    Namespace:              namespace,
    Scheme:                 scheme,
...
```

Run `make` to verify `sidecar-injector` continues to compile. Note the resulting `bin/manager` executable now features a `-namespace` option:

```
./bin/manager -help
Usage of ./bin/manager:
...
  -namespace string
        The namespace in which to inject sidecars. (default "default")
...
```

Now, the controller can be test driven on a local Kubernetes cluster. Assuming you're running a local cluster via a tool like [kind](https://kind.sigs.k8s.io/), [minikube](https://minikube.sigs.k8s.io/), or [Docker Desktop](https://docs.docker.com/desktop/kubernetes/) -- and assuming you have [`kubectl`](https://kubernetes.io/docs/reference/kubectl/) installed and that its context is configured to target the local cluster, run `make run` to build and run `sidecar-injector` against the cluster:

```
make run
test -s /Users/mdb/dev/go/src/github.com/mdb/sidecar-injector/bin/controller-gen || GOBIN=/Users/mdb/dev/go/src/github.com/mdb/sidecar-injector/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.10.0
/Users/mdb/dev/go/src/github.com/mdb/sidecar-injector/bin/controller-gen rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases
/Users/mdb/dev/go/src/github.com/mdb/sidecar-injector/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
go fmt ./...
go vet ./...
go run ./main.go
1.66976137640096e+09    INFO    controller-runtime.metrics      Metrics server is starting to listen    {"addr": ":8080"}
1.6697613764012191e+09  INFO    setup   starting manager
1.669761376401563e+09   INFO    Starting server {"path": "/metrics", "kind": "metrics", "addr": "[::]:8080"}
1.6697613764015648e+09  INFO    Starting server {"kind": "health probe", "addr": "[::]:8081"}
1.669761376401669e+09   INFO    Starting EventSource    {"controller": "deployment", "controllerGroup": "apps", "controllerKind": "Deployment", "source": "kind source: *v1.Deployment"}
1.669761376401744e+09   INFO    Starting Controller     {"controller": "deployment", "controllerGroup": "apps", "controllerKind": "Deployment"}
1.669761376505056e+09   INFO    Starting workers        {"controller": "deployment", "controllerGroup": "apps", "controllerKind": "Deployment", "worker count": 1}
...
```

Create an example `hello` deployment in the cluster's `default` namespace and verify that `sidecar-injector` properly injects a `hello-sidecar` busybox container. To do so, first save the following to a `hello-deployment.yaml` file:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      name: hello
      labels:
        app: hello
    spec:
      containers:
      - image: nginx
        name: hello
```

Then, create the `hello` deployment in the `default` namespace:

```
kubectl apply -f deployment.yaml --namespace default
deployment.apps/hello created
```

Verify the resulting `hello` deployment features both a `hello` and a `hello-sidecar` containers:

```
kubectl get deployment/hello -o jsonpath="{.spec.template.spec.containers[*].name}"
hello hello-sidecar
```

Verify that `hello-sidecar` is running the correct `busybox` image:

```
kubectl get deployment/hello -o jsonpath="{.spec.template.spec.containers[1].image}"
busybox
```

## Building a container image

When running `sidecar-injector` against a local cluster in development from _outside_ that cluster, `make run` does the trick. However, to run `sidecar-injector` on a real production Kubernetes cluster, it's typical to run the controller within the cluster as a Deployment, which requires packaging/publishing the controller as an [OCI](https://opencontainers.org/) image.

Note again that `operator-sdk` seeded the `sidecar-injector` codebase with a `Dockerfile` and some corresponding Make targets (such as `docker-build`) for building the associated image. However, it may be necessary to make a few tweaks, as it was for me...

First, out of the box, `make docker-build` uses an `IMG` variable to produce a generically-named `controller:latest` image:

```Makefile
...
# Image URL to use all building/pushing image targets
IMG ?= controller:latest
...
```

Change this to be the following:

```Makefile
...
# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_TAG_BASE):$(VERSION)
...
```

Also, `IMAGE_TAG_BASE` should probably be a more appropriate value. For example, I've changed the original `IMAGE_TAG_BASE` to reference my personal [DockerHub](https://hub.docker.com/u/clapclapexcitement) repository:

```Makefile
...
# IMAGE_TAG_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
#
# For example, running 'make bundle-build bundle-push catalog-build catalog-push' will build and push both
# hub.docker.com/clapclapexcitement/sidecar-injector-bundle:$VERSION and hub.docker.com/clapclapexcitement/sidecar-injector-catalog:$VERSION.
IMAGE_TAG_BASE ?= hub.docker.com/clapclapexcitement/sidecar-injector
...
```

Additionally, at least in my case, the templated `Dockerfile` assumes an `api` directory, despite that `sidecar-injector` has no corresponding custom resource definition, nor does it expose an API, which causes an error when building the container image:

```
make docker-build
...
 => ERROR [builder 7/9] COPY api/ api/                                                                                                                                           0.0s
------
 > [builder 7/9] COPY api/ api/:
------
failed to compute cache key: "/api" not found: not found
make: *** [docker-build] Error 1
```

To fix this, remove the `COPY api/ api/` line from the `Dockerfile` and re-attempt building the `sidecar-injector` image:

```
make docker-build
...
 => => naming to hub.docker.com/clapclapexcitement/sidecar-injector:0.0.1
...
```

With `docker-build` successfully producing an appropriately named image, the controller's CI/CD pipeline can build and publish this image to the desired registry from which it can be fetched when installed on a cluster (although, implementing such a CI/CD pipeline is a bit out of scope for this simple reference tour).

## Automated testing

What about testing `sidecar-injector`? Like CI/CD, testing's a big topic unto itself; much of its nuance is beyond the scope of this intro. Nonetheless, the following offers an overview of some key patterns.

### Local testing without a cluster

Under the hood, `operator-sdk` leverages [kubebuilder](https://kubebuilder.io/) -- a lower level tool for extending Kubernetes -- and `kubebuilder` itself makes use of a few testing tools also available for use in `operator-sdk`-generated projects:

* [envtest](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/envtest) runs a local Kubernetes control plane API, specifically for testing purposes.
* [Ginkgo](http://onsi.github.io/ginkgo) is a Go testing framework

Note that `operator-sdk` seeded the `sidecar-injector` codebase with a `controller/suite_test.go` file. As can be seen in the [complete sidecar-injector repository](https://github.com/mdb/sidecar-injector/blob/main/controllers/suite_test.go), this file accommodates some pre-test `BeforeSuite` and post-test `AfterSuite` setup/teardown hooks, ensuring a local `envtest`-based control plane API and the `sidecar-injector` controller are run before the tests and stopped after the tests are executed.

In turn [`controllers/deployment_controller_test.go`](https://github.com/mdb/sidecar-injector/blob/main/controllers/deployment_controller_test.go) offers example Ginkgo tests validating the `sidecar-injector` functions properly when a Deployment is created.

For more information, `kubebuilder`'s [Writing controller tests](https://book.kubebuilder.io/cronjob-tutorial/writing-tests.html) documentation offers good insight.

### End-to-end integration testing against a cluster

In addition to `envtest`-based tests, there are also patterns for executing more robust end-to-end integration tests. By comparison, these end-to-end tests might attempt to build the controller, install it on a real Kubernetes cluster (often something akin to a local, `kind`-based development cluster), and verify its functionality within this real cluster.

For an example of such end-to-end tests, see `operator-sdk`'s [memcached-operator example](https://github.com/operator-framework/operator-sdk/tree/v1.26.0/testdata/go/v3/memcached-operator/test/e2e). Also note the the corresponding [`test-e2e` Make target](https://github.com/operator-framework/operator-sdk/blob/v1.26.0/testdata/go/v3/memcached-operator/Makefile#L108-L110) used to invoke these tests.

For more information, `operator-sdk`'s documentation notes a few learning resources on [e2e integration tests](https://sdk.operatorframework.io/docs/building-operators/golang/testing/#e2e-integration-tests).

## Summary

At a glance, `operator-sdk` generally offers a helpful toolkit for getting started with Kubernetes controller development, even when a controller reconciles core resources rather than custom resources. Nonetheless, a few notes and open questions remain, especially for `operator-sdk` newcomers...

1. For a simple controller such as `sidecar-injector` -- which has no CRDs -- is the use of `operator-sdk` a bit overly complicated? Would [kubebuilder](https://kubebuilder.ior) or even just the [controller-gen](https://kubebuilder.io/reference/controller-gen.html) be a more appropriately minimal tool? Or perhaps no external framework is warrented, and `sidecar-injector` could be implemented even more minimally, as exemplified by [trstringer/k8s-controller-core-resource](https://github.com/trstringer/k8s-controller-core-resource)?
2. In a real world scenario, would `sidecar-injector` be more appropriately implemented as a [mutating admission webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)?
3. `operator-sdk` scaffolds out code and directories not discussed above in detail (a `hack` directory, lots of `config/*` files, many additionally mysterious Make targets, such as `bundle`, etc.). The [operator-sdk documentation](https://sdk.operatorframework.io/docs/overview/project-layout/) explains the project layout, but does `sidecar-injector` need all this stuff?
4. What should `sidecar-injector`'s CI/CD process look like? How should versioning and releases work?
5. How should `sidecar-injector` users install the controller on their own clusters? Should `sidecar-injector`'s codebase feature a [helm](https://helm.sh/) chart for users to utilize? What's the relevancy of `config/manager` and `config/rbac`, which home default `sidecar-injector` manifests?

## Further reading

* [Extending Kubernetes](https://kubernetes.io/docs/concepts/extend-kubernetes/#combining-new-apis-with-automation)
* [Kubewatch, an example of Kubernetes custom controller](https://docs.bitnami.com/tutorials/kubewatch-an-example-of-kubernetes-custom-controller/)
* [Build a Kubernetes Operator in six steps](https://developers.redhat.com/articles/2021/09/07/build-kubernetes-operator-six-steps)
* [How to write Kubernetes custom controllers in Go](https://medium.com/speechmatics/how-to-write-kubernetes-custom-controllers-in-go-8014c4a04235)

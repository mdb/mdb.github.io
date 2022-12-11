---
title: What is the Kubernetes controller pattern?
date: 2022-11-29
tags:
- kubernetes
- platform engineering
thumbnail:
teaser: An introduction to the Kubernetes controller pattern.
---

_A colleague recently relayed to me their vision for a microservices architecture involving the automatic injection of sidecar containers to all deployments' pods within a Kubernetes namespace. Naive to Kubernetes' support for custom controllers, the colleague hoped to proof-of-concept the idea via enhanced CI/CD pipeline logic that opaquely extended Kubernetes deployment manifest YAML prior to each application deployment. As an alternative, the following offers an overview of the Kubernetes controller pattern, as well as reference implementation._

_This controller pattern intro also serves as a natural followup to [What is the Kubernetes Operator Pattern?](/blog/what-is-the-kubernetes-operator-pattern/)._

## What?

## Why?

## How?

## Implementing a Custom Controller

Let's relate all this back to my colleague's original vision, as noted above:

> A colleague recently relayed to me their vision for a microservices architecture involving the automatic injection of sidecar containers to all deployments' pods within a Kubernetes namespace.

How might a custom controller be developed to satisfy this architecture? The [operator-sdk](https://sdk.operatorframework.io/) offers a toolkit for building such Kubernetes native applications. Once installed, the `operator-sdk` CLI can bootstrap a customer controller codebase and kickstart the development process.

While often used to build full-on Kubernetes _operators_ -- controller that interact with _custom resources_ (see [What is the Kubernetes Operator Pattern?](/blog/what-is-the-kubernetes-operator-pattern/) for more on all that) -- `operator-sdk` can also be used to build controllers that interact with core, non-custom Kubernetes resources, as is a bit more appropriate to implement a basic sidecar injector controller (at least in its crude, demo-appropriate MVP form).

To get started, first create a directory to home the controller codebase:

```txt
mkdir sidecar-injector
cd sidecar-injector
```

Next, use the `operator-sdk` to scaffold a controller codebase. For the purposes of this example, the controller will be built using Go (though it's worth noting other options exist). As seen below, the `--domain` option specifies a path prefix for the API group the controller's custom Kubernetes resources belong to. Because `sidecar-injector` will feature no custom resources, this value isn't super important. The `--repo` option specifies the name of the `sidecar-injector` Go module.

```
operator-sdk init \
  --domain=mikeball.info \
  --repo=github.com/mdb/sidecar-injector
```

Next, scaffold a controller. `--kind` specifies the controller will handle [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), and `--resource=false` specifies the controller does not deal with any custom resources:

```
operator-sdk create api \
  --group=apps \
  --version=v1 \
  --kind=Deployment \
  --controller=true \
  --resource=false
```

The `operator-sdk create api` command created a `controllers/deployment_controller.go` file, which will serve as the backbone of the `sidecar-injector` controller. Most notably, the `DeploymentReconciler#Reconcile` method will home the core of relevant control loop, _reconciling_ desired and actual state on Deployment resources by injecting a sidecar container to each Pod template:

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

However, before proceeding, note the following annotations:

```
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps,resources=deployments/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=apps,resources=deployments/finalizers,verbs=update
```

These are used to generate and scaffold relevant code pertaining to the controller's required permissions during `sidecar-injector`'s build process (see the `Makefile` for more details and clues). However, in `sidecar-injector`'s case, not all these permissions are necessary. Remove the unnecessary permissions annotations, leaving only...

```
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
```

Now, run `make manifests` to generate a `config/rbac/role.yaml` file from the modified annotations. This `config/rbac/role.yaml` file specifies `sidecar-injector`'s [RBAC]() requirements such that it's authorized to perform the necessary actions against Deployments:

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

Next, begin building out `Reconcile`, as demonstrated by the following. Note the in-context code comment explanations:

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

After each code edit, run `make` to ensure `sidecar-injector` continues to successfullly compile to a `bin/manager` binary:

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

Finally, edit `main.go` -- the controller program's entrypoint -- and ensure the controller only injects sidecars in the specified Kubernetes Namespace. By default, `sidecar-injector` targets the `default` namespace, but also accommodates overrides via the specification of a `-namespace` command line option when running `sidecar-injector` via its compiled binary.

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

Now, the controller can be test driven on a local Kubernetes cluster. Assuming you're running a local cluster via a tool like [kind](TODO), [minikube](TODO), or [Docker Desktop](TODO) -- and assuming you have `kubectl` installed and that its context is configured to target the local cluster, run `make run` to build and run `sidecar-injector` against the cluster:

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

Now, create an example `hello` deployment in the cluster's `default` namespace and verify that `sidecar-injector` properly injects a `hello-sidecar` busybox container.

First, save the following to a `hello-deployment.yaml` file:

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

## Automated testing

## Building a container image

When running `sidecar-injector` against a local cluster in development, `make run` does the trick. However, to run `sidecar-injector` on a real production Kubernetes cluster, it's first necessary to package the controller as an [OCI]() image. Note that `operator-sdk`

```Makefile
...
# Image URL to use all building/pushing image targets
IMG ?= controller:latest
...
```

Change this to be...

```Makefile
...
# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_TAG_BASE):$(VERSION)
...
```

...and change `IMAGE_TAG_BASE` to be an appropriate value. For example, I've changed the original `IMAGE_TAG_BASE` to reference my personal [DockerHub](TODO) repository:

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

Note that, at least when using `operator-sdk` version, the templated `Dockerfile` assumes an `api` directory, despite that `sidecar-injector` has no corresponding custom resource definition:

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

To fix this, remove the `COPY api/ api/` from the `Dockerfile`.

Now, build the `sidecar-injector` image:

```
make docker-build
...
 => => naming to hub.docker.com/clapclapexcitement/sidecar-injector:0.0.1
...
```

TODO:
* is it true that 'make run' does not run an image?
* what's up with the `config` dir? Should `config/manager` be edited to reflect the image name changes?

## Further reading

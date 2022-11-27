---
title: What is the Kubernetes Operator Pattern?
date: 2022-11-20
tags:
- kubernetes
- platform engineering
thumbnail:
published: false
teaser: An introduction to the Kubernetes operator pattern.
---

_What is the Kubernetes operator pattern? The following offers an overview of the operator pattern, and how it leverages custom resource definitions and custom controllers to extend Kubernetes._

## What?

Broadly speaking, Kubernetes operators seek to abstract, codify, and automate tasks beyond what out-of-the-box Kubernetes itself provides.

As summarized in the [CNCF Operator Whitepaper](https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md#executive-summary):

> In Kubernetes, an operator provides intelligent, dynamic management capabilities by extending the functionality of the API.
>
> These operator components allow for the automation of common processes as well as reactive applications that can continually adapt to their environment. This in turn allows for more rapid development with fewer errors, lower mean-time-to-recovery, and increased engineering autonomy.

## Why?

Out of the box, the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/) enables querying and manipulating common, built-in [API objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/), such as Pods, Namespaces, Deployments, ConfigMaps, etc. However, through operators, the core Kubernetes API can be extended -- and enhanced -- beyond these core objects to support higher level abstractions.

In effect, operators enable platform engineers to codify operational logic, thereby abstracting features like application resilience, deployment logic, autoscaling, advanced routing, configuration, etc. into discreet software components. These discreet operators may have their own develop, build, test, version, and release lifeycle, and offer operational solutions that can be repeatably installed into underlying Kubernetes clusters to natively enhance those clusters' capabilities.

A few examples:

* [Argo Rollouts](https://argoproj.github.io/rollouts/) offers progressive deployment capabilities
* [operatorhub.io](https://operatorhub.io/) offers numerous operator examples
* The [operator-sdk tutorial](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/) offers an example of an operator that abstracts a [memcached](https://memcached.org/) deployment

## How?

Operator implementations leverage two constructs:

1. custom resources
1. custom controllers

## Custom Resources

* a resource is a Kubernetes API endpoint pertaining a collection of a certain **kind** of object. Pods, Services, ConfigMaps, and Namespaces are common, core examples.
* a custom resource enhances the built-in Kubernetes API via a **Custom Resource Definition** or via **API aggregation**

Custom resources can be created via the [CustomResourceDefinition API](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) by specifying the custom resource in YAML, then `kubectal apply -f`-ing the YAML file to install the resource into the cluster. For example, the following offers the beginnings of a hypothetical `Foo` custom resource definition:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: foo.mikeball.info
spec:
  kind: Foo
...
```

Once created, authorized users can create instances of the `kind: Foo` resource type and perform CRUD actions against those instances, just as can be done for the built-in resources. For example, `kubectl get foos` reads the available instances of `Foo`:

```txt
kubectl get foos
NAME     AGE
my-foo   3s
```

See [Extend the Kubernetes API with CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) for more details on the specifics.

Optionally, Kubernetes' [aggregation layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) accommodates further, more flexible extension of the Kubernetes API via API aggregation. While Custom Resources make Kubernetes recognize new kinds of objects, the aggregation layer supports the registration of "add-on" extension API servers in association with URL paths. For example, when an extension API server is registered in association with `/apis/foo.mikeball.info/v1/*` paths, the aggregation layer proxies requests to these paths to the associated extension API server. Typically, the underlying extension API server is running on pods within the cluster and is itself associated with one or more _custom controllers_.

## Custom Controllers

* custom controllers are programs installed on a Kubernetes cluster that use the Kubernetes API to reconcile -- and transform -- installed resources' actual state with the desired state specified by the custom resource (On their own -- in absence of an associated controller -- custom resources merely expose a way to set the desired state and read the actual state, but offer no mechanism by which the actual state is actually transformed to the desired state).
* controllers leverage the [Reconciler Pattern](https://www.oreilly.com/library/view/cloud-native-infrastructure/9781491984291/ch04.html), just as core Kubernetes does in managing built-in, non-custom resources too
* controllers often use methods exposed by the Kubernetes API to watch for key events pertaining to resources and act accordingly based on their business logic

## Summary: Operators, CRDs, and Controllers

It's my sense the terms operator, controller, and custom resource are all a bit overloaded and frequently conflated. After all, their conceptual boundaries are somewhat blurry, arguably. In theory, Kubernetes custom resources don't _require_ a corresponding controller, though a custom resource without a controller is arguably little more than a data store. Similarly, a custom controller doesn't need to operate on a custom resource; custom controllers may exercise custom logic on built-in Kubernetes resources.

To some extent, the terms "operator," "controller," and even "custom resource" are used somewhat interchangably (after all, the one's existence often implies the others' existence). However, very strictly speaking, the _operator pattern_ relies on one or more custom resources and one or more corresponding controllers all working in concert to extend Kubernetes (Or at least that's my conception. [Submit a PR](http://github.com/mdb/mdb.github.io) if you feel I've misprepresented something).

## Implementing an Operator

Interested in implementing your own operator? The [operator-sdk](https://sdk.operatorframework.io/) offers a CLI to help; its [tutorials](https://sdk.operatorframework.io/docs/building-operators/) are a good place to start.

## Further reading

* [Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
* [Operator Whitepaper](https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md)

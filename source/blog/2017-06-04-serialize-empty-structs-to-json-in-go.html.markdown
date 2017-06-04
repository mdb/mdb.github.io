---
title: Serialize Empty Structs to JSON in Go
date: 2017-06-04 15:03 UTC
published: true
tags: golang
thumbnail: skate_dog_thumb.png
teaser: How to avoid serializing an empty struct to JSON in Go?
---

**Problem**: How can a Golang struct be serialized to JSON _without_ including an empty object representing an empty struct within the parent struct?

For example, given a `MyStruct` struct such as the following:

```golang
type MyStruct struct {
  Data   MyData `json:"data,omitempty"`
  Status string `json:"status,omitempty"`
}
```

And a `str` instance of `MyStruct` marshal'd to JSON:

```golang
str := &MyStruct{
  Status: "some-status"
}

j, _ := json.Marshal(str)

Println(string(j))
```

The yielded JSON contains an empty `"data": {}`, which may be problematic, depending on usage:

```json
{
  "data": {},
  "status": "some-status"
}
```

How can we get the following JSON in such a data scenario, instead?

```json
{
  "status": "some-status"
}
```

**Solution**: make `MyData` a pointer.

For example, declare `MyStruct` like so:

```golang
type MyStruct struct {
  Data   *MyData `json:"data,omitempty"`
  Status string `json:"status,omitempty"`
}
```

To yield JSON _without_ a `"data"`:

```golang
str := &MyStruct{
  Status: "some-status"
}
```

To yeild JSON _with_ an empty `"data": {}`:

```golang
str := &MyStruct{
  Data: &MyData{},
  Status: "some-status"
}
```

To yield JSON with a non-empty `"data"`:

```golang
str := &MyStruct{
  Data: &MyData{
    Foo: "bar"
  },
  Status: "some-status"
}
```

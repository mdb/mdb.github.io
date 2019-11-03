---
title: Using OptionParser in Rake
date: 2016/04/15
tags: rake, ruby
published: true
thumbnail: cage_thumb.png
teaser: How to use Ruby OptionParser in Rake
---

Problem: you'd like to leverage named arguments in your Ruby `Rake` task.

Solution: use `OptionParser` to parse the named arguments. Note the need to _also_ call `#OptionParser#order!(ARGV)`, which is often absent from internet documentation.

This example uses Ruby `2.2.2` and Rake `11.1.2`.

```ruby
require 'optparse'

task :hello do
  options = {
    name: 'world'
  }

  o = OptionParser.new

  o.banner = "Usage: rake hello [options]"
  o.on('-n NAME', '--name NAME') { |name|
    options[:name] = name
  }

  # return `ARGV` with the intended arguments
  args = o.order!(ARGV) {}

  o.parse!(args)

  puts "hello #{options[:name]}"
end
```

Usage:

```
rake hello -- --name=mike
hello mike
```

Default behavior with no arguments:

```
$ rake hello
hello world
```

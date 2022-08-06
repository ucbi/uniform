# Uniform

The Uniform System is an architecture for maintaining multiple Elixir apps from a
single Elixir project in a way that minimizes duplicate work and maximizes
sharing capabilities.

It's like a monolith. But unlike a monolith, the apps can be "ejected" into
separate codebases that only contain the code needed by each app.

The complete documentation for Uniform is located [here](https://hexdocs.pm/uniform/).

## Recommended Guides

In order to understand and use this library, we heavily recommend reading the
following guides:

- [The Uniform System: How It Works](https://hexdocs.pm/uniform/how-it-works.html)
- [Dependencies](https://hexdocs.pm/uniform/dependencies.html)
- [Code Transformations](https://hexdocs.pm/uniform/code-transformations.html)

The [Setting up a Phoenix
project](https://hexdocs.pm/uniform/setting-up-a-phoenix-project.html) guide is
recommended if you're building Phoenix apps.

## Usage

```bash
mix uniform.eject Tweeter
```

## Installation

Consult the [Getting Started](https://hexdocs.pm/uniform/getting-started.html)
guide to add `Uniform` to an Elixir application.

In summary, you'll need to:

1. Add the dep in `mix.exs`: `{:uniform, "~> 0.1.1"}`
2. Add a [Blueprint](https://hexdocs.pm/uniform/Uniform.Blueprint.html) module to your project
3. Configure your Elixir app to point to the Blueprint module
4. Add `uniform.exs` manifests to each Ejectable Application

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

<br>
<img width="250" src="https://github.com/ucbi/uniform/raw/main/guides/images/uniform.png" alt="Uniform">

> Write less boilerplate and reuse more code in your portfolio of Elixir apps

[![Build Status](https://github.com/ucbi/uniform/workflows/CI/badge.svg)](https://github.com/ucbi/uniform/actions?query=workflow%3A%22CI%22)
[![hex.pm](https://img.shields.io/hexpm/v/uniform.svg)](https://hex.pm/packages/uniform)
[![hex.pm](https://img.shields.io/hexpm/l/uniform.svg)](https://hex.pm/packages/uniform)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/uniform)

With Uniform, developers maintain multiple Elixir apps inside a Base Project –
a "monolith" containing every app. Before deployment, the apps are "ejected"
into separate codebases containing only the code needed by each app.

The entire process is automated, so there's much less work required to start a
new app or share capabilities between apps.

The complete documentation for Uniform is located
[here](https://hexdocs.pm/uniform/).

## Recommended Guides

In order to understand and use this library, we heavily recommend reading the
following guides:

- [How It Works](https://hexdocs.pm/uniform/how-it-works.html)
- [Uniform Manifests](https://hexdocs.pm/uniform/uniform-manifests-uniform-exs.html)
- [Dependencies](https://hexdocs.pm/uniform/dependencies.html)
- [Code Transformations](https://hexdocs.pm/uniform/code-transformations.html)

The [Setting up a Phoenix
project](https://hexdocs.pm/uniform/setting-up-a-phoenix-project.html) guide is
recommended if you're building Phoenix apps.

## Usage

```bash
mix uniform.eject tweeter
```

## Installation

Consult the [Getting Started](https://hexdocs.pm/uniform/getting-started.html)
guide to add `Uniform` to an Elixir application.

In summary, you'll need to:

1. Add the dep in `mix.exs`
2. Add a [Blueprint](https://hexdocs.pm/uniform/Uniform.Blueprint.html) module to your project
3. Add configuration to identify the Blueprint module
4. Add `uniform.exs` manifests to each Ejectable App
5. Fill out the Blueprint so all the necessary files get ejected

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

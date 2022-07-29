# Eject

Part architectural pattern, part template this is a way of working that enables developers to work on a primary, unified application, similar to a monolith, but unlike a monolith can be split into smaller completely uncoupled applications with no trace of the original monolith from whence they came.

The complete documentation for Eject is located [here](https://hexdocs.pm/eject/).

## Recommended Guides

In order to understand and use this library, we heavily recommend reading the
following guides:

- [The Eject System: How It Works](https://hexdocs.pm/eject/how-it-works.html)
- [Dependencies](https://hexdocs.pm/eject/dependencies.html)
- [Code Transformations](https://hexdocs.pm/eject/code-transformations.html)

The [Setting up a Phoenix
project](https://hexdocs.pm/eject/setting-up-a-phoenix-project.html) guide is
recommended if you're building Phoenix apps.

## Usage

```bash
mix eject Tweeter
```

Read about [the Eject System](https://hexdocs.pm/eject/how-it-works.html) for details about how it
works.

## Installation

Consult the [Getting Started](https://hexdocs.pm/eject/getting-started.html)
guide to add `Eject` to an Elixir application.

In summary, you'll need to:

1. Add the dep in `mix.exs`: `{:eject, "~> 0.1.0"}`
2. Add a [Plan](https://hexdocs.pm/eject/Eject.Plan.html) module to your project
3. Configure your Elixir app to point to the Plan module
4. Add `eject.exs` manifests to each Ejectable Application

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

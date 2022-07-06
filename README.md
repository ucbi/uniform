# Eject

- [Eject](#eject)
  - [Description](#description)
  - [Terminology](#terminology)
  - [Use Cases](#use-cases)
  - [Benefits](#benefits)
  - [Disadvantages](#disadvantages)
  - [Compared with other approaches](#compared-with-other-approaches)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Documentation](#documentation)
  - [License](#license)

## Description

Part architectural pattern, part template this is a way of working that enables developers to work on a primary, unified application, similar to a monolith, but unlike a monolith can be split into smaller completely uncoupled applications with no trace of the original monolith from whence they came.

## Terminology

- When we nail down the terms we'll using via [#1](https://github.com/ucbi/eject/issues/1) we need to define them each here and use them consistently throughout the documentation.

## Use Cases

You need to maintain a portfolio of applications that may be entirely independent of each other. You want things to be done consistently throughout them, though they may have some necessarily unique features. You want leverage as you maintain this portfolio.

In our specifc use case, we build and maintain applications across companies for a large enterprise. The companies have their own distinct branding, themes, deployment pipelines, and assurance processes. However, they share data access patterns, ui libraries, authentication mechanisms, and many other common features.

This would also be true in an agency setting where the agency typically builds things a certain way but each company and domain brings unique requirements.

## Benefits 

- **Higher leverage to maintain a portfolio of applications** - the ROI scales with the number of applications managed this way. When you add a new capability, refactor deprecations, or change an implementation, the results are automatically incorporated into all of your applications!
- **Reduce dependency drift** - this is achieved by only setting dependencies on the primary application and all ejected applications get a subset of those dependencies. This constraint eliminates the problem of having multiple dep versions in use across an portfolio and having to grapple with missing features or incompatible apis.
- Faster feedback - when you change anything shared, your changes are automatically made and tested into all applications that could be impacted
- **Defer factoring decisions** - In the interest of the DRY principle, there is a motivation to abstract and modularize the moment we start adding a feature. This can often turn out to be a cross cutting concern in a way we didn't anticipate resulting an an abstraction that leaks or is otherwise ill-suited to the specific use case. As a result, there's advocacy for the WET principle (Write Everything Twice), which is about using the same ideas multiple times to get a real feel for the common API. Using the ejector pattern, there are no distinct packages to create up front which makes it much easier to refactor as the API evolves. Indeed, this very library started as a single module in the lib directory and is on its third implementation.
- **Share capabilities with lower overhead** - using the pattern, any capability that is developed for a specific ejected application can be lifted to the lib level and is instantly available to all other applications in the portfolio.
- **Global Refactors** - When the entire portfolio of applications is managed together, we're free to refactor any interal API and know that we've gotten all invocations across the enterprise. This eliminates the burden of maintaining backwards compatibility.

## Disadvantages

- **Novelty** By far the biggest disadvantage is the novelty. When new developers join the team, or if you have an open-source application suite, contributors have to learn this new way of working.
- **No Single Ejected App Participation** There's no way, currently, to have someone contribute changes in an ejected application and integrate them back into the primary repository. This means, to maintain all the benefits of the unified repo contributors need access to the entire portfolio.
- **Inconsistent Routing** Routes don't match between primary and ejected application environments. There's only one root route in the primary, so when you're developing specific applications from the primary repo, all routes have a prefix. This means you need 100% reliance on route helpers and a hard coded route will probably take you to the wrong place either in development or post ejections.
- **Compile Times** Full recompiles can take a really long time for a big portfolio of application. Elixir 1.13 has helped out tremendously in this regard, but when you're changing config that maybe only has relevance to a single application - you still end up with a full recompile of lots of unaffected code. 
- **CI Burn Rate** - Because we test every change, on every commit, on every application, we burn through CI minutes.

## Compared with other approaches

- VS Umbrellas
- VS Ponchos
- VS Monoliths
- VS Micro-services
- VS individual libraries for common features

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eject` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eject, "~> 0.1.0"}
  ]
end
```

## Usage

Add usage example/instructions

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/eject>.

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

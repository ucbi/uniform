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

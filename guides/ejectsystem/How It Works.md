# How It Works

## What is "Ejecting"?

For the purposes of this documentation, ejecting an app means

> Copying the code used by the application to a separate, standalone code
> repository, without including code that the application doesn't need.

Ejecting is done like this:

```bash
mix eject MyAppName
```

See `mix eject` for more details. This task essentially makes code repositories
"out of thin air" by taking only the relevent code from your Base Project.

We use Continuous Integration (CI) and Continuous Deployment (CD) tools to
automate the process of committing code to ejected repos and deploying to live
environments. A single merged code change can result in dozens of apps being
safely deployed without any human involvement.

## What is a Base Project?

A Base Project is the single Elixir application that developers directly modify
when maintaining code with the Eject paradigm.

The Base Project contains:

1. Code for multiple [Ejectable Apps](#what-is-an-ejectable-app)
2. [Libraries](dependencies.html#lib-dependencies) shared between the applications
3. A [Plan](Eject.Plan.html) module configuring which files are copied to
   ejected repositories.

## What is an Ejectable App?

In the Eject System, multiple applications are stored in a single Elixir
project. Each application is stored in a sub-directory of `lib`.

To identify a directory inside `lib` as an Ejectable App, **create an `eject.exs`
file inside the directory.**

### eject.exs Options

`eject.exs` files must contain a keyword list, in this structure:

```elixir
# lib/my_app/eject.exs
[
  mix_deps: [:gql, :timex],
  lib_deps: [:some_lib_directory],
  extra: [
    some_data: "just for this app"
  ]
]
```

- `mix_deps` - [Mix Dependencies](dependencies.html#mix-dependencies) of the
  app; each must exist in `mix.exs`.
- `lib_deps` - [Lib Dependencies](dependencies.html#lib-dependencies) of the
  app; each must exist as a directory in `lib/`.
- `extra` - additional user-defined data to configure the app.

> #### The purpose of the :extra key {: .tip}
>
> `mix eject` does not by change its behavior based on the data in `extra`, but
> it is placed in `app.extra` so that you can use it to make decisions in
> [templates](building-files-from-eex-templates.html) or in the
> [eject](Eject.Plan.html#eject/2) or [modify](Eject.Plan.html#modify/4) blocks
> in your [Plan](Eject.Plan.html) module.
>
> For 'global' values available to _all_ ejectable apps, use the
> `c:Eject.Plan.extra/1` callback implementation.

> #### No Keys in eject.exs are required {: .info}
>
> Note that `eject.exs` does not need to include `mix_deps`, `lib_deps`, or
> `extra`. They all default to an empty list.
>
> By implication, `[]` is a valid `eject.exs` file.

## How files are included/excluded by `mix eject`

Whenever you run `mix eject MyApp`, there are 4 simple rules that the library
uses to decide which files to include or exclude from the ejected codebase.

1. [A small handful of files](Eject.Plan.html#module-files-that-are-always-ejected)
   common to most Elixir projects are always included.
2. All files in `lib/my_app` and `test/my_app` are included.
3. For every [Lib Dependency](dependencies.html#lib-dependencies), all files in
   `lib/dep_name` and `test/dep_name` are included.
4. All files specified by the [eject section](Eject.Plan.html#eject/2) of the
   Plan are included.

> The only caveat to these rules is that the files in rules 2 and 3 (the
> `lib/foo` and `test/foo` files for your ejected app and Lib Dependencies) are
> subject to [only](Eject.Plan.html#only/1) and
> [except](Eject.Plan.html#except/1) instructions.

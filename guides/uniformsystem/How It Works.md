# The Uniform System: How It Works

With the Uniform System, multiple apps are maintained together in a single Elixir
codebase. When you're ready to deploy an app, it's "ejected" out into separate
codebases that only contains the code needed by the app.

## What is a Base Project?

A Base Project is the single Elixir application that houses all of the
applications. When you run the Base Project in your development environment,
you are running your entire portfolio of applications simultaneously.

Since Uniform projects are just an Elixir application, the `lib` directory is
central. It contains directories for:

1. [Ejectable Apps](how-it-works.html#what-is-an-ejectable-app)
2. [Lib Dependencies](dependencies.html#lib-dependencies) (shared libraries)

It also contrains a [Blueprint](Uniform.Blueprint.html) module configuring which
files are copied to ejected repositories.

A Base Project directory structure might look like this.

```bash
+ my_base_app
  + lib
    + my_first_app
    + my_second_app
    + utilities
    + ui_components
```

## What is "Ejecting"?

For the purposes of this documentation, ejecting an app means

> Copying the code used by the application to a separate, standalone code
> repository, without including code that the application doesn't need.

Ejecting is done like this:

```bash
mix uniform.eject MyAppName
```

See `mix uniform.eject` for more details. This task essentially makes code repositories
"out of thin air" by taking only the relevent code from your Base Project.

We use Continuous Integration (CI) and Continuous Deployment (CD) tools to
automate the process of committing code to ejected repos and deploying to live
environments. A single merged code change can result in dozens of apps being
safely deployed without any human involvement.

## What is an Ejectable App?

An Ejectable App is simply an application that can be ejected from the Base
Project.

Each Ejectable App is stored in a sub-directory of `lib`.

To identify a directory inside `lib` as an Ejectable App, **create an `uniform.exs`
file inside the directory.**

### uniform.exs Options

`uniform.exs` files must contain a keyword list, in this structure:

```elixir
# lib/my_app/uniform.exs
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
> `mix uniform.eject` does not by change its behavior based on the data in `extra`, but
> it is placed in `app.extra` so that you can use it to make decisions in
> [templates](building-files-from-eex-templates.html) or in the
> [base_files](Uniform.Blueprint.html#base_files/1) or [modify](Uniform.Blueprint.html#modify/2) sections
> in your [Blueprint](Uniform.Blueprint.html) module.
>
> For 'global' values available to _all_ ejectable apps, use the
> `c:Uniform.Blueprint.extra/1` callback implementation.

> #### No Keys in uniform.exs are required {: .info}
>
> Note that `uniform.exs` does not need to include `mix_deps`, `lib_deps`, or
> `extra`. They all default to an empty list.
>
> By implication, `[]` is a valid `uniform.exs` file.

## How files are included/excluded by `mix uniform.eject`

Whenever you run `mix uniform.eject MyApp`, there are 4 simple rules that the library
uses to decide which files to include or exclude from the ejected codebase.

1. All files specified by the [base_files](Uniform.Blueprint.html#base_files/2)
   section of the Blueprint are included. These are files to include with every
   app.
2. All files in `lib/my_app` and `test/my_app` are included.
3. For every [Lib Dependency](dependencies.html#lib-dependencies), all files in
   `lib/dep_name` and `test/dep_name` are included.
4. [A small handful of files](Uniform.Blueprint.html#module-files-that-are-always-ejected)
   common to most Elixir projects are always included.

> There are some caveats to these rules.
>
> The files in rule 2 are subject to the
> [lib_app_except](Uniform.Blueprint.html#c:app_lib_except/1) callback.
>
> The files in rule 3 are subject to [only](Uniform.Blueprint.html#only/1) and
> [except](Uniform.Blueprint.html#except/1) instructions.


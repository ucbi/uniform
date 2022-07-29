# How It Works

## What is "Ejecting"?

For the purposes of this documentation, ejecting an app means

> Copying the code used by the application to a separate, standalone code
> repository, without including code that the application doesn't need.

Ejecting is done with `mix eject`. This mix task essentially makes code
repositories "out of thin air" by taking only the relevent bits from your Base
Project.

## What is a Base Project?

A Base Project is the single Elixir application that developers directly modify
when maintaining code with the Eject paradigm.

The Base Project contains code for multiple logically-separate applications and
their shared libraries.

## What is an Ejectable App?

In an [umbrella
project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html#umbrella-projects),
there is an `apps` directory containing distinct Elixir
applications. But in an `Eject` project, all of the separate applications are
stored in a single Elixir project.

Each application is stored in a sub-directory of the `lib/` directory. To
designate a lib directory as an ejectable application, create an `eject.exs`
file directly inside the lib directory. For example, `lib/my_app/eject.exs`.

To eject an Ejectable App in `lib/my_app`, run this command:

```
mix eject MyApp
```

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

- `mix_deps` - [Mix Dependencies](#mix-dependencies) of the app; each must exist in `mix.exs`.
- `lib_deps` - [Lib Dependencies](#lib-dependencies) of the app; each must exist as a folder in `lib/`.
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

## Mix and Lib Dependencies

### Lib Dependencies

A Lib Dependency is a directory in the [Base
Project](#what-is-a-base-project)'s `lib/` directory that contains a code
library used by [Ejectable Apps](#what-is-an-ejectable-app).

Lib Dependencies are `Eject`'s way to make sharing code easy between different
apps without resorting to something more involved like private Hex packages.

A Lib Dependency is referenced by an atom that matches the name of the
directory in `lib/`.

For example, a library in this directory

```bash
lib/utilities
```

would be referenced in `eject.exs` like this

```elixir
[
  lib_deps: [:utilities]
]
```

Or in the [Plan](Eject.Plan.html) module like this

```elixir
deps do
  always do
    lib :utilities
  end
end
```

### Mix Dependencies

`Eject` is aware of the deps in your `mix.exs`. Whenever an app is ejected, it
removes all mix dependencies that aren't explicitly needed by the app.

### How to include a Dependency with an Ejectable App

There are three ways:

1. Include the dependency by saying so in [eject.exs](#eject-exs-options).
2. Place the dependency in the `always` block of your [Plan](Eject.Plan.html)
   module. (See `Eject.Plan.always/1`.)
3. Configure another dependency to require it as a "sub-dependency" in your
   [Plan](Eject.Plan.html) module. (See `Eject.Plan.deps/1`.) All transitive
   (sub-) dependencies of any dependency in `always` or `eject.exs` will be
   ejected.

## What exactly does `mix eject` do?

When you eject an app by running `mix eject MyApp`, the following happens:

- The destination directory is created if it doesn't exist.
- All files and directories in the destination are deleted, except for `.git`,
  `_build`, and `deps`.
    - `.git` is kept to preserve the Git repository and history.
    - `deps` is kept to avoid having to download all dependencies after ejection.
    - `_build` is kept to avoid having to recompile the entire project after
      ejection.
- All files in `lib/my_app` are copied to the destination.
- All files specified in the `eject(app) do` block of the [Plan](`Eject.Plan`)
  are copied to the destination.
- All Lib Dependencies of the app are copied to the destination.
- For each file copied, [a set of transformations](./code-transformations.html)
  are applied to the file contents – except for those specified with `cp` and `cp_r`.

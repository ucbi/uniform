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
project. Each application is stored in a sub-directory of `lib/`. There is only
one requirement to designate a `lib/` directory as an Ejectable App:

> **Create an `eject.exs` file directly inside the directory.**

(For example, `lib/my_app/eject.exs`.)

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
- `lib_deps` - [Lib Dependencies](#lib-dependencies) of the app; each must exist as a directory in `lib/`.
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

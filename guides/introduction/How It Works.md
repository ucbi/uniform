# How It Works

With Uniform, multiple apps are maintained together in a single Elixir
codebase. When you're ready to deploy an app, it's "ejected" to a separate
codebase that only contains the code needed by the app.

## The Base Project

The Base Project is the single Elixir project that houses multiple separate
apps. Apps are developed and tested together in the Base Project.

The Base Project's `lib` directory is central. It contains directories for:

1. [Ejectable Apps](how-it-works.html#ejectable-apps)
2. [Lib Dependencies](dependencies.html#lib-dependencies) (shared libraries)

So the directory structure of a Base Project might look like this.

```bash
+ my_base_app
  + lib
    + my_first_app
    + my_second_app
    + utilities
    + ui_components
```

Each Base Project needs a [Blueprint](Uniform.Blueprint.html) module
configuring which files are copied to ejected repositories.

## What is "Ejecting"?

"Ejecting" an app means copying the app's code to a separate, standalone
codebase – without including code the app doesn't need.

- **Unused Lib Dependencies are excluded from `lib`**
- **Unused Mix Dependencies are removed from `mix.exs`**

Ejecting is done with `mix uniform.eject`.

```bash
mix uniform.eject my_app_name
```

## Ejectable Apps

Ejectable Apps are apps that can be [ejected](#what-is-ejecting) from the Base
Project. Create them with `mix uniform.gen.app`.

```bash
mix uniform.gen.app my_new_app
```

To set up an Ejectable App manually:

1. Make a directory inside `lib` for your app (E.g. `lib/my_new_app`)
2. Add [uniform.exs](uniform-manifests-uniform-exs.html) inside it

## Exactly which files get ejected?

There are [four rules that determine which files are
copied](Mix.Tasks.Uniform.Eject.html#module-which-files-get-ejected) during
ejection.

Basically, the Blueprint's `base_files` are ejected along with every directory
in `lib` and `test` whose name matches (1) the app being ejected and (2) its
Lib Dependencies.

Make sure to build out your Blueprint's
[`base_files`](Uniform.Blueprint.html#base_files/1) and
[`deps`](Uniform.Blueprint.html#deps/1) sections. If you're building Phoenix
apps, you may want to consult the [Setting up a Phoenix
project](./setting-up-a-phoenix-project.html) guide.

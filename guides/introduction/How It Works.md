# How It Works

With Uniform, multiple apps are maintained together in a single Elixir
codebase. When you're ready to deploy an app, it's "ejected" to a separate
codebase that only contains the code needed by the app.

## The Base Project

The Base Project is the single Elixir application that houses all of your
applications. Applications are developed and tested in the Base Project.

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

"Ejecting" an app means copying the code used by the application to a separate,
standalone code repository, without including code that the application doesn't
need. Specifically,

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

When you run `mix uniform.eject my_app`, these four rules determine which files
are copied.

1. [A few files](Uniform.Blueprint.html#module-files-that-are-always-ejected)
   common to Elixir projects are copied.
2. All files in the Blueprint's
   [base_files](Uniform.Blueprint.html#base_files/1) section are copied.
3. All files in `lib/my_app` and `test/my_app` are copied.
4. For every [Lib Dependency](dependencies.html#lib-dependencies) of `my_app`:
    - All files in `lib/dep_name` and `test/dep_name` are copied.
    - All [associated files](Uniform.Blueprint.html#lib/2-associated-files)
      tied to the Lib Dependency are copied.

> If you need to apply exceptions to these rules, you can use these tools.
>
>   - Files in `(lib|test)/my_app` (rule 3) are subject to the
>     [lib_app_except](Uniform.Blueprint.html#c:app_lib_except/1) callback.
>   - Lib Dependency files (rule 4) are subject to
>     [only](Uniform.Blueprint.html#only/1) and
>     [except](Uniform.Blueprint.html#except/1) instructions.


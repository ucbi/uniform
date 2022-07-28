# How It Works

## What is "Ejecting"?

When we refer to "ejecting" an app, we mean taking all of the code used by that
application and copying it to a distinct code repository. This is done with
`mix eject`.

**`Eject` makes code repositories "out of thin air" by taking only the relevent
bits from your Base Project.**

## What is a Base Project?

A Base Project is the single Elixir application that developers directly modify
when maintaining code with the Eject paradigm.

The Base Project contains code for multiple logically-separate applications and
their shared libraries.

## What is an Ejectable App?

In an [umbrella
project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html#umbrella-projects),
for example, your project has an `apps` directory containing distinct Elixir
applications. In `Eject` projects, on the other hand,
all of your separate applications are stored in a single Elixir project. **Each
application is stored in a separate folder in the `lib/` directory.**

To designate a lib directory as an ejectable application, create an `eject.exs`
file directly inside the lib directory. For example, `lib/my_app/eject.exs`.

`eject.exs` files must contain a keyword list, in this structure:

```elixir
[
  mix_deps: [:gql, :timex],
  lib_deps: [:some_lib_directory],
  extra: [
    some_data: "just for this app"
  ]
]
```

None of the keys are required; `[]` is a valid `eject.exs` file.

The name of the directory is important. To eject an application in `lib/my_app`,
run this command:

```
mix eject MyApp
```

## What is a Lib Dependency?

A Lib Dependency is a folder in `lib` that contains a code library that is used
by Ejectable Apps.

While [Hex](https://hex.pm/) contains public libraries, many teams have private
libraries that are useful to share between projects. It's possible to share
these with private Hex packages. However, using the Eject paradigm, libraries
can be shared simply by putting them in `lib/` and specifying that an app
depends on them.

## What does `mix eject` do?

When `mix eject MyApp` is run:

- A new directory is created (if it doesn't exist) at the destination.
- If the destination already exists, all files and directories are deleted.
  except for `.git`, `_build`, and `deps`.
    - Keeping `.git` prevents `mix eject` from deleting your Git repository
      history.
    - Keeping `deps` ensures all of the dependencies won't need to be
      downloaded every time ejection happens.
    - Keeping `_build` ensures that the minimum amount of recompilation will be
      required after ejection.
- All of the files in `lib/my_app` are copied to the destination.
- All of the files specified by the `eject` block of the `Plan` module are
  copied to the destination.
- All of the files in Lib Dependencies of the app are copied to the
  destination.
- As each of the files above are copied, a set of transformations are applied
  to each file except for those specified with `cp` and `cp_r`.

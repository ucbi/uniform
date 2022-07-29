# Dependencies

## Lib Dependencies

A Lib Dependency is a directory in the [Base
Project](#what-is-a-base-project)'s `lib/` directory that contains a code
library used by [Ejectable Apps](#what-is-an-ejectable-app).

Lib Dependencies are used to share non-public code between Ejectable Apps with
less ceremony than other mechanisms like private Hex packages.

A Lib Dependency is referenced by an atom that matches the name of the
directory in `lib/`.

For example, a library in `lib/utilities` would be referenced in `eject.exs` or
in the [Plan](Eject.Plan.html) module as `:utilities`.

## Mix Dependencies

`Eject` is aware of the deps in your `mix.exs`. Whenever an app is ejected, it
removes all mix dependencies that aren't explicitly needed by the app.

## Configuring the Deps of an App

There are three methods to specify which Lib and Mix dependencies are required
by an App:

1. Include the dependency for **a single Ejectable App** by saying so in
   [eject.exs](#eject-exs-options).

```elixir
# lib/my_app/eject.exs
[
  lib_deps: [:utilities],
  mix_deps: [:absinthe]
]
```

2. Include the depencency in **all Ejectable Apps** by placing the dependency in
   the [always](`Eject.Plan.always/1`) block of your [Plan](Eject.Plan.html)
   module.

```elixir
deps do
  always do
    lib :utilities
    mix :absinthe
  end
end
```

3. Make it a "sub-dependency" of a dependency from method 1 or 2 by using the
   `lib_deps` or `mix_deps` macros in your [deps block](`Eject.Plan.deps/1`).

```elixir
deps do
  lib :some_included_lib do
    lib_deps [:utilities]
  end

  mix :some_included_mix do
    mix_deps [:absinthe]
  end
end
```

> #### Chained Dependencies {: .info}
>
> `mix eject` will follow chains of sub-dependencies completely.
>
> If all of the following are true:
>
> - The app's `eject.exs` manifest includes `lib_deps: [:foo]`
> - The `deps` section of your Plan says that `foo` has `lib_deps: [:bar]`
> - The `deps` section of your Plan says that `bar` has `lib_deps: [:baz]`
>
> Then the ejected codebase will include `lib/foo`, `lib/bar`, and `lib/baz`.


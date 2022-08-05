# Dependencies

## Lib Dependencies

A Lib Dependency is a directory in the [Base
Project](how-it-works.html#what-is-a-base-project)'s `lib/` directory that
contains a code library used by [Ejectable
Apps](how-it-works.html#what-is-an-ejectable-app).

Lib Dependencies are used to share non-public code between Ejectable Apps with
less ceremony than other mechanisms like private Hex packages.

A Lib Dependency is referenced by an atom that matches the name of the
directory in `lib/`.

For example, a library in `lib/utilities` would be referenced in `uniform.exs` or
in the [Blueprint](Uniform.Blueprint.html) module as `:utilities`.

## Mix Dependencies

Uniform is aware of the deps in your `mix.exs`. Whenever an app is ejected, it
removes all mix dependencies that aren't explicitly needed by the app.

This is accomplished by wrapping your list of dependencies in the following
comments:

```elixir
defp deps do
  # uniform:deps
  [
    ...
  ]
  # /uniform:deps
end
```

## Adding Dependencies to an App

There are three methods to specify which Lib and Mix dependencies are required
by an App:

1. Include the dependency for **a single Ejectable App** by saying so in
   [uniform.exs](how-it-works.html#uniform-exs-options).

```elixir
# lib/my_app/uniform.exs
[
  lib_deps: [:utilities],
  mix_deps: [:absinthe]
]
```

2. Include the depencency in **all Ejectable Apps** by placing the dependency in
   the [always](`Uniform.Blueprint.always/1`) section of your [Blueprint](Uniform.Blueprint.html)
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
   `lib_deps` or `mix_deps` macros in your [deps section](`Uniform.Blueprint.deps/1`).
   (See "Chained Dependencies" below.)

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
> `mix uniform.eject` will follow chains of sub-dependencies completely.
>
> If these are true:
>
> - The app's `uniform.exs` manifest includes `lib_deps: [:foo]`
> - The `deps` section of your Blueprint says that `foo` has `lib_deps: [:bar]`
> - The `deps` section of your Blueprint says that `bar` has `lib_deps: [:baz]`
>
> Then the ejected codebase will include `lib/foo`, `lib/bar`, and `lib/baz`.


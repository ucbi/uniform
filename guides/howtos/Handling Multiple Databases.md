# Handling multiple databases

> This guide assumes that you've read the [How It Works](how-it-works.html) and
> [Getting Started](getting-started.html) guides.

If you're using Uniform it's likely that you have multiple databases, but you
don't want to give every app access to every database.

In this scenario, we recommend creating separate [Lib
Dependencies](dependencies.html#lib-dependencies) (each in its own
`lib/some_data_source` directory) which each encapsulate all of the code for
interacting with a single database. This implies that each Lib Dependency would
house the [Ecto Repo](https://hexdocs.pm/ecto/Ecto.Repo.html) as well as all
[Ecto Schemas](https://hexdocs.pm/ecto/Ecto.Schema.html) and
[Context](https://hexdocs.pm/phoenix/contexts.html) modules related to its
database.

Structuring the code this way allows you to easily include or exclude the code
for a data source in [uniform.exs](uniform-manifests-uniform-exs.html).

## An Example

For example, given apps with these `uniform.exs` manifests

```elixir
# lib/some_app/uniform.exs
[
  lib_deps: [:my_data_source]
]
```

```elixir
# lib/another_app/uniform.exs
[
  lib_deps: [:my_data_source, :other_data_source]
]
```

```elixir
# lib/third_app/uniform.exs
[
  lib_deps: [:other_data_source]
]
```

- `SomeApp` would be ejected with all of the code related to interacting with
  `my_data_source`
- `AnotherApp` would be ejected with the code for both `my_data_source` and
  `other_data_source`
- `ThirdApp` would only be ejected with the code for `other_data_source`

## Configuring Lib Dependencies

If you take this approach, make sure to configure your
[Blueprint](`Uniform.Blueprint`) module to include any Lib or Mix Dependencies
of each data source's library. Also, be sure to include migrations and seeds
related to the library.

```elixir
lib :my_data_source do
  lib_deps [:some_library]
  mix_deps [:faker, ...]

  # `match_dot: true` below to include priv/my_data_source_repo/.formatter.exs
  file Path.wildcard("priv/my_data_source_repo/**", match_dot: true)
end
```

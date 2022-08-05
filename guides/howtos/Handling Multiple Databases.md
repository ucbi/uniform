# Handling Multiple Databases

> This guide assumes that you're familiar with [The Uniform
> System](how-it-works.html) and have gone through the [Getting
> Started](getting-started.html) guide.

If you're using The Uniform System it's likely that you have multiple Repos for
multiple databases, but you only want to give access for a given database to
some of your apps.

In this scenario, we recommend creating separate [Lib
Dependencies](dependencies.html#lib-dependencies) (each in its own
`lib/some_data_source` directory) which each encapsulate all of the code for
interacting with a single database. This implies that each Lib Dependency
would house all of the [Ecto Schemas](https://hexdocs.pm/ecto/Ecto.Schema.html)
and [Context](https://hexdocs.pm/phoenix/contexts.html) modules related to its
database.

Structuring the code this way allows you to easily include or exclude the code
for a data source in [uniform.exs](how-it-works.html#uniform-exs-options).

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

- `SomeApp` would be ejected with all of the code related to interacting with `my_data_source`
- `AnotherApp` would be ejected with the code for both `my_data_source` and `other_data_source`
- `ThirdApp` would only be ejected with the code for `other_data_source`

## Configuring Lib Dependencies

If you take this approach, make sure to configure your [Blueprint](`Uniform.Blueprint`) module
to include any Lib or Mix Dependencies of each data source's library. Also, be sure
to include migrations and seeds related to the library.

```elixir
lib :ucbi_data do
  lib_deps [:some_library]
  mix_deps [:faker, ...]

  # `match_dot: true` below to include priv/my_data_source_repo/.formatter.exs
  file Path.wildcard("priv/my_data_source_repo/**", match_dot: true)
end
```

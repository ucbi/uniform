# Uniform Manifests (uniform.exs)

As explained in the How It Works guide, [Ejectable
Apps](how-it-works.html#ejectable-apps) are defined by the existence of a
`uniform.exs` file inside the app's `lib` directory.

Each app has its own `uniform.exs`.

## Structure

`uniform.exs` contains a keyword list with three supported options: `mix_deps`,
`lib_deps`, and `extra`.

**Each key is optional and defaults to `[]`.**

```elixir
# the simplest valid uniform.exs
[]
```

A typical `uniform.exs` might look something like this.

```elixir
# lib/my_app/uniform.exs
[
  mix_deps: [:gql, :timex],
  lib_deps: [:ui_components, :auth],
  extra: [
    some_data: "just for this app"
  ]
]
```

## mix_deps

`mix_deps` lists [Mix Dependencies](dependencies.html#mix-dependencies) of the
app.

Provide the same atom as you do in `mix.exs`. (E.g. `:ecto`.)

## lib_deps

`lib_deps` lists [Lib Dependencies](dependencies.html#lib-dependencies) of the
app.

Provide the directory in `lib` as an atom. (E.g. `:ui_components` for
`lib/ui_components`.)

## extra

`extra` contains a keyword list of arbitrary, developer-defined data. The
contents are placed in `app.extra`. (See [`Uniform.App`](Uniform.App.html))

When you need make `mix uniform.eject` change what code is emitted for
different apps (beyond including/excluding dependencies), you'll want to use
`app.extra` with one of these tools:

- [`base_files`](Uniform.Blueprint.html#base_files/1)
- [Templates](building-files-from-eex-templates.html)
- [Modifiers](Uniform.Blueprint.html#modify/2)

Note that `app.extra` also contains keys returned by the [extra
callback](Uniform.Blueprint.html#c:extra/1). (`uniform.exs` has precedence for
conflicting keys.)

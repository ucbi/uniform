# Uniform Manifests (uniform.exs)

As explained in the How It Works guide, [Ejectable
Apps](how-it-works.html#ejectable-apps) are defined by the existence of a
`uniform.exs` file inside the app's `lib` directory.

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
  lib_deps: [:some_lib_directory],
  extra: [
    some_data: "just for this app"
  ]
]
```

## mix_deps

`mix_deps` lists [Mix Dependencies](dependencies.html#mix-dependencies) of the
app. Provide the same atom as you do in `mix.exs`. (E.g. `:ecto`.)

Mix Dependencies required by every app should be specified using
[always](Uniform.Blueprint.html#always/1) in the `deps` section of your
Blueprint. It isn't necessary to redundantly add them to `uniform.exs`.

## lib_deps

`lib_deps` lists [Lib Dependencies](dependencies.html#lib-dependencies) of the
app. Provide the directory in `lib` as an atom. (E.g. `:ui_components` for
`lib/ui_components`.)

Lib Dependencies required by every app should be specified using
[always](Uniform.Blueprint.html#always/1) in the `deps` section of your
Blueprint. It isn't necessary to redundantly add them to `uniform.exs`.

## extra

`extra` contains arbitrary developer-defined data to configure the app.

Whenever you run `mix uniform.eject`, the contents of `extra` in `uniform.exs`
are merged with the output of the (optional) [extra
callback](Uniform.Blueprint.html#c:extra/1) in your Blueprint. (`uniform.exs`
has precedence for conflicting keys.) The merged results are placed in
`app.extra`.

You can use `app.extra` to make decisions about:

- What to render in [templates](building-files-from-eex-templates.html)
- Which [base_files](Uniform.Blueprint.html#base_files/1) to include
- How to [modify](Uniform.Blueprint.html#modify/2) code before ejecting

For example, `extra` can be used to store:

- Which UI theme to use (if you have many)
- The host to deploy with (if you have many)
- A list of [crons jobs](https://en.wikipedia.org/wiki/Cron) to be added in the
  app's ejected configuration. (E.g. with
  [quantum](https://hex.pm/packages/quantum))


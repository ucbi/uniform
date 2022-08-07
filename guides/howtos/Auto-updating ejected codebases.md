# Auto-updating ejected codebases

When using Uniform, we recommend the following setup:

- Host ejected code repositories on the same platform as your [Base
  Project](how-it-works.html#the-base-project). (GitHub, GitLab, etc.)
- Consider those ejected repositories as "untouchable". Only update them via
  `mix uniform.eject`.
- **Automate updating ejected repositories with Continuous Integration (CI).**

## Getting a list of Ejectable Apps

Uniform ships with a few tools to help you get a full list of your Ejectable
Apps.

To output your Ejectable App names in stdout on the command line, use `mix
uniform.ejectable_apps`.

```bash
$ mix uniform.ejectable_apps
my_first_app
my_second_app
```

If you're working in Elixir, you can also use `Uniform.ejectable_app_names/0`

```elixir
iex> Uniform.ejectable_app_names()
[
  "my_first_app",
  "my_second_app"
]
```

Or `Uniform.ejectable_apps/0`

```elixir
iex> Uniform.ejectable_apps()
[
  #Uniform.App<
    extra: [...],
    name: %{
      camel: "MyFirstApp",
      hyphen: "my-first-app",
      module: MyFirstApp,
      underscore: "my_first_app"
    },
    ...
  >,
  #Uniform.App<
    extra: [...],
    name: %{
      camel: "MySecondApp",
      hyphen: "my-second-app",
      module: MySecondApp,
      underscore: "my_second_app"
    },
    ...
  >
]
```


# Auto-updating ejected codebases

When using Uniform, we recommend the following setup:

- Host ejected code repositories on the same platform as your [Base
  Project](how-it-works.html#the-base-project). (GitHub, GitLab, etc.)
- Consider those ejected repositories as "untouchable". Only update them via
  `mix uniform.eject`.
- **Automate updating ejected repositories with Continuous Integration (CI).**

## Building your CI pipeline

If you follow the setup recommended above, you'll need to build a Continuous
Integration (CI) pipeline that commits updates to your ejected code
repositories.

Since each CI tool is configured in a different way, we cannot provide a single
example to match your platform. However, we can provide a list of recommended
steps to build the pipeline.

In your CI pipeline, we recommend:

1. Only eject after a successful merge to the main/master branch.
2. Use `mix uniform.ejectable_apps` to get a full list of Ejectable Apps. (See below.)
3. Clone each of your Ejectable Apps so that they're ready to have commits
   added.
4. For each app, run `mix uniform.eject`.
5. For each app, run `git commit`. If there are no changes to commit, this will
   no-op.
6. Push your changes with `git push`.

Note that these steps leave out whatever authentication steps are necessary
with your git host to `clone` and `push` to the repositories. Since each git
host is different, you'll have to consult the documentation for yours.

## Getting a list of Ejectable Apps

For step 2 above, Uniform ships with a few tools to help you get a full list of
your Ejectable Apps.

To output your Ejectable App names in stdout on the command line, use [`mix
uniform.ejectable_apps`](Mix.Tasks.Uniform.EjectableApps.html).

```bash
$ mix uniform.ejectable_apps
my_first_app
my_second_app
```

If you're working in Elixir, you can also use `Uniform.ejectable_app_names/0`
or `Uniform.ejectable_apps/0`.

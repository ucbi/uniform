defmodule Mix.Tasks.Uniform.EjectableApps do
  @moduledoc """
  Outputs the name of all [Ejectable Apps](how-it-works.html#ejectable-apps)
  to stdout.

  This task is useful for building a CI pipeline that automatically commits
  updates to each ejected code repository. See the [Auto-updating ejected
  codebases](auto-updating-ejected-codebases.html) guide for more information.

  ## Usage

  ```bash
  mix uniform.ejectable_apps
  ```
  """

  use Mix.Task

  def run(_) do
    for name <- Uniform.ejectable_app_names(), do: IO.puts(name)
  end
end

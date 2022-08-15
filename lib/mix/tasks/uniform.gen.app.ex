defmodule Mix.Tasks.Uniform.Gen.App do
  @moduledoc """
  Generates an `uniform.exs` file so that the given app can be ejected with `mix
  uniform.eject`.

  ## Usage

  ```bash
  $ mix uniform.gen.app some_app_name
  Created lib/some_app_name/uniform.exs
  ```

  Running that command will create `lib/some_app_name/uniform.exs`, which will
  allow you to run

  ```bash
  $ mix uniform.eject some_app_name
  ```
  """

  use Mix.Task

  require Logger

  @doc false
  def run([lib]) do
    unless String.match?(lib, ~r/[a-z0-9_]+/) do
      raise_invalid_input()
    end

    File.mkdir_p!("lib/#{lib}")
    path = "lib/#{lib}/uniform.exs"

    if File.exists?(path) do
      Logger.warn("Did not create #{path} because it already exists")
    else
      File.write!(path, """
      [
        # add lib deps required by this app, unless they're already in `always`
        # or required by an included dependency:
        #
        # lib_deps: [
        #   :ui_components
        # ],

        # add mix deps required by this app, unless they're already in `always`
        # or required by an included dependency:
        #
        # mix_deps: [
        #   :norm
        # ],

        # Add keyword pairs needed by `modify`, `base_files`, or templates
        # to make decisions about this app.
        #
        # extra: [
        #   crons: [...],
        #   fly_io_options: [...]
        # ]
      ]
      """)

      IO.puts("Created #{path}")
    end
  end

  def run(_) do
    raise_invalid_input()
  end

  defp raise_invalid_input do
    raise ArgumentError,
      message: """
      Expected usage:

          mix uniform.gen.app some_lib_directory
      """
  end
end

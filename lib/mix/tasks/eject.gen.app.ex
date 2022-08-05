defmodule Mix.Tasks.Eject.Gen.App do
  @moduledoc """
  Generates an `eject.exs` file so that the given app can be ejected with `mix
  eject`.

  ## Usage

  ```bash
  mix eject.gen.app some_app_name
  ```

  Running that command will create `lib/some_app_name/eject.exs`. This will
  enable `mix eject some_app_name` to work without failing.
  """

  use Mix.Task

  require Logger

  @doc false
  def run([lib]) do
    unless String.match?(lib, ~r/[a-z0-9_]+/) do
      raise_invalid_input()
    end

    File.mkdir_p!("lib/#{lib}")
    path = "lib/#{lib}/eject.exs"

    if File.exists?(path) do
      Logger.warning("Did not create #{path} because it already exists")
    else
      Logger.info("Creating #{path}")

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
        # eject: [
        #   crons: [...],
        #   fly_io_options: [...]
        # ]
      ]
      """)
    end
  end

  def run(_) do
    raise_invalid_input()
  end

  defp raise_invalid_input do
    raise ArgumentError,
      message: """
      Expected usage:

          mix eject.gen.app some_lib_directory
      """
  end
end

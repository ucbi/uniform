defmodule Mix.Tasks.Uniform.Init do
  @moduledoc """
  Initializes a [Base Project](how-it-works.html#the-base-project) repository
  with the bare minimum setup required for using Uniform.

  1. Adds a [Blueprint](Uniform.Blueprint.html) module
  2. Adds required configuration to `config/config.exs`

  The remainder of installation steps are listed in the [Getting
  Started](getting-started.html) guide.

  ## Usage

  ```bash
  $ mix uniform.init
  Created lib/base_app/uniform/blueprint.ex
  Added configuration in config/config.exs
  ```
  """

  use Mix.Task

  require Logger

  @doc false
  def run(_) do
    otp_app = Keyword.fetch!(Mix.Project.config(), :app)

    File.mkdir_p!("lib/#{otp_app}/uniform")
    create_blueprint(otp_app)
    add_config(otp_app)
  end

  defp create_blueprint(otp_app) do
    blueprint_path =
      __ENV__.file
      |> Path.dirname()
      |> Path.join("/../../../templates/blueprint.ex")
      |> Path.expand()

    blueprint =
      EEx.eval_file(blueprint_path,
        assigns: [
          app_module: app_module(otp_app),
          app_underscore: to_string(otp_app)
        ]
      )

    write_unless_exists("lib/#{otp_app}/uniform/blueprint.ex", blueprint)
  end

  defp add_config(otp_app) do
    case File.read("config/config.exs") do
      {:ok, config} ->
        do_add_config(config, otp_app)

      {:error, reason} ->
        Logger.warning("Could not patch config/config.exs – reason: #{reason}")
    end
  end

  defp do_add_config(config, otp_app) do
    case String.split(config, "import Config") do
      [before_import, after_import] ->
        blueprint_config = """
        import Config

        # uniform:remove
        config :#{otp_app}, Uniform, blueprint: #{app_module(otp_app)}.Uniform.Blueprint
        # /uniform:remove\
        """

        File.write!("config/config.exs", before_import <> blueprint_config <> after_import)
        IO.puts("Added configuration in config/config.exs")

      _ ->
        Logger.warning(
          "Could not patch config/config.exs because it does not contain `import Config`"
        )
    end
  end

  defp write_unless_exists(path, contents) do
    if File.exists?(path) do
      Logger.warning("Did not create #{path} because it already exists")
    else
      File.write!(path, contents)
      IO.puts("Created #{path}")
    end
  end

  defp app_module(otp_app) do
    otp_app
    |> to_string()
    |> Macro.camelize()
  end
end

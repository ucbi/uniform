defmodule Mix.Tasks.Eject.Init do
  @moduledoc """
  Initializes a [Base Project](how-it-works.html#what-is-a-base-project)
  repository with the bare minimum setup required for using `Eject`.

  1. Adds a [Blueprint](Eject.Blueprint.html) module
  2. Adds required configuration to `config/config.exs`

  The remainder of installation steps are listed in the [Getting
  Started](getting-started.html) guide.

  ## Usage

  ```bash
  mix eject.init
  ```
  """

  use Mix.Task

  require Logger

  @doc false
  def run(_) do
    otp_app = Keyword.fetch!(Mix.Project.config(), :app)

    File.mkdir_p!("lib/#{otp_app}/eject")
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

    write_unless_exists("lib/#{otp_app}/eject/blueprint.ex", blueprint)
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

        # eject:remove
        config :#{otp_app}, Eject, blueprint: #{app_module(otp_app)}.Eject.Blueprint
        # /eject:remove\
        """

        Logger.info("Adding configuration in config/config.exs")
        File.write!("config/config.exs", before_import <> blueprint_config <> after_import)

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
      Logger.info("Creating #{path}")
      File.write!(path, contents)
    end
  end

  defp app_module(otp_app) do
    otp_app
    |> to_string()
    |> Macro.camelize()
  end
end

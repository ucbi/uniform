defmodule Eject.Config do
  @moduledoc false

  defstruct [:mix_project_app, :mix_project, :blueprint, :destination]

  alias Eject.{LibDep, MixDep}

  @typedoc """
  `mix_project_app` is the `:app` key of the keyword list returned by the `project`
  callback in `mix.exs`.

  `destination` is the default destination where ejectable apps will be
  ejected, unless a destination is given to `mix eject`.

  ### Example

      %Config{
        mix_project_app: :my_app,
        mix_project: MyBaseApp.MixProject,
        blueprint: MyBaseApp.Eject.Project,
        destination: "/Users/me/code"
      }

  """
  @type t :: %__MODULE__{
          mix_project_app: atom,
          mix_project: module,
          blueprint: module,
          destination: nil | Path.t()
        }

  @doc """
  Builds a `t:Eject.Config.t` struct from the current Mix project.

  To derive the `blueprint` and `destination` fields, looks for the following in config:

        config :my_app, Eject, blueprint: SomeModule, destination: "..."

  where `:my_app` is the value of the `:app` key in your Mix project specification in `mix.exs`.
  """
  @spec build :: t
  def build do
    mix_project_app = Keyword.fetch!(Mix.Project.config(), :app)
    config = Application.get_env(mix_project_app, Eject)

    if is_nil(config[:blueprint]) do
      camelized =
        mix_project_app
        |> to_string()
        |> Macro.camelize()

      raise """
      Eject configuration is missing. Run:

          mix eject.init

      Or add the following to config/config.exs.

          config :#{mix_project_app}, Eject, blueprint: #{camelized}.Eject.Blueprint

      (Change `#{camelized}.Eject.Blueprint` to the name of your Blueprint module.)
      """
    end

    case Code.ensure_loaded(config[:blueprint]) do
      {:module, _} ->
        :ok

      {:error, error} ->
        raise """
        Tried to load Blueprint module #{inspect(config[:blueprint])} but received:

            {:error, #{inspect(error)}}

        Did you spell the module name correctly in `config.exs`?

        """
    end

    unless function_exported?(config[:blueprint], :__template_dir__, 0) do
      raise """
      #{inspect(config[:blueprint])} is not a Blueprint module.

      Add the following to #{inspect(config[:blueprint])}.

          use Eject.Blueprint, templates: "..."

      (Change `...` to your Eject templates directory.)

      """
    end

    %__MODULE__{
      mix_project_app: mix_project_app,
      mix_project: Mix.Project.get(),
      blueprint: config[:blueprint],
      destination: config[:destination]
    }
  end

  @doc """
  Returns all lib deps that can be ejected, in the form of a map where the key is
  the lib's name.
  """
  @spec lib_deps(t) :: %{LibDep.name() => LibDep.t()}
  def lib_deps(config) do
    {:module, _} = Code.ensure_loaded(config.blueprint)

    registered =
      if function_exported?(config.blueprint, :__deps__, 1),
        do: config.blueprint.__deps__(:lib),
        else: []

    names = for lib_dep <- registered, do: to_string(lib_dep.name)

    unregistered =
      for dir <- File.ls!("lib"), File.dir?(Path.join("lib", dir)), dir not in names do
        LibDep.new!(%{
          name: String.to_atom(dir),
          lib_deps: [],
          mix_deps: [],
          always: false
        })
      end

    for lib_dep <- registered ++ unregistered, into: %{} do
      {lib_dep.name, lib_dep}
    end
  end

  @doc """
  Returns all mix deps that can be ejected, in the form of a map where the key is
  the mix dep's name.
  """
  @spec mix_deps(t) :: %{MixDep.name() => MixDep.t()}
  def mix_deps(config) do
    {:module, _} = Code.ensure_loaded(config.blueprint)

    registered =
      if function_exported?(config.blueprint, :__deps__, 1),
        do: config.blueprint.__deps__(:mix),
        else: []

    mix_exs_deps =
      config.mix_project.project()
      |> Keyword.get(:deps, [])
      |> Enum.map(fn
        {name, _} -> name
        {name, _, _} -> name
      end)

    names =
      for mix_dep <- registered do
        if mix_dep.name not in mix_exs_deps do
          raise "Mix dependency #{mix_dep.name} is not in mix.exs"
        end

        mix_dep.name
      end

    unregistered =
      for name <- mix_exs_deps, name not in names do
        MixDep.new!(%{name: name, always: false, mix_deps: []})
      end

    for mix_dep <- registered ++ unregistered, into: %{} do
      {mix_dep.name, mix_dep}
    end
  end
end

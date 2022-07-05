defmodule Eject.Project do
  defstruct [:base_app, :module, :templates, :destination]

  alias Eject.{LibDep, MixDep}

  @typedoc """
  `base_app` is the `:app` key of the keyword list returned by the `project`
  callback in `mix.exs`.

  `destination` is the default destination where ejectable apps will be
  ejected, unless a destination is given to `mix eject`.

  ### Example

      %Project{
        base_app: :my_base_app,
        module: MyBaseApp.Eject.Project,
        templates: "/Users/me/code/my_base_app/lib/my_base_app/eject/templates",
        destination: "/Users/me/code"
      }

  """
  @type t :: %__MODULE__{
          base_app: atom,
          module: module,
          templates: nil | Path.t(),
          destination: nil | Path.t()
        }

  @spec from_config_key(atom) :: t
  def from_config_key(config_key) do
    config = Application.get_env(config_key, Eject)

    %__MODULE__{
      base_app: config_key,
      module: config[:project],
      templates: config[:templates],
      destination: config[:destination]
    }
  end

  @doc """
  Returns all lib deps that can be ejected, in the form of a map where the key is
  the lib's name.

  Hydrated using the `c:Eject.lib_deps/0` callback implementation, e.g. `YourProject.Eject.Project.lib_deps/1`.
  """
  @spec lib_deps(t) :: %{LibDep.name() => LibDep.t()}
  def lib_deps(project) do
    for dep <- project.module.lib_deps(), into: %{} do
      {name, opts} =
        case dep do
          {name, opts} -> {name, opts}
          name -> {name, []}
        end

      lib_dep =
        LibDep.new!(%{
          name: name,
          lib_deps: opts |> Keyword.get(:lib_deps, []) |> List.wrap(),
          mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap(),
          always: Keyword.get(opts, :always, false),
          file_rules: Eject.Rules.new(opts)
        })

      {name, lib_dep}
    end
  end

  @doc """
  Returns all mix deps that can be ejected, in the form of a map where the key is
  the mix dep's name.

  Hydrated using the `c:Eject.mix_deps/0` callback implementation, e.g. `YourProject.Eject.Project.mix_deps/1`.
  """
  @spec mix_deps(t) :: %{MixDep.name() => MixDep.t()}
  def mix_deps(project) do
    for dep <- project.module.mix_deps(), into: %{} do
      {name, opts} =
        case dep do
          {name, opts} -> {name, opts}
          name -> {name, []}
        end

      mix_dep =
        MixDep.new!(%{
          name: name,
          mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap()
        })

      {name, mix_dep}
    end
  end
end

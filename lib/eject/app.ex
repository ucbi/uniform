defmodule Eject.App do
  @moduledoc """
  A struct representing a discrete, self-contained application to be ejected by `Eject`.
  """

  alias __MODULE__
  alias Eject.{Deps, Manifest, Project}

  defstruct [:project, :name, :destination, :deps, :extra]

  @type t :: %__MODULE__{
          project: Project.t(),
          name: %{
            module: module,
            web_module: module,
            kebab: String.t(),
            snake: String.t(),
            pascal: String.t()
          },
          destination: Path.t(),
          deps: Deps.t(),
          extra: keyword
        }

  @type new_opt :: {:destination, String.t()}

  @doc """
  Initializes a new `%App{}` struct.

  ### Example

      new!(project, manifest, Tweeter)

      %Eject.App{
        project: %Project{...},
        name: %{
          module: Tweeter,
          web_module: TweeterWeb,
          kebab: "tweeter",
          snake: "tweeter",
          pascal: "Tweeter"
        },
        destination: "...",
        deps: %Deps{
          lib: %{
            included_lib: %LibDep{...},
            indirectly_included_lib: %LibDep{...}
          },
          mix: %{
            included_mix: %MixDep{...},
            indirectly_included_mix: %MixDep{...}
          },
          included: %{
            lib: [:included_lib, :indirectly_included_lib],
            mix: [:included_mix, :indirectly_included_mix]
          },
          all: %{
            lib: [:excluded_lib, :included_lib, :indirectly_included_lib],
            mix: [:excluded_mix, :included_mix, :indirectly_included_mix]
          }
        },
        extra: [...]
      }

  """
  @spec new!(Project.t(), Manifest.t(), atom) :: t
  @spec new!(Project.t(), Manifest.t(), atom, [new_opt]) :: t
  def new!(%Project{} = project, %Manifest{} = manifest, name, opts \\ []) when is_atom(name) do
    "Elixir." <> app_name_pascal_case = to_string(name)
    app_name_snake_case = Macro.underscore(name)
    deps = Deps.discover!(project, manifest)

    app = %App{
      project: project,
      name: %{
        module: name,
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        web_module: String.to_atom("Elixir." <> app_name_pascal_case <> "Web"),
        pascal: app_name_pascal_case,
        snake: app_name_snake_case,
        kebab: String.replace(app_name_snake_case, "_", "-")
      },
      destination: destination(app_name_snake_case, project, opts),
      deps: deps
    }

    # `extra/1` requires an app struct
    %{app | extra: Keyword.merge(project.module.extra(app), manifest.extra)}
  end

  @doc """
  Indicates if an app requires a given dependency.

  ### Examples

      iex> depends_on?(
      ...>   %Eject.App{
      ...>     deps: %{
      ...>       included: %{
      ...>         mix: [:some_included_mix_dep]
      ...>       }
      ...>     }
      ...>   },
      ...>   :mix,
      ...>   :some_included_mix_dep
      ...> )
      true

      iex> depends_on?(
      ...>   %Eject.App{deps: %{included: %{mix: [:included]}}},
      ...>   :mix,
      ...>   :not_included_dep
      ...> )
      false

      iex> depends_on?(
      ...>   %Eject.App{deps: %{included: %{lib: [:some_included_lib]}}},
      ...>   :lib,
      ...>   :some_included_lib
      ...> )
      true

  """
  def depends_on?(app, category, dep_name) when category in [:lib, :mix] and is_atom(dep_name) do
    dep_name in app.deps.included[category]
  end

  defp destination(app_name_snake_case, project, opts) do
    destination =
      case {project.destination, opts[:destination]} do
        {nil, nil} -> "../" <> app_name_snake_case
        {nil, opt} -> opt
        {config, nil} -> Path.join(config, app_name_snake_case)
      end

    Path.expand(destination)
  end
end

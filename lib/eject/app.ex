defmodule Eject.App do
  @moduledoc """
  A struct representing a discrete, self-contained application to be ejected by `Eject`.
  """

  alias __MODULE__
  defstruct [:name, :destination, :deps, :extra]

  @type t :: %__MODULE__{
          name: %{
            module: module,
            web_module: module,
            kebab: String.t(),
            snake: String.t(),
            pascal: String.t()
          },
          destination: Path.t(),
          deps: Eject.Deps.t(),
          extra: keyword
        }

  @type new_opt :: {:destination, String.t()}

  @doc """
  Initializes a new `%App{}` struct.

  ### Example

      iex> new!(manifest, TwitterClone)
      %Eject.App{
        name: %{
          module: TwitterClone,
          web_module: TwitterCloneWeb,
          kebab: "twitter-clone",
          snake: "twitter_clone",
          pascal: "TwitterClone"
        },
        destination: "/Users/me/code/twitter_clone",
        deps: %Eject.Deps{
          lib: %{
            my_company_backend: %Eject.LibDep{
              name: :my_company_backend,
              always: true,
              mix_deps: [],
              lib_deps: [],
              file_rules: []
            }
          },
          mix: %{},
          included: %{
            lib: [:my_company_backend],
            mix: []
          },
          all: %{
            lib: [:my_company_backend, :unused_lib_folder],
            mix: [:mint]
          }
        },
        extra: [
          some_data: "from eject.exs"
        ]
      }

  """
  @spec new!(Eject.Manifest.t(), atom) :: t
  @spec new!(Eject.Manifest.t(), atom, [new_opt]) :: t
  def new!(%Eject.Manifest{} = manifest, name, opts \\ []) when is_atom(name) do
    "Elixir." <> app_name_pascal_case = to_string(name)
    app_name_snake_case = Macro.underscore(name)
    deps = Eject.Deps.discover!(manifest)

    app = %App{
      name: %{
        module: name,
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        web_module: String.to_atom("Elixir." <> app_name_pascal_case <> "Web"),
        pascal: app_name_pascal_case,
        snake: app_name_snake_case,
        kebab: String.replace(app_name_snake_case, "_", "-")
      },
      destination: destination(app_name_snake_case, opts),
      deps: deps
    }

    # `extra/1` requires an app struct
    %{app | extra: Keyword.merge(Eject.project().extra(app), manifest.extra)}
  end

  @doc """
  Indicates if an app requires a given dependency.

  ### Examples

      iex> depends_on?(%App{}, :mix, :some_included_mix_dep)
      true

      iex> depends_on?(%App{}, :mix, :not_included_dep)
      false

      iex> depends_on?(%App{}, :lib, :some_included_lib)
      true

  """
  def depends_on?(app, category, dep_name) when category in [:lib, :mix] and is_atom(dep_name) do
    dep_name in app.deps.included[category]
  end

  defp destination(app_name_snake_case, opts) do
    destination =
      case {Eject.config()[:destination], opts[:destination]} do
        {nil, nil} -> "../" <> app_name_snake_case
        {nil, opt} -> opt
        {config, nil} -> Path.join(config, app_name_snake_case)
      end

    Path.expand(destination)
  end
end

defmodule Eject.App do
  @moduledoc """
  An App struct, representing an application to be ejected. See the [type
  definition](`t:t/0`) for more details.

  ## App Struct Availability

  This struct is available in the Plan module in these locations:

  - `c:Eject.Plan.extra/1` callback
  - `c:Eject.Plan.target_path/2` callback
  - `Eject.Plan.eject/2` macro
  - `Eject.Plan.modify/4` macros

  In these callbacks and macros, you can make decisions about what to eject or
  how files should be modified using the `app`.

  ## Checking App Dependencies

  The `depends_on?/3` utility can be used to determine whether a app depends on
  a mix or lib dependency.

      depends_on?(app, :mix, :norm)

  See `depends_on?/3` for more information.

  """

  alias __MODULE__
  alias Eject.{Manifest, Config, LibDep, MixDep}

  @derive {Inspect, except: [:internal]}
  defstruct [:internal, :name, :destination, :extra]

  defmodule Deps do
    @moduledoc """
               A struct containing all dependencies associated with an ejectable app.

               Intended to be attached to the `deps` field of `t:Eject.App.t/0`.

                 - `:lib` – all included `%LibDeps{}`
                 - `:mix` – all included `%MixDeps{}`
                 - `:included` – all included lib and mix deps as atom names (same as pulling keys from above structs)
                 - `:all` – *all* mix and lib dep names that _could_ be included in an
                   app. The `all` field helps identify and warn on references to mix or
                   lib deps that are not in `mix.exs` or `lib/`.
               """ && false

    defstruct [:lib, :mix, :included, :all]

    alias Eject.{LibDep, MixDep, Manifest, Config}

    @type t :: %__MODULE__{
            lib: %{LibDep.name() => LibDep.t()},
            mix: %{MixDep.name() => MixDep.t()},
            included: %{
              lib: [LibDep.name()],
              mix: [MixDep.name()]
            },
            all: %{
              lib: [LibDep.name()],
              mix: [MixDep.name()]
            }
          }
  end

  @typedoc """
  An App struct, representing a discrete, self-contained application to be
  ejected.

  ## Example

  Note that the `extra` key contains everything you put in `extra` in
  `eject.exs` for the given app. It also contains anything returned by
  `c:Eject.Plan.extra/1`.

      #Eject.App<
        destination: "/Users/me/code/tweeter",
        extra: [company: :fake_co, logo_file: "pixel", some_data: "from eject.exs"],
        name: %{
          camel: "Tweeter",
          hyphen: "tweeter",
          module: Tweeter,
          underscore: "tweeter"
        },
        ...
      >

  """
  @type t :: %__MODULE__{
          name: %{
            module: module,
            hyphen: String.t(),
            underscore: String.t(),
            camel: String.t()
          },
          destination: Path.t(),
          extra: keyword
        }

  @typep new_opt :: {:destination, String.t()}

  @doc """
       Initializes a new `%App{}` struct.

       ### Example

           new!(config, manifest, Tweeter)

           %Eject.App{
             config: %Config{...},
             name: %{
               module: Tweeter,
               hyphen: "tweeter",
               underscore: "tweeter",
               camel: "Tweeter"
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

       """ && false
  @spec new!(Config.t(), Manifest.t(), atom) :: t
  @spec new!(Config.t(), Manifest.t(), atom, [new_opt]) :: t
  def new!(%Config{} = config, %Manifest{} = manifest, name, opts \\ []) when is_atom(name) do
    "Elixir." <> app_name_camel_case = to_string(name)
    app_name_underscore_case = Macro.underscore(name)

    app = %App{
      internal: %{
        config: config,
        deps: deps(config, manifest)
      },
      name: %{
        module: name,
        camel: app_name_camel_case,
        underscore: app_name_underscore_case,
        hyphen: String.replace(app_name_underscore_case, "_", "-")
      },
      destination: destination(app_name_underscore_case, config, opts)
    }

    {:module, _} = Code.ensure_loaded(config.plan)

    # `extra/1` requires an app struct
    extra =
      if function_exported?(config.plan, :extra, 1) do
        Keyword.merge(config.plan.extra(app), manifest.extra)
      else
        manifest.extra
      end

    %{app | extra: extra}
  end

  @doc """
  Indicates if an app requires a given dependency.

  Pass in the `app`, the dependency type (either `:lib` or `:mix`), and the
  name of the dependency (like `:tesla` or `:my_lib_directory`) and the
  function will return `true` if the dependency will be ejected along with the
  app.

  ## Examples

      depends_on?(app, :mix, :some_included_mix_dep)
      depends_on?(app, :mix, :not_included_dep)
      depends_on?(app, :lib, :some_included_lib)

  ## Examples in Context

      eject(app) do
        if depends_on?(app, :mix, :some_hex_dependency) do
          file "file_needed_by_some_hex_dependency"
        end
      end

      modify ~r/^test\/.+_(test).exs/, file, app do
        if depends_on?(app, :lib, :my_data_lib) do
          file
        else
          String.replace(
            file,
            "use Oban.Testing, repo: MyDataLib.Repo",
            "use Oban.Testing, repo: OtherDataLib.Repo"
          )
        end
      end

  """
  @spec depends_on?(app :: t, category :: :lib | :mix, dep_name :: atom) :: boolean
  def depends_on?(app, category, dep_name) when category in [:lib, :mix] and is_atom(dep_name) do
    dep_name in app.internal.deps.included[category]
  end

  defp destination(app_name_underscore_case, config, opts) do
    destination =
      case {config.destination, opts[:destination]} do
        {nil, nil} -> "../" <> app_name_underscore_case
        {_, opt} when not is_nil(opt) -> opt
        {config, nil} -> Path.join(config, app_name_underscore_case)
      end

    Path.expand(destination)
  end

  # Given a manifest struct, returns a `%Deps{}` struct containing
  # information about lib and mix dependencies.
  @spec deps(Config.t(), Manifest.t()) :: t
  defp deps(config, manifest) do
    all_libs = Config.lib_deps(config)
    all_mixs = Config.mix_deps(config)
    included_libs = included_libs(manifest, all_libs)
    included_mixs = included_mixs(manifest, included_libs, all_mixs)

    %Deps{
      lib: included_libs,
      mix: included_mixs,
      included: %{
        lib: Map.keys(included_libs),
        mix: Map.keys(included_mixs)
      },
      all: %{
        lib: Map.keys(all_libs),
        mix: Map.keys(all_mixs)
      }
    }
  end

  @spec included_libs(Manifest.t(), %{atom => LibDep.t()}) :: %{atom => LibDep.t()}
  defp included_libs(manifest, all) do
    root_deps =
      all
      |> Enum.filter(fn {_, lib_dep} -> lib_dep.always || lib_dep.name in manifest.lib_deps end)
      |> Enum.into(%{})

    root_deps
    |> Map.values()
    |> Enum.reduce(root_deps, &gather_child_deps(&1, :lib_deps, &2, all))
  end

  @spec included_mixs(Manifest.t(), %{atom => LibDep.t()}, %{atom => MixDep.t()}) :: %{
          atom => MixDep.t()
        }
  defp included_mixs(manifest, included_libs, all_mixs) do
    root_deps =
      all_mixs
      |> Enum.filter(fn {_, mix_dep} -> mix_dep.always || mix_dep.name in manifest.mix_deps end)
      |> Enum.into(%{})

    # gather nested mix deps required by manifest
    root_deps =
      root_deps
      |> Enum.map(fn {_name, dep} -> dep end)
      |> Enum.reduce(
        root_deps,
        &gather_child_deps(&1, :mix_deps, &2, all_mixs)
      )

    # gather mix deps required by lib deps, which have already been flattened
    included_libs
    |> Map.values()
    |> Enum.reduce(root_deps, &gather_child_deps(&1, :mix_deps, &2, all_mixs))
  end

  @typep dep :: LibDep.t() | MixDep.t()

  @spec gather_child_deps(dep, :lib_deps | :mix_deps, %{atom => dep}, %{atom => dep}) :: %{
          atom => dep
        }
  defp gather_child_deps(dep, children_field, gathered, all_of_type) do
    dep
    |> Map.get(children_field, [])
    |> Enum.reduce(gathered, fn child_name, gathered ->
      if Map.has_key?(gathered, child_name) do
        # already gathered this one
        gathered
      else
        if Map.has_key?(all_of_type, child_name) do
          nested_dep = all_of_type[child_name]
          gathered = Map.put(gathered, child_name, nested_dep)
          # recurse to ensure we capture infinite potential levels of nesting
          gather_child_deps(nested_dep, children_field, gathered, all_of_type)
        else
          type =
            case dep do
              %LibDep{} -> :lib
              %MixDep{} -> :mix
            end

          raise "Could not find #{type} dependency #{child_name} which is a dependency of #{dep.name}"
        end
      end
    end)
  end
end

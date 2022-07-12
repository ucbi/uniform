defmodule Eject.Manifest do
  @moduledoc """
  A struct containing the `Eject` manifest for an app, parsed from `lib/<my_ejectable_app>/eject.exs`.

  The `eject.exs` manifest specifies required dependencies and configuration values:
    - `mix_deps` - mix dependencies; each must exist in the `c:Eject.mix_deps/0` callback implementation.
    - `lib_deps` - lib dependencies; each must exist in the `c:Eject.lib_deps/0` callback implementation.
    - `extra` - additional key value pairs specific to the ejectable app. For 'global' values available
      to _all_ ejectable apps, use the `c:Eject.extra/1` callback implementation.

  Required for each ejectable app.

      # Example `eject.exs`
      [
        mix_deps: [:ex_aws_s3],
        lib_deps: [:my_utilities],
        extra: [
          sentry: [...],
          deployment: [
            target: :heroku,
            options: [...],
              buildpacks: [...],
              addons: [...],
              domains: [...]
          ]
        ]
      ]

  """
  defstruct mix_deps: [], lib_deps: [], extra: []

  alias Eject.{Config, LibDep, MixDep}

  @typedoc "A struct containing the `Eject` manifest for an app."
  @type t :: %__MODULE__{
          mix_deps: [MixDep.name()],
          lib_deps: [LibDep.name()],
          extra: keyword
        }

  @doc "Loads a manifest file into a `%Manifest{}` struct."
  @spec eval_and_parse(Config.t(), String.t() | atom) :: t
  def eval_and_parse(config, app_name_underscore_case) do
    new!(config, eval(app_name_underscore_case))
  end

  @doc "Initializes a new `%Manifest{}` struct."
  @spec new!(Config.t(), keyword) :: t
  def new!(%Config{} = config, params) when is_list(params) do
    manifest = struct!(__MODULE__, params)

    lib_deps = Map.keys(Config.lib_deps(config))
    mix_deps = Map.keys(Config.mix_deps(config))
    missing_lib_deps = Enum.filter(manifest.lib_deps, &(&1 not in lib_deps))
    missing_mix_deps = Enum.filter(manifest.mix_deps, &(&1 not in mix_deps))

    if Enum.any?(missing_mix_deps) or Enum.any?(missing_lib_deps) do
      mix_dep_message =
        if Enum.any?(missing_mix_deps) do
          "The following mix deps were specified in eject.exs but were not defined in the Project mix_deps function: #{Enum.join(missing_mix_deps, ", ")}\n"
        end

      lib_dep_message =
        if Enum.any?(missing_lib_deps) do
          "The following lib deps were specified in eject.exs but were not defined in the Project lib_deps function: #{Enum.join(missing_lib_deps, ", ")}"
        end

      raise ArgumentError, message: "#{mix_dep_message}#{lib_dep_message}"
    end

    manifest
  end

  def new!(_config, _) do
    raise "eject.exs should contain a keyword list"
  end

  defp eval(app_name_underscore_case) do
    manifest_path = manifest_path(app_name_underscore_case)

    if File.exists?(manifest_path) do
      {manifest, _bindings} = Code.eval_file(manifest_path)
      manifest
    else
      raise Eject.NotEjectableError, app_name: app_name_underscore_case, manifest_path: manifest_path
    end
  end

  @doc """
  Relative file path to the manifest file.

  ### Example

      iex> manifest_path("my_app")
      "lib/my_app/eject.exs"

  """
  @spec manifest_path(String.t() | atom) :: String.t()
  def manifest_path(app_name_underscore_case) do
    "lib/#{app_name_underscore_case}/eject.exs"
  end
end

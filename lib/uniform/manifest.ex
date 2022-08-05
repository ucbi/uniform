defmodule Uniform.Manifest do
  @moduledoc """
             A struct containing the `Uniform` manifest for an app, parsed from `lib/<my_ejectable_app>/uniform.exs`.

             The `uniform.exs` manifest specifies required dependencies and configuration values:
               - `mix_deps` - mix dependencies; each must exist in `mix.exs`.
               - `lib_deps` - lib dependencies; each must exist as a folder in `lib/`.
               - `extra` - additional key value pairs specific to the ejectable app. For 'global' values available
                 to _all_ ejectable apps, use the `c:Uniform.extra/1` callback implementation.

             Required for each ejectable app.

                 # Example `uniform.exs`
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

             """ && false

  defstruct mix_deps: [], lib_deps: [], extra: []

  alias Uniform.{Config, LibDep, MixDep}

  @typedoc "A struct containing the `Uniform` manifest for an app."
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
          "The following mix deps were specified in uniform.exs but were not defined in the Project mix_deps function: #{Enum.join(missing_mix_deps, ", ")}\n"
        end

      lib_dep_message =
        if Enum.any?(missing_lib_deps) do
          "The following lib deps were specified in uniform.exs but were not defined in the Project lib_deps function: #{Enum.join(missing_lib_deps, ", ")}"
        end

      raise ArgumentError, message: "#{mix_dep_message}#{lib_dep_message}"
    end

    manifest
  end

  def new!(_config, _) do
    raise "uniform.exs should contain a keyword list"
  end

  defp eval(app_name_underscore_case) do
    manifest_path = manifest_path(app_name_underscore_case)

    if File.exists?(manifest_path) do
      {manifest, _bindings} = Code.eval_file(manifest_path)
      manifest
    else
      raise Uniform.NotEjectableError, app_name: app_name_underscore_case
    end
  end

  @doc """
  Relative file path to the manifest file.

  ### Example

      iex> manifest_path("my_app")
      "lib/my_app/uniform.exs"

  """
  @spec manifest_path(String.t() | atom) :: String.t()
  def manifest_path(app_name_underscore_case) do
    "lib/#{app_name_underscore_case}/uniform.exs"
  end
end

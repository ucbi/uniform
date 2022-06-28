defmodule Eject.Deps do
  @moduledoc "A struct containing all dependencies associated with an ejectable app."

  defstruct [:lib, :mix, :included, :all]

  alias Eject.{LibDep, MixDep, Manifest}

  @type dep :: LibDep.t() | MixDep.t()

  @typedoc """
  A struct containing all dependencies associated with an ejectable app.

  Intended to be attached to the `deps` field of `t:Eject.App.t/0`.

  Struct fields to identify which deps to eject:
    - `:lib` – all included `%LibDeps{}`
    - `:mix` – all included `%MixDeps{}`
    - `:included` – all included lib and mix deps as atom names (same as pulling keys from above structs)

  Struct fields to verify manifest and callback implementations:
    - `:all` – *all* mix and lib dep names that _could_ be included in an
      app. The `all` field helps identify and warn on references to mix or
      lib deps that are not in the `c:Eject.mix_deps/0` or `c:Eject.lib_deps/0`
      callback implementations.
  """
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

  @doc """
  Given a manifest struct, returns a `%Deps{}` struct containing
  information about lib and mix dependencies.
  """
  @spec discover!(Manifest.t()) :: t
  def discover!(manifest) do
    all_lib_deps = LibDep.all()
    all_mix_deps = MixDep.all()
    lib_deps = lib_deps_included_in_app(manifest, all_lib_deps)
    mix_deps = mix_deps_included_in_app(manifest, lib_deps, all_mix_deps)

    struct!(
      __MODULE__,
      %{
        lib: lib_deps,
        mix: mix_deps,
        included: %{
          lib: Map.keys(lib_deps),
          mix: Map.keys(mix_deps)
        },
        all: %{
          lib: Map.keys(all_lib_deps),
          mix: Map.keys(all_mix_deps)
        }
      }
    )
  end

  @spec lib_deps_included_in_app(Manifest.t(), %{atom => LibDep.t()}) :: %{atom => LibDep.t()}
  defp lib_deps_included_in_app(manifest, all_lib_deps) do
    root_deps =
      Map.filter(
        all_lib_deps,
        fn {_, lib_dep} -> lib_dep.always || lib_dep.name in manifest.lib_deps end
      )

    root_deps
    |> Map.values()
    |> Enum.reduce(root_deps, &gather(&1, :lib_deps, &2, all_lib_deps))
  end

  @spec mix_deps_included_in_app(Manifest.t(), %{atom => LibDep.t()}, %{atom => MixDep.t()}) :: %{
          atom => MixDep.t()
        }
  defp mix_deps_included_in_app(manifest, lib_deps, all_mix_deps) do
    root_deps =
      Map.filter(
        all_mix_deps,
        fn {_, mix_dep} -> mix_dep.name in manifest.mix_deps end
      )

    # gather nested mix deps required by manifest
    root_deps =
      root_deps
      |> Enum.map(fn {_name, dep} -> dep end)
      |> Enum.reduce(
        root_deps,
        &gather(&1, :mix_deps, &2, all_mix_deps)
      )

    # gather mix deps required by lib deps, which have already been flattened
    lib_deps
    |> Map.values()
    |> Enum.reduce(root_deps, &gather(&1, :mix_deps, &2, all_mix_deps))
  end

  @spec gather(dep, :lib_deps | :mix_deps, %{atom => dep}, %{atom => dep}) :: %{
          atom => dep
        }
  defp gather(dep, children_field, gathered, all_of_type) do
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
          gather(nested_dep, children_field, gathered, all_of_type)
        else
          type =
            case dep do
              %LibDep{} -> :lib
              %MixDep{} -> :mix
            end

          raise "#{type}_dep #{dep.name} has a child #{type}_dep #{child_name} which isn't defined in master #{type}_deps function"
        end
      end
    end)
  end
end

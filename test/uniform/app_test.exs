defmodule Uniform.AppTest do
  use ExUnit.Case
  doctest Uniform.App, import: true

  alias Uniform.{Config, Manifest, App, LibDep, MixDep}

  defmodule Blueprint do
    use Uniform.Blueprint

    def extra(_app) do
      [company: :app_test_co, logo_file: "logo.png"]
    end

    deps do
      always do
        lib :always_included_lib
        mix :always_included_mix
      end

      lib :included_lib do
        lib_deps [:indirectly_included_lib]
        mix_deps [:included_mix]
      end

      mix :included_mix do
        mix_deps [:indirect_mix]
      end
    end
  end

  defmodule MixProject do
    def project, do: [deps: deps()]

    defp deps do
      [
        {:included_mix, "0.1.0"},
        {:always_included_mix, "0.1.0"},
        {:indirect_mix, "0.1.0"},
        {:excluded_mix, "0.1.0"}
      ]
    end
  end

  test "new!/3" do
    cwd = File.cwd!()
    on_exit(fn -> File.cd!(cwd) end)
    File.cd!("test/projects/full")

    config = %Config{
      mix_project_app: :test,
      mix_project: MixProject,
      blueprint: Blueprint,
      destination: "/Users/me/code"
    }

    manifest = %Manifest{
      lib_deps: [:included_lib],
      extra: [some_data: "from uniform.exs"]
    }

    %App{} = app = App.new!(config, manifest, "tweeter")

    assert app.name == %{
             module: Tweeter,
             hyphen: "tweeter",
             underscore: "tweeter",
             camel: "Tweeter"
           }

    assert app.internal.config == config
    assert app.destination == "/Users/me/code/tweeter"

    assert app.extra == [
             company: :app_test_co,
             logo_file: "logo.png",
             some_data: "from uniform.exs"
           ]

    assert %LibDep{mix_deps: [:included_mix], lib_deps: [:indirectly_included_lib]} =
             app.internal.deps.lib.included_lib

    assert %LibDep{mix_deps: [], lib_deps: []} = app.internal.deps.lib.indirectly_included_lib
    assert %MixDep{mix_deps: [:indirect_mix]} = app.internal.deps.mix.included_mix
    assert %MixDep{mix_deps: []} = app.internal.deps.mix.indirect_mix

    assert Enum.sort(app.internal.deps.included.lib) == [
             :always_included_lib,
             :included_lib,
             :indirectly_included_lib
           ]

    assert Enum.sort(app.internal.deps.included.mix) == [
             :always_included_mix,
             :included_mix,
             :indirect_mix
           ]

    assert Enum.sort(app.internal.deps.all.lib) == [
             :always_included_lib,
             :excluded_lib,
             :included_lib,
             :indirectly_included_lib,
             :tweeter,
             :uniform,
             :with_only
           ]

    assert Enum.sort(app.internal.deps.all.mix) == [
             :always_included_mix,
             :excluded_mix,
             :included_mix,
             :indirect_mix
           ]
  end

  test "depends_on?/1" do
    assert App.depends_on?(
             %Uniform.App{
               internal: %{
                 deps: %{
                   included: %{
                     mix: [:some_included_mix_dep]
                   }
                 }
               }
             },
             :mix,
             :some_included_mix_dep
           )

    refute App.depends_on?(
             %Uniform.App{internal: %{deps: %{included: %{mix: [:included]}}}},
             :mix,
             :not_included_dep
           )

    assert App.depends_on?(
             %Uniform.App{internal: %{deps: %{included: %{lib: [:some_included_lib]}}}},
             :lib,
             :some_included_lib
           )
  end
end

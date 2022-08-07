defmodule Uniform.AppTest do
  use Uniform.TestProjectCase
  doctest Uniform.App, import: true

  alias Uniform.{Config, Manifest, App, LibDep, MixDep}

  test "new!/3" do
    config = %Config{
      mix_project_app: :test_project,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.Blueprint,
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

    assert app.internal.config == %Config{
             mix_project_app: :test_project,
             mix_project: TestProject.MixProject,
             blueprint: TestProject.Uniform.Blueprint,
             destination: "/Users/me/code"
           }

    assert app.destination == "/Users/me/code/tweeter"
    assert app.extra == [company: :fake_co, logo_file: "pixel", some_data: "from uniform.exs"]

    assert %LibDep{mix_deps: [:included_mix], lib_deps: [:indirectly_included_lib, :with_only]} =
             app.internal.deps.lib.included_lib

    assert %LibDep{mix_deps: [], lib_deps: []} = app.internal.deps.lib.indirectly_included_lib
    assert %MixDep{mix_deps: [:indirectly_included_mix]} = app.internal.deps.mix.included_mix
    assert %MixDep{mix_deps: []} = app.internal.deps.mix.indirectly_included_mix

    assert app.internal.deps.included.lib == [
             :always_included_lib,
             :included_lib,
             :indirectly_included_lib,
             :with_only
           ]

    assert app.internal.deps.included.mix == [
             :always_included_mix,
             :included_mix,
             :indirectly_included_mix
           ]

    assert app.internal.deps.all.lib == [
             :always_included_lib,
             :excluded_lib,
             :included_lib,
             :indirectly_included_lib,
             :tweeter,
             :uniform,
             :with_only
           ]

    assert app.internal.deps.all.mix == [
             :always_included_mix,
             :excluded_mix,
             :included_mix,
             :indirectly_included_mix,
             :uniform
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

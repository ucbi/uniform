defmodule Eject.AppTest do
  use Eject.ProjectCase
  doctest Eject.App, import: true

  alias Eject.{Config, Manifest, App, LibDep, MixDep}

  test "new!/3" do
    config = %Config{
      base_app: :test_project,
      mix_module: TestProject.MixProject,
      module: TestProject.Eject.Project,
      destination: "/Users/me/code"
    }

    manifest = %Manifest{
      lib_deps: [:included_lib],
      extra: [some_data: "from eject.exs"]
    }

    %App{} = app = App.new!(config, manifest, Tweeter)

    assert app.name == %{
             module: Tweeter,
             web_module: TweeterWeb,
             kebab: "tweeter",
             snake: "tweeter",
             pascal: "Tweeter"
           }

    assert app.config == %Config{
             base_app: :test_project,
             mix_module: TestProject.MixProject,
             module: TestProject.Eject.Project,
             destination: "/Users/me/code"
           }

    assert app.destination == "/Users/me/code/tweeter"
    assert app.extra == [company: :fake_co, logo_file: "pixel", some_data: "from eject.exs"]

    assert %LibDep{mix_deps: [:included_mix], lib_deps: [:indirectly_included_lib, :with_only]} =
             app.deps.lib.included_lib

    assert %LibDep{mix_deps: [], lib_deps: []} = app.deps.lib.indirectly_included_lib
    assert %MixDep{mix_deps: [:indirectly_included_mix]} = app.deps.mix.included_mix
    assert %MixDep{mix_deps: []} = app.deps.mix.indirectly_included_mix

    assert app.deps.included.lib == [
             :always_included_lib,
             :included_lib,
             :indirectly_included_lib,
             :with_only
           ]

    assert app.deps.included.mix == [
             :always_included_mix,
             :included_mix,
             :indirectly_included_mix
           ]

    assert app.deps.all.lib == [
             :always_included_lib,
             :eject,
             :excluded_lib,
             :included_lib,
             :indirectly_included_lib,
             :tweeter,
             :with_only
           ]

    assert app.deps.all.mix == [
             :always_included_mix,
             :excluded_mix,
             :included_mix,
             :indirectly_included_mix
           ]
  end
end

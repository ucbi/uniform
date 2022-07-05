defmodule Eject.AppTest do
  use ExUnit.Case, async: true
  doctest Eject.App, import: true

  alias Eject.{Project, Manifest, App, LibDep, MixDep}

  test "new!/3" do
    project = %Project{
      base_app: :test_app,
      module: TestApp.Project,
      destination: "/Users/me/code"
    }

    manifest = %Manifest{
      lib_deps: [:included_lib],
      extra: [some_data: "from eject.exs"]
    }

    %App{} = app = App.new!(project, manifest, Tweeter)

    assert app.name == %{
             module: Tweeter,
             web_module: TweeterWeb,
             kebab: "tweeter",
             snake: "tweeter",
             pascal: "Tweeter"
           }

    assert app.project == %Project{
             base_app: :test_app,
             module: TestApp.Project,
             destination: "/Users/me/code"
           }

    assert app.destination == "/Users/me/code/tweeter"
    assert app.extra == [some_data: "from eject.exs"]

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

    assert app.deps.included.mix == [:included_mix, :indirectly_included_mix]

    assert app.deps.all.lib == [
             :always_included_lib,
             :excluded_lib,
             :included_lib,
             :indirectly_included_lib,
             :with_only
           ]

    assert app.deps.all.mix == [:excluded_mix, :included_mix, :indirectly_included_mix]
  end
end

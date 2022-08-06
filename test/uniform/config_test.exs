defmodule Uniform.ConfigTest do
  use Uniform.TestProjectCase

  alias Uniform.{LibDep, MixDep, Config}

  setup do
    config = %Config{
      mix_project_app: :test_project,
      mix_project: TestProject.MixProject,
      blueprint: TestProject.Uniform.Blueprint
    }

    %{config: config}
  end

  test "lib_deps/1", %{config: config} do
    assert %LibDep{
             lib_deps: [:indirectly_included_lib, :with_only],
             mix_deps: [:included_mix]
           } = Config.lib_deps(config).included_lib

    assert %LibDep{lib_deps: [], mix_deps: []} = Config.lib_deps(config).indirectly_included_lib
    assert %LibDep{lib_deps: [], mix_deps: []} = Config.lib_deps(config).excluded_lib
  end

  test "mix_deps/1", %{config: config} do
    assert %MixDep{
             mix_deps: [:indirectly_included_mix]
           } = Config.mix_deps(config).included_mix

    assert %MixDep{mix_deps: []} = Config.mix_deps(config).indirectly_included_mix
    assert %MixDep{mix_deps: []} = Config.mix_deps(config).excluded_mix
  end
end

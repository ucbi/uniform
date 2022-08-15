defmodule Uniform.ConfigTest do
  use ExUnit.Case

  alias Uniform.Config

  defmodule Blueprint do
    use Uniform.Blueprint

    deps do
      lib :uniform do
        lib_deps [:mix]
        mix_deps [:indirect_mix]
      end
    end
  end

  defmodule EmptyBlueprint do
    use Uniform.Blueprint
  end

  defmodule MixDepsBlueprint do
    use Uniform.Blueprint

    deps do
      mix :included_mix do
        mix_deps [:indirect_mix]
      end
    end
  end

  defmodule MixProject do
    def project, do: [deps: deps()]
    defp deps, do: [{:included_mix, "0.1.0"}, {:indirect_mix, "0.1.0"}, {:excluded_mix, "0.1.0"}]
  end

  setup do
    config = %Config{mix_project_app: :test, mix_project: MixProject, blueprint: Blueprint}
    %{config: config}
  end

  test "lib_deps/1", %{config: config} do
    uniform = Config.lib_deps(config).uniform
    assert uniform.lib_deps == [:mix]
    assert uniform.mix_deps == [:indirect_mix]

    # mix as an indirectly included dep
    mix = Config.lib_deps(config).mix
    assert mix.lib_deps == []
    assert mix.mix_deps == []

    # mix as an excluded dep
    mix = Config.lib_deps(%{config | blueprint: EmptyBlueprint}).mix
    assert mix.lib_deps == []
    assert mix.mix_deps == []
  end

  test "mix_deps/1", %{config: config} do
    config = %{config | blueprint: MixDepsBlueprint}
    mix_deps = Config.mix_deps(config)
    # included deps are returned
    assert mix_deps.included_mix.mix_deps == [:indirect_mix]
    # indirectly included deps are returned
    assert mix_deps.indirect_mix.mix_deps == []
    # excluded deps are returned
    assert mix_deps.excluded_mix.mix_deps == []
  end
end

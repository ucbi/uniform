defmodule Mix.Tasks.Uniform.InitTest do
  use ExUnit.Case

  test "mix uniform.init" do
    root = "test/projects/initable/"
    original_config = File.read!(root <> "config/config.exs")

    on_exit(fn ->
      File.rm!(root <> "lib/initable/uniform/blueprint.ex")
      File.write!(root <> "config/config.exs", original_config)
    end)

    {stdout, 0} = System.cmd("mix", ["uniform.init"], cd: root)

    assert stdout == """
           Created lib/initable/uniform/blueprint.ex
           Added configuration in config/config.exs
           """

    config = File.read!(root <> "config/config.exs")

    assert config =~ """
           # uniform:remove
           config :initable, Uniform, blueprint: Initable.Uniform.Blueprint
           # /uniform:remove
           """

    # check Blueprint for invalid Elixir (compilation error would happen)
    blueprint = File.read!(root <> "lib/initable/uniform/blueprint.ex")
    Code.compile_string(blueprint)
    # check config.exs for invalid Elixir (will raise exception)
    config = File.read!(root <> "config/config.exs")
    Code.string_to_quoted!(config)
  end
end

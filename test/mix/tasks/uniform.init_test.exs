defmodule Mix.Tasks.Uniform.InitTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  setup do
    cwd = File.cwd!()
    File.cd("test/support/initable_project")
    # restore working directory
    on_exit(fn -> File.cd(cwd) end)
  end

  test "mix uniform.init" do
    original_config = File.read!("config/config.exs")

    stdout = capture_io(fn -> Mix.Task.run("uniform.init") end)

    assert stdout == """
           Created lib/test_project/uniform/blueprint.ex
           Added configuration in config/config.exs
           """

    config = File.read!("config/config.exs")

    assert config =~ """
           # uniform:remove
           config :test_project, Uniform, blueprint: TestProject.Uniform.Blueprint
           # /uniform:remove
           """

    blueprint = File.read!("lib/test_project/uniform/blueprint.ex")
    config = File.read!("config/config.exs")
    # file system cleanup
    File.rm!("lib/test_project/uniform/blueprint.ex")
    File.write!("config/config.exs", original_config)

    # mute warnings about redefining TestProject.Uniform.Blueprint
    Code.compiler_options(ignore_module_conflict: true)
    # check Blueprint for invalid Elixir (compilation error would happen)
    Code.compile_string(blueprint)
    # reload canonical blueprint since we just redefined it
    Code.compile_file("../test_project/lib/uniform/blueprint.ex")
    # check config.exs for invalid Elixir (will raise exception)
    Code.string_to_quoted!(config)

    # reset option
    Code.compiler_options(ignore_module_conflict: false)
  end
end

defmodule Mix.Tasks.Uniform.Gen.AppTest do
  use Uniform.TestProjectCase

  import ExUnit.CaptureIO

  test "creates the directory and empty uniform.exs" do
    # remove stdout from test output
    capture_io(fn -> Mix.Task.run("uniform.gen.app", ["new_test_app"]) end)
    {manifest, []} = Code.eval_file("lib/new_test_app/uniform.exs")
    assert manifest == []
    on_exit(fn -> File.rm_rf!("lib/new_test_app") end)
  end
end

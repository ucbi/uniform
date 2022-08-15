defmodule Mix.Tasks.Uniform.Gen.AppTest do
  use ExUnit.Case

  test "creates the directory and empty uniform.exs" do
    on_exit(fn -> File.rm_rf!("test/projects/full/lib/new_app") end)
    {stdout, 0} = System.cmd("mix", ["uniform.gen.app", "new_app"], cd: "test/projects/full")
    assert stdout == "Created lib/new_app/uniform.exs\n"
    {manifest, []} = Code.eval_file("test/projects/full/lib/new_app/uniform.exs")
    assert manifest == []
  end
end

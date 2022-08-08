defmodule Mix.Tasks.Uniform.EjectableAppsTest do
  use Uniform.TestProjectCase

  import ExUnit.CaptureIO

  test "lists ejectable app names" do
    stdout = capture_io(fn -> Mix.Task.run("uniform.ejectable_apps") end)
    assert stdout == "tweeter\n"
  end
end

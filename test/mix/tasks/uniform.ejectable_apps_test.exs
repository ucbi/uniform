defmodule Mix.Tasks.Uniform.EjectableAppsTest do
  use ExUnit.Case

  test "lists ejectable app names" do
    {stdout, 0} =
      System.cmd(
        "mix",
        ["uniform.ejectable_apps"],
        cd: "test/projects/full"
      )

    assert stdout == "tweeter\n"
  end
end

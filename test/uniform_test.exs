defmodule UniformTest do
  use ExUnit.Case

  setup do
    cwd = File.cwd!()
    on_exit(fn -> File.cd!(cwd) end)
    File.cd!("test/projects/full")
    :ok
  end

  test "ejectable_app_names/0" do
    assert ["tweeter"] = Uniform.ejectable_app_names()
  end

  test "ejectable_apps/0" do
    {stdout, 0} =
      System.cmd(
        "mix",
        ["run", "-e", "Uniform.ejectable_apps()|> inspect(pretty: true) |> IO.puts()"]
      )

    assert stdout ==
             """
             [
               #Uniform.App<
                 extra: [company: :fake_co, logo_file: "pixel"],
                 name: %{
                   camel: "Tweeter",
                   hyphen: "tweeter",
                   module: Tweeter,
                   underscore: "tweeter"
                 },
                 ...
               >
             ]
             """
  end
end

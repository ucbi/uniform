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
    command =
      "Uniform.ejectable_apps() |> hd() |> Map.delete(:__struct__) |> inspect() |> IO.puts()"

    {stdout, 0} = System.cmd("mix", ["run", "-e", command])
    {map, []} = Code.eval_string(stdout)
    app = Map.put(map, :__struct__, Uniform.App)
    assert app.extra == [company: :fake_co, logo_file: "pixel"]

    assert app.name == %{
             camel: "Tweeter",
             hyphen: "tweeter",
             module: Tweeter,
             underscore: "tweeter"
           }
  end
end

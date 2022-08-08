defmodule UniformTest do
  use Uniform.TestProjectCase

  test "ejectable_app_names/0" do
    assert ["tweeter"] = Uniform.ejectable_app_names()
  end

  test "ejectable_apps/0" do
    assert [%Uniform.App{} = app] = Uniform.ejectable_apps()
    assert app.extra == [company: :fake_co, logo_file: "pixel"]

    assert app.name == %{
             camel: "Tweeter",
             hyphen: "tweeter",
             module: Tweeter,
             underscore: "tweeter"
           }
  end
end

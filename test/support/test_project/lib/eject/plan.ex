defmodule TestProject.Eject.Plan do
  use Eject.Plan, templates: "templates"

  @preserve [".gitignore"]

  def app_lib_except(_app) do
    [~r/excluded/]
  end

  def extra(_app) do
    [company: :fake_co, logo_file: "pixel"]
  end

  def target_path("lib/tweeter/lib_dir_changed.txt", _app) do
    "lib/tweeter_changed/lib_dir_changed.txt"
  end

  def target_path("lib/included_lib/lib_dir_changed.txt", _app) do
    "lib/included_lib_changed/lib_dir_changed.txt"
  end

  def target_path(source, _app), do: source

  base_files do
    cp "assets/static/images/#{app.extra[:logo_file]}.png"
    template "config/runtime.exs"

    if app.extra[:company] == :fake_co do
      file [".dotfile", ".another-dotfile"]
      cp_r "dir"
    end
  end

  modify ~r/\.dotfile/, fn file, app ->
    String.replace(
      file,
      "[REPLACE THIS LINE VIA modify/0]",
      "[REPLACED LINE WHILE EJECTING #{app.name.camel}]"
    )
  end

  defmodule Modify do
    def append_hello_world(file) do
      file <> "hello world"
    end

    def append_app_name(file, app) do
      file <> "app name is #{app.name.hyphen}"
    end
  end

  modify ~r/\.dotfile/, &Modify.append_hello_world/1
  modify ~r/\.dotfile/, &Modify.append_app_name/2

  deps do
    always do
      lib :always_included_lib do
        except ~r/excluded/
      end

      mix :always_included_mix
    end

    lib :included_lib do
      mix_deps [:included_mix]
      lib_deps [:indirectly_included_lib, :with_only]

      cp_r "priv"
      cp "priv/associated.txt"
      file "priv/associated.txt"
      template("priv/included_lib/template.txt", chmod: 0o555)

      except ~r/excluded/
    end

    lib :with_only do
      only ~r/included.txt/
    end

    mix :included_mix do
      mix_deps [:indirectly_included_mix]
    end
  end
end

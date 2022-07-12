defmodule TestProject.Eject.Plan do
  use Eject.Plan, templates: "templates"

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

  eject(app) do
    preserve ".gitignore"
    cp "assets/static/images/#{app.extra[:logo_file]}.png"
    template "config/runtime.exs"

    except ~r/excluded/

    if app.extra[:company] == :fake_co do
      file ".dotfile"
      cp_r "dir"
    end
  end

  modify ~r/\.dotfile/, file, app do
    String.replace(
      file,
      "[REPLACE THIS LINE VIA modify/0]",
      "[REPLACED LINE WHILE EJECTING #{app.name.camel}]"
    )
  end

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
      template "priv/included_lib/template.txt"

      except ~r/excluded/
      lib_directory &TestProject.Eject.Plan.included_lib_dir/2
    end

    lib :with_only do
      only ~r/included.txt/
    end

    mix :included_mix do
      mix_deps [:indirectly_included_mix]
    end
  end

  def included_lib_dir(_app, file_path) do
    if String.contains?(file_path, "lib_dir_changed") do
      "included_lib_changed"
    end
  end
end

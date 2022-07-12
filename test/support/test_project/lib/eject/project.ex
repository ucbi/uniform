defmodule TestProject.Eject.Project do
  use Eject, templates: "templates"

  deps do
    always do
      lib :always_included_lib
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
      lib_directory &TestProject.Eject.Project.included_lib_dir/2
    end

    lib :with_only do
      only ~r/included.txt/
    end

    mix :included_mix, mix_deps: [:indirectly_included_mix]
  end

  eject(app) do
    cp "assets/static/images/#{app.extra[:logo_file]}.png"
    template "config/runtime.exs"
    preserve ".gitignore"

    if app.extra[:company] == :fake_co do
      file ".dotfile"
      cp_r "dir"
    end
  end

  modify ~r/\.dotfile/, file, app do
    String.replace(
      file,
      "[REPLACE THIS LINE VIA modify/0]",
      "[REPLACED LINE WHILE EJECTING #{app.name.pascal}]"
    )
  end

  project do
    app_options(
      except: [
        ~r/excluded/
      ],
      only: [
        ~r/dotfile/,
        ~r/\/included/,
        # add `excluded` to `only` so that we're truly testing whether
        # `except` works (they can be layered)
        ~r/excluded/,
        ~r/lib_dir_changed/
      ],
      lib_directory: &TestProject.Eject.Project.lib_dir_changed/2
    )
  end

  def extra(_app) do
    [company: :fake_co, logo_file: "pixel"]
  end

  def included_lib_dir(_app, file_path) do
    if String.contains?(file_path, "lib_dir_changed") do
      "included_lib_changed"
    end
  end

  def lib_dir_changed(_app, file_path) do
    if String.contains?(file_path, "lib_dir_changed") do
      "tweeter_changed"
    end
  end
end

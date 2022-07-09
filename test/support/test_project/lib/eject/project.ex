defmodule TestProject.Eject.Project do
  use Eject, templates: "templates"

  project do
    app except: [
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

    file ".dotfile"
    binary "assets/static/images/pixel.png"
    dir "dir"
    template "config/runtime.exs"

    preserve ".gitignore"

    lib :included_lib,
      mix_deps: [:included_mix],
      lib_deps: [:indirectly_included_lib, :with_only],
      associated_files: ["priv/associated.txt"],
      except: [~r/excluded/],
      lib_directory: &TestProject.Eject.Project.included_lib_dir/2

    lib :always_included_lib, always: true
    lib :with_only, only: [~r/included.txt/]

    mix :included_mix, mix_deps: [:indirectly_included_mix]

    modify ~r/\.dotfile/, file, app do
      String.replace(
        file,
        "[REPLACE THIS LINE VIA modify/0]",
        "[REPLACED LINE WHILE EJECTING #{app.name.pascal}]"
      )
    end
  end

  def extra(_app) do
    []
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

defmodule Full.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "templates"

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
      "[REPLACE THIS LINE VIA modify]",
      "[REPLACED LINE WHILE EJECTING #{app.name.camel}]"
    )
  end

  modify ~r/\.dotfile/, &(&1 <> "Added to #{&2.name.camel} in anonymous function capture")

  # test eject_fences/1
  modify ~r/\.dotfile/, &eject_fences(&1, &2, "---")

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

      mix :decimal
    end

    lib :included_lib do
      mix_deps [:esbuild]
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

    mix :esbuild do
      mix_deps [:sourceror]
    end
  end

  # For testing that imported and inline functions are available in templates
  import String, only: [upcase: 1], warn: false
  def inline_upcase(string), do: String.upcase(string)
end

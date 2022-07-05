defmodule TestApp.Project do
  use Eject, templates: "test/support/test_project/templates"

  def extra(_app) do
    []
  end

  def lib_deps do
    [
      :indirectly_included_lib,
      :excluded_lib,
      always_included_lib: [always: true],
      included_lib: [
        mix_deps: [:included_mix],
        lib_deps: [:indirectly_included_lib, :with_only],
        associated_files: [
          "test/support/test_project/priv/associated.txt"
        ],
        except: [
          ~r/excluded/
        ],
        lib_directory: fn _app, file_path ->
          if String.contains?(file_path, "lib_dir_changed") do
            "included_lib_changed"
          end
        end
      ],
      with_only: [
        only: [
          ~r/included.txt/
        ]
      ]
    ]
  end

  def mix_deps do
    [
      :excluded_mix,
      :indirectly_included_mix,
      included_mix: [
        mix_deps: [:indirectly_included_mix]
      ]
    ]
  end

  def base_files(_app) do
    [
      {:dir, "test/support/test_project/dir"},
      {:template, "config/runtime.exs"},
      "test/support/test_project/.dotfile"
    ]
  end

  def modify do
    [
      {~r/\.dotfile/, &modify_dotfile/2}
    ]
  end

  def options(_app) do
    [
      preserve: [".gitignore"],
      ejected_app: [
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
        lib_directory: fn _app, file_path ->
          if String.contains?(file_path, "lib_dir_changed") do
            "tweeter_changed"
          end
        end
      ]
    ]
  end

  defp modify_dotfile(file_contents, app) do
    String.replace(
      file_contents,
      "[REPLACE THIS LINE VIA modify/0]",
      "[REPLACED LINE WHILE EJECTING #{app.name.pascal}]"
    )
  end
end

defmodule <%= @app_module %>.Uniform.Blueprint do
  use Uniform.Blueprint, templates: "lib/<%= @app_underscore %>/uniform/templates"

  @impl Uniform.Blueprint
  def extra(_app) do
    # keyword list with data to access in `base_files`, templates, and `modify`
    []
  end

  # Add files that should be ejected with every application here.
  base_files do
    # eject a file with code transformations
    # file "path/to/file"

    # eject a file without code transformations like this
    # cp "assets/static/images/#{app.extra[:logo_file]}.png"

    # uncomment the following if you're ejecting Phoenix applications
    # (ejects all of assets/ without code transformations)
    # cp_r "assets"

    # eject a template like this
    # template "config/runtime.exs"

    # you can conditionally eject files like this
    # if app.extra[:foo] == :bar do
    #   file ["some/file.ex", "another/file.ex"]
    #   cp_r "dir"
    # end
  end

  # use modifiers as a hook to transform file contents before ejecting
  # modify "config/config.exs", file do
  #   file <> "config :foo, bar: :baz"
  # end

  # mix or lib dependencies should be listed here if they should always be
  # ejected, or if they require extra configuration
  deps do
    always do
      lib :<%= @app_underscore %> do
        only [
          "lib/<%= @app_underscore %>/application.ex"
        ]
      end

      # uncomment the following if you're ejecting Phoenix applications
      # lib :<%= @app_underscore %>_web do
      #   only [
      #     "lib/<%= @app_underscore %>_web/endpoint.ex",
      #     "lib/<%= @app_underscore %>_web/gettext.ex",
      #     "lib/<%= @app_underscore %>_web/router.ex",
      #     "lib/<%= @app_underscore %>_web/telemetry.ex",
      #     "lib/<%= @app_underscore %>_web/channels/user_socket.ex",
      #     "lib/<%= @app_underscore %>_web/views/error_helpers.ex",
      #     "lib/<%= @app_underscore %>_web/views/error_view.ex",
      #     "lib/<%= @app_underscore %>_web/views/layout_view.ex",
      #     "lib/<%= @app_underscore %>_web/templates/layout/app.html.heex",
      #     "lib/<%= @app_underscore %>_web/templates/layout/live.html.heex",
      #     "lib/<%= @app_underscore %>_web/templates/layout/root.html.heex"
      #   ]
      # end

      # add mix deps for all applications here
      # mix :phoenix
      # mix :phoenix_html
      # mix :ecto
    end

    # Example lib dependency configuration:
    # lib :<%= @app_underscore %>_data do
    #   mix_deps [:rustler]
    #   lib_deps [:utilities]
    #   cp_r "priv/<%= @app_underscore %>_data/jpegs"
    #   cp "priv/<%= @app_underscore %>_data/bin/some-binary"
    #   file "priv/some-file.txt"
    #   template "lib/mix/tasks/some_task_from_a_template.ex"
    # end

    # Example mix dependency configuration:
    # mix :absinthe do
    #   mix_deps [:absinthe_plug, :dataloader]
    # end
  end

  # uncomment this line to not delete these root-level files on `mix uniform.eject`
  # @preserve [".vscode"]

  # uncomment to specify files NOT to eject from the lib directory of the app
  # @impl Uniform.Blueprint
  # def app_lib_except(_app) do
  #   # add specific file paths or regexes
  #   [
  #     ~r/some_regex/,
  #     "path/to/specific/file.ex"
  #   ]
  # end

  # Uncomment this hook to change the destination path of files.
  # Remember to include a fallback for files you don't want to modify.
  # @impl Uniform.Blueprint
  # def target_path("some/path.ex", app) do
  #   "some/new/path.ex"
  # end
  #
  # def target_path(source, _app), do: source
end

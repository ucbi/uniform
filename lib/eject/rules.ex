defmodule Eject.Rules do
  @moduledoc "A struct representing 'rules' to apply while ejecting files."

  defstruct [:only, :except, :associated_files, :chmod, :lib_directory]

  @typedoc """
  A function that takes an `%Eject.App{}` struct and the relative path of a
  given file, returning `nil` (i.e. do nothing) or a string.

  If a string is returned, the file will be written to a lib directory with
  that name. For example, if the function receives `app`, `lib/foo/bar.baz` and
  returns `new`, the file will be ejected at `lib/new/bar.baz` instead of the
  default behavior of ejecting to the matching path of `lib/foo/bar.baz`.
  """
  @type lib_directory_fn ::
          (Eject.App.t(), relative_path :: String.t() -> lib_directory :: String.t() | nil)

  @typedoc """
  Rules defining how to eject files from a `lib/` library.

  ### Options

  - `only: ["path/to/file", "path/to/other/file.ex", ~r/regex/]` – only ejects files
    with a relative path equaling one of the strings in this list, or that match any
    regex appearing in this list.
  - `except: ["path/to/file", "path/to/other/file.ex", ~r/regex/]` – do _not_ eject files
    with a relative path equaling one of the strings in this list, or that match any
    regex appearing in this list.
  - `associated_files: ["path/to/file", ...]` – also eject all files in the given list
    whenever this lib is ejected. Intended to be used for files outside this
    `lib/` directory.
  - `chmod: 0o755` – after copying the file, change the `mode` for the given file.
    See https://hexdocs.pm/elixir/File.html#chmod/2-permissions for permission options.
  - `lib_directory: fn app, path -> ... end` – see `t:lib_directory_fn/0` for details.
  """
  @type t :: %__MODULE__{
          only: nil | [String.t() | Regex.t()],
          except: nil | [String.t() | Regex.t()],
          associated_files: nil | [{:text | :template | :cp | :cp_r, String.t()}],
          chmod: nil | non_neg_integer,
          lib_directory: nil | lib_directory_fn
        }

  @doc "Initializes a new `%Rules{}` struct."
  def new(params) when is_list(params) do
    struct!(
      __MODULE__,
      Keyword.take(params, ~w(only except associated_files lib_directory chmod)a)
    )
  end
end

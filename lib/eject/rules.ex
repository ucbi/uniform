defmodule Eject.Rules do
  @moduledoc """
             A struct representing 'rules' to apply while ejecting files.
             """ && false

  defstruct [:only, :except, :associated_files, :chmod]

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
  """
  @type t :: %__MODULE__{
          only: nil | [String.t() | Regex.t()],
          except: nil | [String.t() | Regex.t()],
          associated_files: nil | [{:text | :template | :cp | :cp_r, String.t()}],
          chmod: nil | non_neg_integer
        }

  @doc "Initializes a new `%Rules{}` struct."
  def new(params) when is_list(params) do
    struct!(
      __MODULE__,
      Keyword.take(params, ~w(only except associated_files chmod)a)
    )
  end
end

defmodule Eject.LibDep do
  @moduledoc """
             A struct for a dependency within a sub folder in the `lib/` directory.
             """ && false

  @enforce_keys [:name, :always, :mix_deps, :lib_deps]
  defstruct [:name, :always, :mix_deps, :lib_deps, :only, :except, :associated_files]

  @typedoc "The name of a `lib/` dependency."
  @type name :: atom

  @typedoc """
  Optional rules defining how to eject files from a `lib/` library.

  ### Options

  Each field in the `t:Eject.Rules.t/0` struct can be passed in this keyword list, which
  are then used to build the struct itself. See `Eject.Rules` for more information.
  """
  @type file_rule :: keyword

  @type t :: %__MODULE__{
          name: name,
          always: boolean,
          mix_deps: [Eject.MixDep.name()],
          lib_deps: [name],
          only: nil | [String.t() | Regex.t()],
          except: nil | [String.t() | Regex.t()],
          associated_files: nil | [{:text | :template | :cp | :cp_r, String.t()}]
        }

  @doc """
  Creates a new `%LibDep{}` struct.

  ### Example

      iex> new!(%{
      ...>   name: :my_graph,
      ...>   mix_deps: [:absinthe],
      ...>   lib_deps: [:my_graph_dep],
      ...>   always: true,
      ...>   only: nil,
      ...>   except: [~r/regex-of-files-not-to-eject/],
      ...>   associated_files: ["priv/path/to/associated/file"],
      ...> })
      %Eject.LibDep{
        always: true,
        associated_files: ["priv/path/to/associated/file"],
        except: [~r/regex-of-files-not-to-eject/],
        only: nil,
        lib_deps: [:my_graph_dep],
        mix_deps: [:absinthe],
        name: :my_graph
      }

  """
  def new!(
        %{
          name: name,
          mix_deps: mix_deps,
          lib_deps: lib_deps,
          always: always
        } = params
      )
      when is_atom(name) and is_list(lib_deps) and is_list(mix_deps) and is_boolean(always) do
    struct!(__MODULE__, params)
  end
end

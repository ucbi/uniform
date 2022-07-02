defmodule Eject.LibDep do
  @moduledoc "A struct for a dependency within a sub folder in the `lib/` directory."

  @enforce_keys [:name, :always, :mix_deps, :lib_deps, :file_rules]
  defstruct [:name, :always, :mix_deps, :lib_deps, :file_rules]

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
          file_rules: Eject.Rules.t()
        }

  @doc "Creates a new `%LibDep{}` struct."
  def new!(%{
        name: name,
        mix_deps: mix_deps,
        lib_deps: lib_deps,
        always: always,
        file_rules: %Eject.Rules{} = file_rules
      })
      when is_atom(name) and is_list(lib_deps) and is_list(mix_deps) and is_boolean(always) do
    struct!(__MODULE__,
      name: name,
      lib_deps: lib_deps,
      mix_deps: mix_deps,
      always: always,
      file_rules: file_rules
    )
  end
end

defmodule Eject.MixDep do
  @moduledoc "A struct for a dependency in mix.exs."

  defstruct [:name, :mix_deps]

  @typedoc "The name of a mix.exs dependency."
  @type name :: atom

  @type t :: %__MODULE__{
          name: name,
          mix_deps: [name]
        }

  @doc "Creates a new `%MixDep{}` struct."
  def new!(%{name: name, mix_deps: mix_deps}) when is_atom(name) and is_list(mix_deps) do
    struct!(__MODULE__, name: name, mix_deps: mix_deps)
  end
end

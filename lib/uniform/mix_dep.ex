defmodule Eject.MixDep do
  @moduledoc "A struct for a dependency in mix.exs." && false

  @enforce_keys [:name, :always, :mix_deps]
  defstruct [:name, :always, :mix_deps]

  @typedoc "The name of a mix.exs dependency."
  @type name :: atom

  @type t :: %__MODULE__{
          name: name,
          always: boolean,
          mix_deps: [name]
        }

  @doc """
  Creates a new `%MixDep{}` struct.

  ### Example

      iex> new!(%{
      ...>   name: :swoosh,
      ...>   always: true,
      ...>   mix_deps: [:phoenix_swoosh]
      ...> })
      %Eject.MixDep{
        name: :swoosh,
        always: true,
        mix_deps: [:phoenix_swoosh]
      }

  """
  def new!(%{name: name, always: always, mix_deps: mix_deps})
      when is_atom(name) and is_boolean(always) and is_list(mix_deps) do
    struct!(__MODULE__, name: name, always: always, mix_deps: mix_deps)
  end
end

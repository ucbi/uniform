defmodule Eject.MixDep do
  @moduledoc "A struct for a dependency in mix.exs."

  alias __MODULE__
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

  @doc """
  Returns all mix deps that can be ejected, in the form of a map where the key is
  the mix dep's name.

  Hydrated using the `c:Eject.mix_deps/0` callback implementation, e.g. `YourProject.Eject.Project.mix_deps/1`.
  """
  @spec all :: %{MixDep.name() => MixDep.t()}
  def all do
    project = Eject.project()

    project.mix_deps()
    |> Enum.map(fn
      {dep, opts} -> {dep, opts}
      dep -> {dep, []}
    end)
    |> Enum.map(fn {dep, opts} ->
      {dep,
       MixDep.new!(%{
         name: dep,
         mix_deps: opts |> Keyword.get(:mix_deps, []) |> List.wrap()
       })}
    end)
    |> Enum.into(%{})
  end
end

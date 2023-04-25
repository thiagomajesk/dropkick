defmodule Dropkick.Attachment do
  @derive {Jason.Encoder, only: [:key]}
  @enforce_keys [:key, :storage, :filename]
  defstruct [:key, :status, :storage, :filename, :content_type, :metadata, versions: []]

  use Ecto.Type

  def type, do: :map

  def cast(%__MODULE__{} = atch), do: {:ok, atch}
  def cast(atch) when is_map(atch), do: {:ok, struct(__MODULE__, atch)}
  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      Enum.map(data, fn
        {"versions", v} -> {:versions, Enum.map(v, &load/1)}
        {"status", v} -> {:status, String.to_existing_atom(v)}
        {"storage", v} -> {:storage, String.to_existing_atom(v)}
        {k, v} -> {String.to_existing_atom(k), v}
      end)

    {:ok, struct!(__MODULE__, data)}
  end

  def dump(%__MODULE__{} = atch), do: {:ok, Map.from_struct(atch)}
  def dump(data) when is_map(data), do: {:ok, data}
  def dump(_), do: :error
end

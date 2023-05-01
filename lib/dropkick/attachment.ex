defmodule Dropkick.Attachment do
  @moduledoc """
  Represents an attachment that can be saved to a database
  """
  @derive Jason.Encoder
  @enforce_keys [:key, :storage]
  defstruct [:key, :storage, :filename, :content_type, :metadata, versions: []]

  use Ecto.Type

  def type, do: :map

  def cast(token) when is_binary(token) do
    case Dropkick.Security.check(token) do
      {:ok, key} ->
        name = Dropkick.Attachable.name(key)
        type = Dropkick.Attachable.type(key)
        storage = Dropkick.Storage.current()

        data = %{
          key: key,
          filename: name,
          content_type: type,
          storage: storage
        }

        {:ok, struct!(__MODULE__, data)}

      {:error, reason} ->
        {:error, "Invalid token #{reason}"}
    end
  end

  def cast(%__MODULE__{} = atch), do: {:ok, atch}
  def cast(atch) when is_map(atch), do: {:ok, struct(__MODULE__, atch)}
  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      Enum.map(data, fn
        {"versions", v} ->
          {:versions, Enum.map(v, &load_version/1)}

        {"storage", v} ->
          {:storage, String.to_atom(v)}

        {k, v} ->
          {String.to_existing_atom(k), v}
      end)

    {:ok, struct!(__MODULE__, data)}
  end

  def dump(%__MODULE__{} = atch), do: {:ok, Map.from_struct(atch)}
  def dump(data) when is_map(data), do: {:ok, data}
  def dump(_), do: :error

  defp load_version(version) do
    case load(version) do
      {:ok, data} -> data
      {:error, reason} -> raise "Failed to load version #{reason}"
    end
  end
end

defmodule Dropkick.Ecto.File do
  @derive Jason.Encoder
  @enforce_keys [:key, :storage, :status, :filename, :content_type]
  defstruct [:key, :storage, :status, :filename, :content_type, :metadata]

  use Ecto.Type

  @impl true
  def type, do: :map

  @impl true
  def cast(%__MODULE__{} = file), do: {:ok, file}

  def cast(%{filename: filename, path: path, content_type: content_type}) do
    {:ok,
     %__MODULE__{
       key: path,
       storage: Dropkick.Storage.Disk,
       status: :cached,
       filename: filename,
       content_type: content_type
     }}
  end

  def cast(_), do: :error

  @impl true
  def load(data) when is_map(data) do
    data =
      Enum.map(data, fn
        {"storage", v} ->
          {:storage, String.to_atom(v)}

        {"status", "cached"} ->
          {:status, :cached}

        {"status", "stored"} ->
          {:status, :stored}

        {k, v} ->
          {String.to_existing_atom(k), v}
      end)

    {:ok, struct!(__MODULE__, data)}
  end

  @impl true
  def dump(%__MODULE__{} = file), do: {:ok, Map.from_struct(file)}
  def dump(data) when is_map(data), do: {:ok, data}
  def dump(_), do: :error
end

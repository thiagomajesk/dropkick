defmodule Dropkick.File do
  @derive {Inspect, only: [:key]}
  @derive {Jason.Encoder, except: [:binary]}
  @enforce_keys [:key, :status, :filename, :content_type]
  defstruct [:key, :status, :filename, :content_type, :binary, :metadata]

  use Ecto.ParameterizedType

  @impl true
  def type(_params \\ %{}), do: :map

  @impl true
  def init(opts), do: Enum.into(opts, %{})

  @impl true
  def cast(_data, _params \\ %{})

  def cast(nil, _params), do: {:ok, nil}

  def cast(%__MODULE__{} = file, _params), do: {:ok, file}

  def cast(%{filename: filename, path: path}, %{infer: true}) do
    case Infer.get_from_path(path) do
      nil ->
        {:error, "File might be invalid. Could not infer file type information"}

      %{extension: ext, mime_type: content_type} ->
        filename = Path.basename(filename, Path.extname(filename))

        {:ok,
         %__MODULE__{
           key: path,
           status: :cached,
           binary: File.read!(path),
           filename: "#{filename}.#{ext}",
           content_type: content_type
         }}
    end
  end

  def cast(%{filename: filename, path: path, content_type: content_type}, _params) do
    {:ok,
     %__MODULE__{
       key: path,
       status: :cached,
       binary: File.read!(path),
       filename: filename,
       content_type: content_type
     }}
  end

  def cast(_data, _params), do: :error

  @impl true
  def load(_data, _loader \\ nil, _params \\ %{})

  def load(nil, _loader, _params), do: {:ok, nil}

  def load(data, _loader, _params) when is_map(data) do
    data =
      Enum.map(data, fn
        {"status", k} ->
          {:status, String.to_existing_atom(k)}

        {k, v} ->
          {String.to_existing_atom(k), v}
      end)

    {:ok, struct!(__MODULE__, data)}
  end

  @impl true
  def dump(_data, _dumper \\ nil, _params \\ %{})
  def dump(nil, _dumper, _params), do: {:ok, nil}
  def dump(%__MODULE__{} = file, _dumper, _params), do: {:ok, Map.from_struct(file)}
  def dump(data, _dumper, _params) when is_map(data), do: {:ok, data}
  def dump(_data, _dumper, _params), do: :error

  @impl true
  def equal?(_val1, _val2, _params \\ %{})
  def equal?(%{key: key1}, %{key: key2}, _params), do: key1 == key2
  def equal?(val1, val2, _params), do: val1 == val2
end

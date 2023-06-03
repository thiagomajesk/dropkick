defmodule Dropkick.File do
  @moduledoc """
  A custom type that maps a upload-like structure to a file.

    * `:key` - The location of the the uploaded file
    * `:content_type` - The content type of the uploaded file
    * `:filename` - The filename of the uploaded file given in the request
    * `:status` - The status of the uploaded file. It can be `:cached` (when the file
    was just casted from a `Plug.Upload` and the key points to a temporary directory), `:deleted` (when
    the file was deleted from the storage and the key points to its old location) and `:stored` (when the
    file was persisted to its final destination and the key points to its current location).
    * `:metadata` - This field is meant to be used by users to store metadata about the file.
    * `:__cache__` - This field is used to store internal in-memmory information about the file that might
    be relevant during processing (this field is currently not used internally and its not casted to the database).

  ## Security

  Like `Plug.Upload`, the `:content_type` and `:filename` fields are client-controlled.
  Because of this, you should inspect and validate these values before trusting the upload content.
  You can check the file's [magic number](https://en.wikipedia.org/wiki/Magic_number_(programming)) signature
  by passing the option `infer: true` to your fields:

      field :avatar, Dropkick.File, infer: true
  """
  @derive {Inspect, optional: [:metadata], except: [:__cache__]}
  @derive {Jason.Encoder, except: [:__cache__]}
  @enforce_keys [:key, :status, :filename, :content_type]
  defstruct [:__cache__, :key, :status, :filename, :content_type, :metadata]

  use Ecto.ParameterizedType

  @impl true
  def type(_params), do: :map

  @impl true
  def init(opts), do: Enum.into(opts, %{})

  @impl true
  def cast(nil, _params), do: {:ok, nil}

  def cast(%__MODULE__{} = file, _params), do: {:ok, file}

  def cast(%{filename: filename, path: path, content_type: content_type}, params) do
    case Map.get(params, :infer, false) && Infer.get_from_path(path) do
      nil ->
        {:error, "File might be invalid. Could not infer file type information"}

      false ->
        {:ok,
         %__MODULE__{
           key: path,
           status: :cached,
           filename: filename,
           content_type: content_type
         }}

      %{extension: ext, mime_type: type} ->
        filename = Path.basename(filename, Path.extname(filename))

        {:ok,
         %__MODULE__{
           key: path,
           status: :cached,
           filename: "#{filename}.#{ext}",
           content_type: type
         }}
    end
  end

  def cast(_data, _params), do: :error

  @impl true
  def load(nil, _loader, _params), do: {:ok, nil}

  def load(data, _loader, _params) when is_map(data) do
    data =
      Enum.map(data, fn
        {"status", v} ->
          {:status, String.to_atom(v)}

        {k, v} ->
          {String.to_existing_atom(k), v}
      end)

    {:ok, struct!(__MODULE__, data)}
  end

  @impl true
  def dump(nil, _dumper, _params), do: {:ok, nil}
  def dump(%__MODULE__{} = file, _dumper, _params), do: {:ok, from_map(file)}
  def dump(data, _dumper, _params) when is_map(data), do: {:ok, from_map(data)}
  def dump(_data, _dumper, _params), do: :error

  @impl true
  def equal?(%{key: key1}, %{key: key2}, _params), do: key1 == key2
  def equal?(val1, val2, _params), do: val1 == val2

  defp from_map(map) do
    Map.take(map, [
      :key,
      :status,
      :filename,
      :content_type,
      :metadata
    ])
  end
end

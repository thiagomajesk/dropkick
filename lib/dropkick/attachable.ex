defprotocol Dropkick.Attachable do
  @spec key(struct() | binary()) :: String.t()
  def key(upload)

  @spec name(struct() | binary()) :: String.t()
  def name(upload)

  @spec content(struct() | binary()) :: {:ok, iodata()} | {:error, String.t()}
  def content(upload)
end

defimpl Dropkick.Attachable, for: BitString do
  def key(path), do: path

  def name(path), do: Path.basename(path)

  def content(path) do
    if Regex.match?(~r"^http(s?)\:\/\/.+", path) do
      Dropkick.Attachable.content(URI.new!(path))
    else
      case File.read(Path.expand(path)) do
        {:error, reason} -> {:error, "Could not read path: #{reason}"}
        success_tuple -> success_tuple
      end
    end
  end
end

defimpl Dropkick.Attachable, for: Plug.Upload do
  def key(%Plug.Upload{path: path}), do: path

  def name(%Plug.Upload{filename: name}), do: name

  def content(%Plug.Upload{path: path}) do
    case File.read(path) do
      {:error, reason} -> {:error, "Could not read path: #{reason}"}
      success_tuple -> success_tuple
    end
  end
end

defimpl Dropkick.Attachable, for: URI do
  def key(%URI{path: path}), do: path

  def name(%URI{path: path}), do: Path.basename(path)

  def content(%URI{} = uri) do
    uri = String.to_charlist(URI.to_string(uri))

    case :httpc.request(:get, {uri, []}, [], body_format: :binary) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, content}} ->
        {:ok, content}

      {:ok, {{'HTTP/1.1', code, _}, _headers, _}} ->
        {:error, "Unsuccessful response code: #{code}"}

      {:error, {reason, _}} ->
        {:error, "Could not read path: #{reason}"}
    end
  end
end

defimpl Dropkick.Attachable, for: Dropkick.Attachment do
  def key(%{key: key}), do: key

  def name(%{filename: name}), do: name

  def content(attachment) do
    case attachment do
      %{storage: nil} ->
        raise "No storage defined for this attachment"

      %{storage: storage} when is_atom(storage) ->
        storage.read(attachment)

      %{storage: storage} ->
        raise("#{inspect(storage)} is not a module")
    end
  end
end

defimpl Dropkick.Attachable, for: Dropkick.Transform do
  def key(%{key: key}), do: key

  def name(%{filename: name}), do: name

  def content(%{content: content}), do: content
end

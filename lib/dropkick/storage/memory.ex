defmodule Dropkick.Storage.Memory do
  @behaviour Dropkick.Storage

  @impl true
  def store(%Dropkick.Ecto.File{status: :cached} = file, _opts \\ []) do
    with {:ok, content} <- file.storage.read(file),
         {:ok, pid} <- StringIO.open(content) do
      key = encode_key(pid, file.filename)
      {:ok, Map.merge(file, %{key: key, status: :stored, storage: __MODULE__})}
    end
  end

  @impl true
  def read(%Dropkick.Ecto.File{} = file, _opts \\ []) do
    if storage = file.storage != Dropkick.Storage.Memory do
      raise Dropkick.Storage.incompatible_storage_message(:read, __MODULE__, storage)
    end

    {:ok, read_from_memory(file)}
  end

  @impl true
  def copy(%Dropkick.Ecto.File{} = file, dest, _opts \\ []) do
    if storage = file.storage != Dropkick.Storage.Memory do
      raise Dropkick.Storage.incompatible_storage_message(:copy, __MODULE__, storage)
    end

    with content <- read_from_memory(file),
         {:ok, pid} <- StringIO.open(content) do
      {:ok, Map.replace!(file, :key, encode_key(pid, dest))}
    end
  end

  @impl true
  def delete(%Dropkick.Ecto.File{} = file, _opts \\ []) do
    if storage = file.storage != Dropkick.Storage.Memory do
      raise Dropkick.Storage.incompatible_storage_message(:delete, __MODULE__, storage)
    end

    pid = decode_key(file.key)
    with {:ok, _} <- StringIO.close(pid), do: :ok
  end

  @doc false
  def encode_key(pid, suffix) when is_pid(pid) do
    encoded =
      pid
      |> :erlang.pid_to_list()
      |> List.to_string()
      |> Base.url_encode64()

    Path.join(["mem://", encoded, suffix])
  end

  @doc false
  def decode_key(key) when is_binary(key) do
    # https://www.erlang.org/doc/man/erlang.html#list_to_pid-1
    # This BIF is intended for debugging and is not to be used in application programs.
    <<"mem://", encoded::binary-size(12), ?/, _rest::binary>> = key

    encoded
    |> Base.url_decode64!()
    |> to_charlist()
    |> :erlang.list_to_pid()
  end

  defp read_from_memory(%{key: key}) do
    key
    |> decode_key()
    |> StringIO.contents()
    |> then(&elem(&1, 0))
  end
end

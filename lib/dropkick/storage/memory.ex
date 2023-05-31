defmodule Dropkick.Storage.Memory do
  # A note about converting list to pids and vice-versa...
  # This BIF is intended for debugging and is not to be used in application programs.
  # This storage strategy should be used for tests only: https://www.erlang.org/doc/man/erlang.html#list_to_pid-1
  @behaviour Dropkick.Storage

  @impl true
  def store(%Dropkick.File{status: :cached} = file, _opts \\ []) do
    with {:ok, content} <- File.read(file.key),
         {:ok, pid} <- StringIO.open(content) do
      key = encode_key(pid, file.filename)
      {:ok, Map.merge(file, %{key: key, status: :stored})}
    end
  end

  @impl true
  def read(%Dropkick.File{} = file, _opts \\ []) do
    {:ok, read_from_memory(file)}
  end

  @impl true
  def copy(%Dropkick.File{} = file, dest, _opts \\ []) do
    with content <- read_from_memory(file),
         {:ok, pid} <- StringIO.open(content) do
      {:ok, Map.replace!(file, :key, encode_key(pid, dest))}
    end
  end

  @impl true
  def delete(%Dropkick.File{} = file, _opts \\ []) do
    with pid <- decode_key(file.key),
         {:ok, _} <- StringIO.close(pid) do
      {:ok, Map.replace!(file, :status, :deleted)}
    end
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

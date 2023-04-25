defmodule Dropkick.Storage.Memory do
  alias Dropkick.{Storage, Attachable, Attachment}

  @behaviour Storage

  @impl Storage
  def put(upload, _opts \\ []) do
    with {:ok, content} <- Attachable.content(upload),
         {:ok, pid} <- StringIO.open(content) do
      name = Attachable.name(upload)
      key = encode_key(pid, name)

      {:ok,
       %Attachment{
         key: key,
         filename: name,
         storage: __MODULE__,
         status: :stored
       }}
    end
  end

  @impl Storage
  def read(%Attachment{} = atch, _opts \\ []) do
    {:ok, read_from_memory(atch)}
  end

  @impl Storage
  def copy(%Attachment{} = atch, path, _opts \\ []) do
    with content <- read_from_memory(atch),
         {:ok, pid} <- StringIO.open(content) do
      {:ok, Map.replace!(atch, :key, encode_key(pid, path))}
    end
  end

  @impl Storage
  def delete(%Attachment{} = atch, _opts \\ []) do
    pid = decode_key(Attachable.key(atch))
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

  defp read_from_memory(atch) do
    atch
    |> Attachable.key()
    |> decode_key()
    |> StringIO.contents()
    |> then(&elem(&1, 0))
  end
end

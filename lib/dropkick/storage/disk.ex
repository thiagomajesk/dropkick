defmodule Dropkick.Storage.Disk do
  alias Dropkick.{Storage, Attachable, Attachment}

  @behaviour Storage

  @impl Storage
  def put(attachable, opts \\ []) do
    folder = Keyword.get(opts, :folder, "uploads")
    prefix = Keyword.get(opts, :prefix, "/")

    name = Attachable.name(attachable)
    path = Path.join([folder, prefix, name])

    with :ok <- File.mkdir_p!(Path.dirname(path)),
         {:ok, content} <- Attachable.content(attachable) do
      File.write!(path, content)

      {:ok,
       %Attachment{
         key: path,
         filename: name,
         storage: __MODULE__,
         status: :stored
       }}
    end
  end

  @impl Storage
  def read(atch, opts \\ [])

  @impl Storage
  def read(%Attachment{storage: Dropkick.Storage.Disk} = atch, _opts) do
    case File.read(Attachable.key(atch)) do
      {:error, reason} -> {:error, "Could not read file: #{reason}"}
      success_result -> success_result
    end
  end

  @impl Storage
  def read(%Attachment{} = atch, _opts) do
    case Attachable.content(atch) do
      {:error, reason} -> {:error, "Could not read file: #{reason}"}
      success_result -> success_result
    end
  end

  @impl Storage
  def copy(atch, path, opts \\ [])

  @impl Storage
  def copy(%Attachment{storage: Dropkick.Storage.Disk} = atch, path, opts) do
    move? = Keyword.get(opts, :move, false)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- move_or_rename(Attachable.key(atch), path, move?) do
      {:ok, Map.replace!(atch, :key, path)}
    else
      {:error, reason} -> {:error, "Could not copy file: #{reason}"}
    end
  end

  @impl Storage
  def copy(%Attachment{} = atch, dest, _opts) do
    with {:ok, content} <- Attachable.content(atch),
         :ok <- File.write(Attachable.key(atch), content) do
      {:ok, Map.replace!(atch, :key, dest)}
    else
      {:error, reason} -> {:error, "Could not copy file: #{reason}"}
    end
  end

  @impl Storage
  def delete(%Attachment{} = atch, _opts \\ []) do
    case File.rm(Attachable.key(atch)) do
      {:error, reason} -> {:error, "Could not delete file: #{reason}"}
      success_result -> success_result
    end
  end

  defp move_or_rename(src, dest, false), do: File.cp(src, dest)
  defp move_or_rename(src, dest, true), do: File.rename(src, dest)
end

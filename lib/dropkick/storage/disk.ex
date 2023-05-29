defmodule Dropkick.Storage.Disk do
  @behaviour Dropkick.Storage

  @impl true
  def store(%Dropkick.Ecto.File{status: :cached} = file, opts \\ []) do
    folder = Keyword.fetch!(opts, :folder)
    key = Path.join(folder, file.filename)

    with :ok <- File.mkdir_p(Path.dirname(key)),
         {:ok, content} <- File.read(file.key),
         File.write(key, content) do
      {:ok, Map.merge(file, %{key: key, status: :stored})}
    end
  end

  @impl true
  def read(%Dropkick.Ecto.File{} = file, _opts \\ []) do
    case File.read(file.key) do
      {:error, reason} -> {:error, "Could not read file: #{reason}"}
      success_result -> success_result
    end
  end

  @impl true
  def copy(%Dropkick.Ecto.File{} = file, dest, opts \\ []) do
    move? = Keyword.get(opts, :move, false)

    with :ok <- File.mkdir_p(Path.dirname(dest)),
         :ok <- move_or_rename(file.key, dest, move?) do
      {:ok, Map.replace!(file, :key, dest)}
    else
      {:error, reason} -> {:error, "Could not copy file: #{reason}"}
    end
  end

  @impl true
  def delete(%Dropkick.Ecto.File{} = file, _opts \\ []) do
    case File.rm(file.key) do
      :ok -> {:ok, Map.replace!(file, :status, :deleted)}
      {:error, reason} -> {:error, "Could not delete file: #{reason}"}
    end
  end

  defp move_or_rename(src, dest, false), do: File.cp(src, dest)
  defp move_or_rename(src, dest, true), do: File.rename(src, dest)
end

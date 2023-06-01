defmodule Dropkick.Uploader do
  @callback storage_prefix(any()) :: String.t()

  @callback on_before_store(any(), Dropkick.File.t()) :: {module(), Keyword.t()}
  @callback on_after_store(any(), Dropkick.File.t()) :: {module(), Keyword.t()}

  @callback on_before_delete(any(), Dropkick.File.t()) :: {module(), Keyword.t()}
  @callback on_after_delete(any(), Dropkick.File.t()) :: {module(), Keyword.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      require Logger

      @doc """
      Stores the given `%Dropkick.File` struct.
      """
      def store(scope, %Dropkick.File{} = file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(scope),
             {:ok, file} <- __MODULE__.on_before_store(scope, file) do
          file
          |> storage.store(folder: folder, prefix: prefix)
          |> Dropkick.Task.after_success(fn file ->
            with {:ok, file} <- __MODULE__.on_after_store(scope, file) do
              Logger.info("Finished storing file #{inspect(file)}")
            end
          end)
        end
      end

      @doc """
      Deletes the given `%Dropkick.File` struct.
      """
      def delete(scope, %Dropkick.File{} = file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(scope),
             {:ok, file} <- __MODULE__.on_before_delete(scope, file) do
          file
          |> storage.delete(folder: folder, prefix: prefix)
          |> Dropkick.Task.after_success(fn file ->
            with {:ok, file} <- __MODULE__.on_after_delete(scope, file) do
              Logger.info("Finished deleting file #{inspect(file)}")
            end
          end)
        end
      end

      def storage_prefix(_scope), do: ""

      def on_before_store(_scope, file), do: {:ok, file}
      def on_after_store(_scope, file), do: {:ok, file}

      def on_before_delete(_scope, file), do: {:ok, file}
      def on_after_delete(_scope, file), do: {:ok, file}

      defoverridable storage_prefix: 1,
                     on_before_store: 2,
                     on_after_store: 2,
                     on_before_delete: 2,
                     on_after_delete: 2
    end
  end
end

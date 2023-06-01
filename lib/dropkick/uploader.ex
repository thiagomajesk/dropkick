defmodule Dropkick.Uploader do
  @callback storage_prefix(struct(), atom()) :: String.t()

  @callback on_before_store(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}
  @callback on_after_store(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}

  @callback on_before_delete(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}
  @callback on_after_delete(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      require Logger

      @doc """
      Stores the given `%Dropkick.File` struct.
      """
      def store(schema, field, %Dropkick.File{} = file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(schema, field),
             {:ok, file} <- __MODULE__.on_before_store(schema, field, file) do
          file
          |> storage.store(folder: folder, prefix: prefix)
          |> Dropkick.Task.after_success(fn file ->
            with {:ok, file} <- __MODULE__.on_after_store(schema, field, file) do
              Logger.info("Finished storing file #{inspect(file)}")
            end
          end)
        end
      end

      @doc """
      Deletes the given `%Dropkick.File` struct.
      """
      def delete(schema, field, %Dropkick.File{} = file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(schema, field),
             {:ok, file} <- __MODULE__.on_before_delete(schema, field, file) do
          file
          |> storage.delete(folder: folder, prefix: prefix)
          |> Dropkick.Task.after_success(fn file ->
            with {:ok, file} <- __MODULE__.on_after_delete(schema, field, file) do
              Logger.info("Finished deleting file #{inspect(file)}")
            end
          end)
        end
      end

      def storage_prefix(_schema, _field), do: ""

      def on_before_store(_schema, _field, file), do: {:ok, file}
      def on_after_store(_schema, _field, file), do: {:ok, file}

      def on_before_delete(_schema, _field, file), do: {:ok, file}
      def on_after_delete(_schema, _field, file), do: {:ok, file}

      defoverridable storage_prefix: 2,
                     on_before_store: 3,
                     on_after_store: 3,
                     on_before_delete: 3,
                     on_after_delete: 3
    end
  end
end

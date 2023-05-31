defmodule Dropkick.Uploader do
  @callback storage_prefix(struct(), atom()) :: String.t()
  @callback on_before_store(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}
  @callback on_before_delete(struct(), atom(), Dropkick.File.t()) :: {module(), Keyword.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      @doc """
      Stores the given file
      """
      def store(schema, field, file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(schema, field),
             {:ok, file} <- __MODULE__.on_before_store(schema, field, file) do
          storage.store(file, folder: folder, prefix: prefix)
        end
      end

      @doc """
      Deletes the given file
      """
      def delete(schema, field, file) do
        with storage <- Application.fetch_env!(:dropkick, :storage),
             folder <- Application.fetch_env!(:dropkick, :folder),
             prefix <- __MODULE__.storage_prefix(schema, field),
             {:ok, file} <- __MODULE__.on_before_delete(schema, field, file) do
          storage.delete(file, folder: folder, prefix: prefix)
        end
      end

      def storage_prefix(_schema, _field), do: ""
      def on_before_store(_schema, _field, file), do: {:ok, file}
      def on_before_delete(_schema, _field, file), do: {:ok, file}

      defoverridable storage_prefix: 2, on_before_store: 3, on_before_delete: 3
    end
  end
end

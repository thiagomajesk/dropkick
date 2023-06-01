defmodule Dropkick.Uploader do
  @callback storage_prefix(any()) :: String.t()

  @callback on_before_store(Dropkick.File.t(), any()) :: :ok
  @callback on_after_store(Dropkick.File.t(), any()) :: :ok

  @callback on_before_delete(Dropkick.File.t(), any()) :: :ok
  @callback on_after_delete(Dropkick.File.t(), any()) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      require Logger

      @doc """
      Stores the given `%Dropkick.File` struct.
      """
      def store(%Dropkick.File{status: :cached} = file, scope) do
        storage = Application.fetch_env!(:dropkick, :storage)
        folder = Application.fetch_env!(:dropkick, :folder)
        prefix = __MODULE__.storage_prefix(scope)

        :ok = __MODULE__.on_before_store(file, scope)

        file
        |> storage.store(folder: folder, prefix: prefix)
        |> Dropkick.Task.after_success(fn file ->
          :ok = __MODULE__.on_after_store(file, scope)
          Logger.info("Finished storing file #{inspect(file)}")
        end)
      end

      @doc """
      Deletes the given `%Dropkick.File` struct.
      """
      def delete(%Dropkick.File{} = file, scope) do
        storage = Application.fetch_env!(:dropkick, :storage)
        :ok = __MODULE__.on_before_delete(file, scope)

        file
        |> storage.delete()
        |> Dropkick.Task.after_success(fn file ->
          :ok = __MODULE__.on_after_delete(file, scope)
          Logger.info("Finished deleting file #{inspect(file)}")
        end)
      end

      def storage_prefix(_scope), do: ""

      def on_before_store(file, _scope), do: :ok
      def on_after_store(file, _scope), do: :ok

      def on_before_delete(file, _scope), do: :ok
      def on_after_delete(file, _scope), do: :ok

      defoverridable storage_prefix: 1,
                     on_before_store: 2,
                     on_after_store: 2,
                     on_before_delete: 2,
                     on_after_delete: 2
    end
  end
end

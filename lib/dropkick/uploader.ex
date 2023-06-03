defmodule Dropkick.Uploader do
  @moduledoc """
  Defines the behaviour for a file uploader.
  """

  @doc """
  Returns the storage path for a given scope.
  This function can be used to personalize the directory where files are saved.

  ## Example

  You can user pattern matching to specify multiple clauses:

      def storage_prefix({store, :logo}), do: "avatars/\#{user.id}"
      def storage_prefix({user, :avatar}), do: "avatars/\#{user.id}"
      def storage_prefix({%{id: id}, _}), do: "files/\#{id}"
  """
  @callback storage_prefix(any()) :: String.t()

  @doc """
  Process some logic before storing a `%Dropkick.File` struct.
  This function must return a success tuple with the file, otherwise the store operation will fail.
  When an error is returned, the store operation won't be executed and the pipeline is aborted.
  """
  @callback before_store(Dropkick.File.t(), any()) :: {:ok, Dropkick.File.t()}

  @doc """
  Process some logic after storing a `%Dropkick.File` struct.
  This function must return a success tuple with the file, otherwise the operation will fail.
  When an error is returned, the file is still stored, but the rest of the pipeline is aborted.
  """
  @callback after_store(Dropkick.File.t(), any()) :: {:ok, Dropkick.File.t()}

  @doc """
  Process some logic before deleting a `%Dropkick.File` struct.
  This function must return a success tuple with the file, otherwise the operation will fail.
  When an error is returned, the delete operation won't be executed and the pipeline is aborted.
  """
  @callback before_delete(Dropkick.File.t(), any()) :: {:ok, Dropkick.File.t()}

  @doc """
  Process some logic after deleting a `%Dropkick.File` struct.
  This function must return a success tuple with the file, otherwise the operation will fail.
  When an error is returned, the file is still deleted, but the rest of the pipeline is aborted.
  """
  @callback after_delete(Dropkick.File.t(), any()) :: {:ok, Dropkick.File.t()}

  @doc """
  Process some logic after storing/deleting a `%Dropkick.File` struct.
  When a success tuple is returned, the value is simply logged into the terminal.
  Whatever is executed inside this callback is completely isolated and doesn't affect the pipeline.
  You can implement this callback to do any post-processing with without modifying the original file.
  """
  @callback process(Dropkick.File.t(), any()) :: {:ok, Dropkick.File.t()}

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

        with {:ok, file} <- __MODULE__.before_store(file, scope),
             {:ok, file} <- storage.store(file, folder: folder, prefix: prefix),
             {:ok, file} <- __MODULE__.after_store(file, scope) do
          Dropkick.Task.tap_async({:ok, file}, fn {:ok, file} ->
            with {:ok, file} <- __MODULE__.process(file, scope) do
              Logger.info("Finished storing file #{inspect(file)}")
            end
          end)
        end
      end

      @doc """
      Deletes the given `%Dropkick.File` struct.
      """
      def delete(%Dropkick.File{} = file, scope) do
        storage = Application.fetch_env!(:dropkick, :storage)

        with {:ok, file} <- __MODULE__.before_delete(file, scope),
             {:ok, file} <- storage.delete(file),
             {:ok, file} <- __MODULE__.after_delete(file, scope) do
          Dropkick.Task.tap_async({:ok, file}, fn {:ok, file} ->
            with {:ok, result} <- __MODULE__.process(file, scope) do
              Logger.info("Finished deleting file #{inspect(result)}")
            end
          end)
        end
      end

      def storage_prefix(_scope), do: ""

      def before_store(file, _scope), do: {:ok, file}
      def after_store(file, _scope), do: {:ok, file}

      def before_delete(file, _scope), do: {:ok, file}
      def after_delete(file, _scope), do: {:ok, file}

      def process(file, _scope), do: {:ok, file}

      defoverridable storage_prefix: 1,
                     before_store: 2,
                     after_store: 2,
                     before_delete: 2,
                     after_delete: 2,
                     process: 2
    end
  end
end

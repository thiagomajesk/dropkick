defmodule Dropkick.Ecto.Repo do
  defmacro __using__(_opts) do
    quote do
      def insert_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
        %{data: %{__struct__: module}} = changeset

        fields =
          Enum.filter(module.__schema__(:fields), fn field ->
            Ecto.Changeset.changed?(changeset, field) &&
              module.__schema__(:type, field) == Dropkick.Ecto.File
          end)

        files_multi =
          Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
            Ecto.Multi.run(multi, {:file, field}, fn repo, %{insert: schema} ->
              with {:ok, file} <- uploader.store(schema, field, Map.get(schema, field)) do
                repo.update(Ecto.Changeset.change(schema, %{field => file}))
              end
            end)
          end)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:insert, changeset, opts)
        |> Ecto.Multi.append(files_multi)
        |> __MODULE__.transaction()
        |> case do
          {:ok, %{insert: schema}} ->
            {:ok, schema}

          {:error, {:file, field}, reason, %{insert: schema}} ->
            {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
        end
      end

      def update_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
        %{data: %{__struct__: module}} = changeset

        fields =
          Enum.filter(module.__schema__(:fields), fn field ->
            Ecto.Changeset.changed?(changeset, field) &&
              module.__schema__(:type, field) == Dropkick.Ecto.File
          end)

        files_multi =
          Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
            Ecto.Multi.run(multi, {:file, field}, fn repo, %{update: schema} ->
              with {:ok, file} <- uploader.store(schema, field, Map.get(schema, field)) do
                repo.update(Ecto.Changeset.change(schema, %{field => file}))
              end
            end)
          end)

        Ecto.Multi.new()
        |> Ecto.Multi.update(:update, changeset, opts)
        |> Ecto.Multi.append(files_multi)
        |> __MODULE__.transaction()
        |> case do
          {:ok, %{update: schema}} ->
            {:ok, schema}

          {:error, {:file, field}, reason, %{update: schema}} ->
            {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
        end
      end

      def delete_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
        %{data: %{__struct__: module}} = changeset

        fields =
          Enum.filter(module.__schema__(:fields), fn field ->
            module.__schema__(:type, field) == Dropkick.Ecto.File
          end)

        files_multi =
          Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
            Ecto.Multi.run(multi, {:file, field}, fn repo, %{delete: schema} ->
              uploader.delete(schema, field, Map.get(schema, field))
            end)
          end)

        Ecto.Multi.new()
        |> Ecto.Multi.delete(:delete, changeset, opts)
        |> Ecto.Multi.append(files_multi)
        |> __MODULE__.transaction()
        |> case do
          {:ok, %{delete: schema}} ->
            {:ok, schema}

          {:error, {:file, field}, reason, %{delete: schema}} ->
            {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
        end
      end
    end
  end
end

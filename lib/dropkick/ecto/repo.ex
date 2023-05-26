defmodule Dropkick.Ecto.Repo do
  defmacro __using__(_opts) do
    quote do
      def insert_with_files(%Ecto.Changeset{} = changeset, opts \\ []) do
        {uploader, opts} = Keyword.pop!(opts, :uploader)

        files_multi = files_multi(changeset, :insert, &uploader.store/3)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:insert, changeset, opts)
        |> Ecto.Multi.append(files_multi)
        |> execute_transaction()
      end

      defp files_multi(changeset, operation, callback) when is_function(callback, 3) do
        %{data: %{__struct__: module}} = changeset

        fields =
          Enum.filter(module.__schema__(:fields), fn field ->
            module.__schema__(:type, field) == Dropkick.Ecto.File
          end)

        files_multi =
          Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
            Ecto.Multi.run(multi, {:file, field}, fn repo, operations ->
              schema = Map.fetch!(operations, operation)
              callback.(schema, field, Map.get(schema, field))
            end)
          end)

        schema_multi =
          Ecto.Multi.run(Ecto.Multi.new(), :schema, fn repo, operations ->
            {schema, operations} = Map.pop!(operations, operation)

            changes =
              operations
              |> Enum.map(fn {{:file, field}, file} -> {field, file} end)
              |> Enum.into(%{})

            repo.update(Ecto.Changeset.change(schema, changes))
          end)

        Ecto.Multi.append(files_multi, schema_multi)
      end

      defp execute_transaction(multi) do
        case __MODULE__.transaction(multi) do
          {:ok, %{schema: schema}} ->
            {:ok, schema}

          {:error, :schema, changeset, _changes_so_far} ->
            {:error, changeset}

          {:error, field, {changeset, reason}, _changes_so_far} ->
            {:error, Ecto.Changeset.add_error(changeset, field, reason)}
        end
      end
    end
  end
end

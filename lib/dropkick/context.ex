defmodule Dropkick.Context do
  def insert_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
    repo = Application.fetch_env!(:dropkick, :repo)
    %{data: %{__struct__: module}} = changeset

    fields =
      Enum.filter(module.__schema__(:fields), fn field ->
        Ecto.Changeset.changed?(changeset, field) &&
          match?(
            {:parameterized, Dropkick.File, %{field: ^field}},
            module.__schema__(:type, field)
          )
      end)

    files_multi =
      Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
        Ecto.Multi.run(multi, {:file, field}, fn repo, %{insert: schema} ->
          with {:ok, file} <- uploader.store(Map.get(schema, field), {schema, field}) do
            repo.update(Ecto.Changeset.change(schema, %{field => file}))
          end
        end)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert, changeset, opts)
    |> Ecto.Multi.append(files_multi)
    |> repo.transaction()
    |> case do
      {:ok, %{insert: schema}} ->
        {:ok, schema}

      {:error, :insert, changeset, _} ->
        {:error, changeset}

      {:error, {:file, field}, reason, %{insert: _schema}} ->
        {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
    end
  end

  def update_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
    repo = Application.fetch_env!(:dropkick, :repo)
    %{data: %{__struct__: module}} = changeset

    fields =
      Enum.filter(module.__schema__(:fields), fn field ->
        Ecto.Changeset.changed?(changeset, field) &&
          match?(
            {:parameterized, Dropkick.File, %{field: ^field}},
            module.__schema__(:type, field)
          )
      end)

    files_multi =
      Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
        Ecto.Multi.run(multi, {:file, field}, fn repo, %{update: schema} ->
          with {:ok, file} <- uploader.store(Map.get(schema, field), {schema, field}) do
            # TODO: Add strategy to delete old files instead of keeping them
            repo.update(Ecto.Changeset.change(schema, %{field => file}))
          end
        end)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:update, changeset, opts)
    |> Ecto.Multi.append(files_multi)
    |> repo.transaction()
    |> case do
      {:ok, %{update: schema}} ->
        {:ok, schema}

      {:error, :update, changeset, _} ->
        {:error, changeset}

      {:error, {:file, field}, reason, %{update: _schema}} ->
        {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
    end
  end

  def delete_with_files(%Ecto.Changeset{} = changeset, uploader, opts \\ []) do
    repo = Application.fetch_env!(:dropkick, :repo)
    %{data: %{__struct__: module}} = changeset

    fields =
      Enum.filter(module.__schema__(:fields), fn field ->
        match?({:parameterized, Dropkick.File, %{field: ^field}}, module.__schema__(:type, field))
      end)

    files_multi =
      Enum.reduce(fields, Ecto.Multi.new(), fn field, multi ->
        Ecto.Multi.run(multi, {:file, field}, fn _repo, %{delete: schema} ->
          # TODO: Add strategy to keep old files instead of deleting them
          uploader.delete(Map.get(schema, field), {schema, field})
        end)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete, changeset, opts)
    |> Ecto.Multi.append(files_multi)
    |> repo.transaction()
    |> case do
      {:ok, %{delete: schema}} ->
        {:ok, schema}

      {:error, :delete, changeset, _} ->
        {:error, changeset}

      {:error, {:file, field}, reason, %{delete: _schema}} ->
        {:error, Ecto.Changeset.add_error(changeset, field, inspect(reason))}
    end
  end
end

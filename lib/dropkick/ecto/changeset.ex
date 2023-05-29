defmodule Dropkick.Ecto.Changeset do
  @doc """
  Returns a diff that can be used to define which operations should be done with a file.
  """
  def diff_files(changeset) do
    %{data: %{__struct__: module}} = changeset

    fields =
      Enum.filter(module.__schema__(:fields), fn field ->
        module.__schema__(:type, field) == Dropkick.Ecto.File
      end)

    Enum.reduce(fields, %{}, fn field, acc ->
      IO.inspect(changeset.changes, label: "CHANGES")
      old_value = Map.get(changeset.data, field)
      new_value = Ecto.Changeset.get_change(changeset, field)

      IO.inspect(old_value, label: "OL VALUE")
      IO.inspect(new_value, label: "NEW VALUE")

      case {old_value, new_value} do
        {nil, nil} ->
          acc

        {nil, new_value} ->
          Map.put(acc, {field, :store}, new_value)

        {old_value, nil} ->
          Map.put(acc, {field, :delete}, old_value)

        {old_value, new_value} ->
          acc
          |> Map.put({field, :delete}, old_value)
          |> Map.put({field, :store}, new_value)
      end
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.Ecto.File` has the allowed extensions.
  """
  def validate_upload_extension(changeset, field, accepted_extensions) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      message = "Only the following extensions are allowed #{inspect(accepted_extensions)}"
      if Path.extname(file.filename) not in accepted_extensions, do: [{field, message}], else: []
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.Ecto.File` fullfils the size requirement.
  """
  def validate_upload_size(changeset, field, opts) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      %{size: size} = File.stat!(file.key)

      cond do
        opts[:is] != nil && size != opts[:is] ->
          [{field, "The file should have exactly #{opts[:is]} bytes"}]

        opts[:max] && size > opts[:max] ->
          [{field, "The file size should be no more than #{opts[:max]} bytes"}]

        opts[:min] && size < opts[:min] ->
          [{field, "The file size should be no less than #{opts[:min]} bytes"}]

        true ->
          []
      end
    end)
  end
end

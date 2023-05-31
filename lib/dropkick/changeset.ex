defmodule Dropkick.Changeset do
  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed extensions.
  This function should be considered unsafe unless you define your file fields with `:infer`.
  """
  def validate_file_extension(%Ecto.Changeset{} = changeset, field, extensions) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      message = "Only the following extensions are allowed #{inspect(extensions)}"
      if Path.extname(file.filename) not in extensions, do: [{field, message}], else: []
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed content types.
  This function should be considered unsafe unless you define your file fields with `:infer`.
  """
  def validate_file_type(%Ecto.Changeset{} = changeset, field, content_types) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      message = "Only the following content types are allowed #{inspect(content_types)}"
      if file.content_type not in content_types, do: [{field, message}], else: []
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed size.
  """
  def validate_file_size(changeset, field, opts) do
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

defmodule Dropkick.Ecto.Changeset do
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

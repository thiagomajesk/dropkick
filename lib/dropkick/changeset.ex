defmodule Dropkick.Changeset do
  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed extensions.
  This function should be considered unsafe unless you define your file fields with `infer: true`.

  ## Example

      validate_file_extension(changeset, :avatar, ~w(png jpg))
  """
  def validate_file_extension(%Ecto.Changeset{} = changeset, field, extensions) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      <<?., extension::binary>> = Path.extname(file.filename)
      message = "Only the following extensions are allowed #{Enum.join(extensions, ",")}"
      if extension not in extensions, do: [{field, message}], else: []
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed content types.
  This function should be considered unsafe unless you define your file fields with `infer: true`.

  ## Example

      validate_file_type(changeset, :avatar, ~w(image/jpeg image/jpeg))

  """
  def validate_file_type(%Ecto.Changeset{} = changeset, field, content_types) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      message = "Only the following content types are allowed #{inspect(content_types)}"
      if file.content_type not in content_types, do: [{field, message}], else: []
    end)
  end

  @doc """
  Validates that the given field of type `Dropkick.File` has the allowed size in bytes.

  ## Options

  - `:is`: The file size must be exactly this value.
  - `:max`: The file size must be less than this value.
  - `:min`: The file size must be greater than this value.

  ## Example

      validate_file_size(changeset, :avatar, max: 10 * 1024 * 1024)
  """
  def validate_file_size(changeset, field, opts) do
    Ecto.Changeset.validate_change(changeset, field, fn field, file ->
      %{size: size} = File.stat!(file.key)

      cond do
        opts[:is] != nil && size != opts[:is] ->
          size = Sizeable.filesize(opts[:is])
          [{field, "The file should have exactly #{size}"}]

        opts[:max] && size > opts[:max] ->
          size = Sizeable.filesize(opts[:max])
          [{field, "The file size should be no more than #{size}"}]

        opts[:min] && size < opts[:min] ->
          size = Sizeable.filesize(opts[:min])
          [{field, "The file size should be no less than #{size}"}]

        true ->
          []
      end
    end)
  end
end

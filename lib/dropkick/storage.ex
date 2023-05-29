defmodule Dropkick.Storage do
  @doc """
  Stores the given file with the underlyning storage module.
  The underlyning implementation should accept any storage specific options and:

  - `:folder`: The base location where to save the file being transfered.

  Returns a success tuple like `{:ok, %Dropkick.Ecto.File{status: :stored}}`.
  """
  @callback store(Dropkick.Ecto.File.t(), Keyword.t()) ::
              {:ok, Dropkick.Ecto.File.t()} | {:error, String.t()}

  @doc """
  Reads the given file with the underlyning storage module.
  Returns a success tuple with the contents of the file.
  """
  @callback read(Dropkick.Ecto.File.t(), Keyword.t()) :: {:ok, binary()} | {:error, String.t()}

  @doc """
  Copies the given file with the underlyning storage module.
  The underlyning implementation should accept any storage specific options and:

  - `:move`: Specifies if the file should be just copied or moved entirely, defaults to `false`.

  Returns a success tuple with the attachment in the new destination like: `{:ok, %Dropkick.Ecto.File{}}`.
  """
  @callback copy(Dropkick.Ecto.File.t(), String.t(), Keyword.t()) ::
              {:ok, Dropkick.Ecto.File.t()} | {:error, String.t()}

  @doc """
  Deletes the given attachment with the underlyning storage module.
  """
  @callback delete(Dropkick.Ecto.File.t(), Keyword.t()) ::
              {:ok, Dropkick.Ecto.File.type()} | {:error, String.t()}

  @doc false
  def incompatible_storage_message(action, attempted_storage, current_storage) do
    "Incompatible storage found. Cannot #{action} this file using #{inspect(attempted_storage)} because it was stored as #{inspect(current_storage)}"
  end
end

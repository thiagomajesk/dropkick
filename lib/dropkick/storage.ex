defmodule Dropkick.Storage do
  @doc """
  Stores the given file with the underlyning storage module.
  The underlyning implementation should accept the following options (besides any specific options):

    * `:folder`: The base location where to save the file being transfered.
    * `:prefix`: A sub-folder inside the current location where the file is going to be saved, defaults to `/`.

  Returns a success tuple like: `{:ok, %Dropkick.File{}}`.
  """
  @callback store(Dropkick.File.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}

  @doc """
  Reads the given file with the underlyning storage module.
  Returns a success tuple with the content of the file like: `{:ok, content}`.
  """
  @callback read(Dropkick.File.t(), Keyword.t()) ::
              {:ok, binary()} | {:error, String.t()}

  @doc """
  Copies the given file with the underlyning storage module.
  The underlyning implementation should accept the following options (besides any specific options):

    * `:move`: Specifies if the file should be just copied or moved entirely, defaults to `false`.

  Returns a success tuple with the file in the new destination like: `{:ok, %Dropkick.File{}}`.
  """
  @callback copy(Dropkick.File.t(), String.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}

  @doc """
  Deletes the given file with the underlyning storage module.
  Returns a success tuple with the deleted the file like: `{:ok, %Dropkick.File{}}`.
  """
  @callback delete(Dropkick.File.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}
end

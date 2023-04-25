defmodule Dropkick.Storage do
  alias Dropkick.{Attachable, Attachment}

  @type option :: {atom(), any()}

  @doc """
  Stores the given attachable with the underlyning storage module.

  The underlyning implementation should accept the following options (besides any specific options):

  - `:folder`: The base location where to save the file being transfered.
  - `:prefix`: A sub-folder inside the current location where the file is going to be saved, defaults to `/`.

  Returns a success tuple like `{:ok, %Attachment{status: :stored}}`.
  """
  @callback put(Attachable.t(), [option]) :: {:ok, Attachment.t()} | {:error, String.t()}

  @doc """
  Reads the given attachment with the underlyning storage module.
  When the attachment storage is set to `Disk`, we always attempt to read the file from its key.
  Otherwise, we resort to the definition of `Attachable.content/1` so we can also read remote files if necessary.

  Returns a success tuple with the content of the file like: `{:ok, content}`.
  """
  @callback read(Attachment.t(), [option]) :: {:ok, binary()} | {:error, String.t()}

  @doc """
  Copies the given attachment with the underlyning storage module.
  When the attachment storage is set to `Disk`, we always attempt to read the file from its key.

  The underlyning implementation should accept the following options (besides any specific options):

  - `:move`: Specifies if the file should be just copied or moved entirely, defaults to `false`.

  Returns a success tuple with the attachment in the new destination like: `{:ok, %Attachment{}}`.
  """
  @callback copy(Attachment.t(), String.t(), [option]) ::
              {:ok, Attachment.t()} | {:error, String.t()}

  @doc """
  Deletes the given attachment with the underlyning storage module.
  Diferently from the `read` and `copy` actions that takes into consideration the current attachment's storage.
  This function assumes the attachment being deleted uses the configured storage. So, if your current attachment
  is configured as `Disk` and you try to delete an attachment which storage is setup as `Memory`, the call will fail.
  """
  @callback delete(Attachment.t(), [option]) :: :ok | {:error, String.t()}
end

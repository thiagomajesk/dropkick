defmodule Dropkick.Attachableer do
  @moduledoc """
  This modules provides a definition to specialized uploaders that can be used to specify custom upload workflows.
  A specialized uploader acts as a hook before calling the function at `Dropkick` and allow you to modify how the upload is handled.
  """
  alias Dropkick.{Upload, Attachment}

  @type option :: {atom(), any()}

  @type transforms ::
          :noaction
          | {:blur, list()}
          | {:resize, float(), list()}
          | {:thumbnail, pos_integer() | String.t(), list()}

  @doc """
  See `Dropkick.cache/2` for more information.
  """

  @callback cache(upload :: Upload.t(), list()) :: Attachment.type()

  @doc """
  See `Dropkick.store/2` for more information.
  """

  @callback store(upload :: Upload.t(), list()) :: Attachment.type()

  @doc """
  See `Dropkick.move/2` for more information.
  """
  @callback move(atch :: Attachment.t()) :: Attachment.type()

  @doc """
  Defines a series of validations that will be called before caching the attachment.
  """
  @callback validate(Attachment.type(), context :: map()) :: :ok | {:error, String.t()}

  @doc """
  Defines the transformations to be applied after saving attachments.
  """
  @callback transforms(Attachment.type(), context :: map()) :: transforms()

  @doc """
  Overrides the filename used when the attachment is stored.
  The original filename will still be kept as a metadata.
  """
  @callback filename(Attachment.type(), context :: map()) :: String.t()

  @doc """
  Defines the default prefix that will be used to store and retrieve uploads.
  """
  @callback storage_prefix(Attachment.type(), context :: map()) :: String.t()

  @doc """
  Provide a default URL if no upload was found
  """
  @callback default_url(context :: map()) :: String.t()

  defmacro using(_opts) do
    quote do
      @behaviour Dropkick.Attachableer

      require Logger

      def cache(upload, opts \\ []) do
        context = %{action: :cache}

        folder = Keyword.fetch!(opts, :folder, "uploads")
        prefix = __MODULE__.storage_prefix(upload, context)

        with {:ok, atch} <- Dropkick.cache(upload, folder: folder, prefix: prefix) do
          context = Map.merge(context, Dropkick.contextualize(atch))
          Dropkick.transform(atch, __MODULE__.transforms(atch, context))
        end
      end

      def store(upload, opts \\ []) do
        context = %{action: :store}

        folder = Keyword.fetch!(opts, :folder, "uploads")
        prefix = __MODULE__.storage_prefix(upload, context)

        with {:ok, atch} <- Dropkick.store(upload, folder: folder, prefix: prefix) do
          context = Map.merge(context, Dropkick.contextualize(atch))
          Dropkick.transform(atch, __MODULE__.transforms(atch, context))
        end
      end

      defdelegate move(attachment), to: Dropkick

      defdelegate url(attachment, opts), to: Dropkick

      defdelegate version(attachment, version), to: Dropkick

      def validate(_atch, _context) do
        raise "Function validate/2 not implemented for #{__MODULE__}"
      end

      def filename(%{filename: filename}, _context), do: filename

      def storage_prefix(_atch, %{action: cache}), do: to_string(cache)

      def transforms(_atch, context) do
        case context do
          %{action: :store, version: :thumbnail} ->
            {:thumbnail, "250x250", [crop: :center]}

          _context ->
            :noaction
        end
      end

      # If user has implemented this callback but forgot to deal with the proper action
      # We don't want to automatically transform attachments without letting them know.
      def transform(_atch, %{action: :cache}) do
        message = """
        It seems that you have accidentaly enabled the transformation of cached attachments...
        This could mean that you forgot to handle other actions in your `transform/2` callback implementation.
        Don't worry though, we are automatically ignoring transformations for cached attachments for you.
        If this is not desirable, please implement a version of `transform/2` that handles the `cache` action.
        """

        with :ok <- Logger.warn(message), do: :nooaction
      end

      def default_url(%{version: version}) do
        "/uploads/placeholder_#{version}.png"
      end

      defoverridable default_attachment: 2
    end
  end
end

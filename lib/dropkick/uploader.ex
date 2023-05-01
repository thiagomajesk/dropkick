defmodule Dropkick.Uploader do
  @moduledoc """
  This modules provides a definition to specialized uploaders that can be used to specify custom upload workflows.
  A specialized uploader acts as a hook before calling the function at `Dropkick` and allow you to modify how the upload is handled.
  """
  alias Dropkick.{Attachable, Attachment}

  @type option :: {atom(), any()}

  @type transforms ::
          :noaction
          | {:blur, list()}
          | {:resize, float(), list()}
          | {:thumbnail, pos_integer() | String.t(), list()}

  @doc """
  Caches an attachable by saving it on the provided directory under the "cache" prefix by default.
  When an attachable is cached we won't calculate any metadata information, the file is only
  saved to the directory. This function is usually usefull when you are doing async uploads -
  where you first save the file to a temporary location and only after some confirmation you actually move
  the file to its final destination. You probably want to clean this directory from time to time.
  """

  @callback cache({Attachable.t(), map()}, [option]) :: {:ok, Attachment.type()}

  @doc """
   Stores an attachable by saving it on the provided directory under the "store" prefix by default.
  When an attachable is stored we'll calculate metadata information before moving the file to its destination.
  """

  @callback store({Attachable.t(), map()}, [option]) :: {:ok, Attachment.type()}

  @doc """
  Defines a series of validations that will be called before caching the attachment.
  """
  @callback validate(Attachable.t(), map()) :: :ok | {:error, String.t()}

  @doc """
  Defines the transformations to be applied after saving attachments.
  """
  @callback transform(Attachment.type(), map()) :: transforms()

  @doc """
  Defines the default prefix that will be used to store and retrieve uploads.
  """
  @callback storage_prefix(Attachable.t(), map()) :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      require Logger

      def cache(struct_or_tuple, opts \\ [])

      def cache(attachable, opts) when is_struct(attachable),
        do: cache({attachable, %{}}, opts)

      def cache({attachable, scope}, opts) when is_map(scope) do
        scope = Map.put(scope, :action, :cache)

        folder = Keyword.get(opts, :folder, "uploads")
        prefix = __MODULE__.storage_prefix(attachable, scope)

        cache_opts = [folder: folder, prefix: prefix]

        with :ok <- __MODULE__.validate(attachable, scope),
             {:ok, atch} <- Dropkick.put(attachable, cache_opts) do
          metadata =
            merge_metadata([
              Dropkick.contextualize(atch),
              Dropkick.extract_metadata(atch)
            ])

          atch = Map.put(atch, :metadata, metadata)
          transforms = list_transforms(atch, scope)
          {:ok, Dropkick.transform(atch, transforms)}
        end
      end

      def store(struct_or_tuple, opts \\ [])

      def store(attachable, opts) when is_struct(attachable),
        do: store({attachable, %{}}, opts)

      def store({attachable, scope}, opts) when is_map(scope) do
        scope = Map.put(scope, :action, :store)

        folder = Keyword.get(opts, :folder, "uploads")
        prefix = __MODULE__.storage_prefix(attachable, scope)

        store_opts = [folder: folder, prefix: prefix]

        with :ok <- __MODULE__.validate(attachable, scope),
             {:ok, atch} <- Dropkick.put(attachable, store_opts) do
          metadata =
            merge_metadata([
              Dropkick.contextualize(atch),
              Dropkick.extract_metadata(atch)
            ])

          atch = Map.put(atch, :metadata, metadata)
          transforms = list_transforms(atch, scope)
          {:ok, Dropkick.transform(atch, transforms)}
        end
      end

      def url(%Attachment{key: key}) do
        Path.join(Application.get_env(:dropkick, :host, "/"), key)
      end

      def validate(_attachable, _scope) do
        raise "Function validate/2 not implemented for #{__MODULE__}"
      end

      def storage_prefix(_attachable, %{action: action}), do: to_string(action)

      def transform(%Attachment{content_type: "image/" <> _}, %{action: :store}) do
        {:thumbnail, "250x250", [crop: :center]}
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

        with :ok <- Logger.warn(message), do: :noaction
      end

      defp list_transforms(atch, scope) do
        atch
        |> __MODULE__.transform(scope)
        |> List.wrap()
        |> List.flatten()
        |> Enum.reject(&(&1 == :noaction))
      end

      defp merge_metadata(maps) do
        Enum.reduce(maps, %{}, &Map.merge(&2, &1))
      end

      defoverridable validate: 2, storage_prefix: 2, transform: 2
    end
  end
end

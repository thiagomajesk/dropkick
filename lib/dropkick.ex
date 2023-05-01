defmodule Dropkick do
  @moduledoc """
  This module provides functions that you can use to interact directly with uploads and attachments.
  """

  alias Dropkick.Attachment

  @doc """
  Creates a version of the attachment with some transformation.
  Transformations validated against an attachment `content_type`.
  The current transformations supported are:

  ## `image/*`
  Image transformations uses the [`image`](https://hexdocs.pm/image) library behind the scenes

    - `{:thumbnail, size, opts}`: Generates an image thumbnail, receives the same options
    as [`Image.thumbnail/3`](https://hexdocs.pm/image/Image.html#thumbnail/3)
  """
  def transform(%Attachment{} = atch, transforms) do
    atch
    |> transform_stream(transforms)
    |> Stream.filter(&match?({:ok, _}, &1))
    |> Enum.reduce(atch, fn {:ok, version}, atch ->
      Map.update!(atch, :versions, fn versions -> [version | versions] end)
    end)
  end

  @doc """
  Extracts context from the attachment.
  """
  def contextualize(%Attachment{} = atch) do
    key = Dropkick.Attachable.key(atch)

    %{
      extension: Path.extname(key),
      directory: Path.dirname(key),
      filename: Path.basename(key)
    }
  end

  @doc """
  Extracts metadata from the attachment.
  """
  def extract_metadata(%Attachment{content_type: "image/" <> _} = atch) do
    # If our attachment is an image, we try to extract additional information.
    # Depending on the complexity we should probably move this into a 'Metadata' module in the future.
    case Dropkick.Attachable.content(atch) do
      {:ok, content} ->
        {mimetype, width, height, variant} = ExImageInfo.info(content)

        %{
          mimetype: mimetype,
          dimension: "#{width}x#{height}",
          variant: variant
        }

      _ ->
        %{}
    end
  end

  # If we don't yet support extracting metadata from the content type we do nothing.
  # In the future this could be expanded to other formats as long as we have a proper lib in the ecosystem do do that.
  def extract_metadata(%Attachment{} = atch), do: atch

  @doc """
  Calls the underlyning storage's `put` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def put(attachable, opts \\ []),
    do: Dropkick.Storage.current().put(attachable, opts)

  @doc """
  Calls the underlyning storage's `read` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def read(attachable, opts \\ []),
    do: Dropkick.Storage.current().read(attachable, opts)

  @doc """
  Calls the underlyning storage's `copy` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def copy(attachable, dest, opts \\ []),
    do: Dropkick.Storage.current().copy(attachable, dest, opts)

  @doc """
  Calls the underlyning storage's `delete` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def delete(attachable, opts \\ []),
    do: Dropkick.Storage.current().delete(attachable, opts)

  defp transform_stream(atch, transforms) do
    Task.Supervisor.async_stream_nolink(Dropkick.TransformTaskSupervisor, transforms, fn
      {:thumbnail, size, params} ->
        with {:ok, transform} <- Dropkick.Transform.thumbnail(atch, size, params),
             {:ok, version} <- put(transform, folder: Path.dirname(transform.key)) do
          version
        end

      transform ->
        raise "Not a valid transform param #{inspect(transform)}"
    end)
  end
end

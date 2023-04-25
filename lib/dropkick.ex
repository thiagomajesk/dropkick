defmodule Dropkick do
  @moduledoc """
  This module provides functions that you can use to interact directly with uploads and attachments.
  """

  alias Dropkick.Attachment

  @doc """
  Caches an attachable by saving it on the provided directory under the "cache" prefix by default.
  When an attachable is cached we won't calculate any metadata information, the file is only
  saved to the directory. This function is usually usefull when you are doing async uploads -
  where you first save the file to a temporary location and only after some confirmation you actually move
  the file to its final destination. You probably want to clean this directory from time to time.
  """
  def cache(attachable, opts \\ []) do
    opts = Keyword.put(opts, :prefix, "cache")

    with {:ok, atch} <- put(attachable, opts) do
      {:ok, Map.replace!(atch, :status, :cached)}
    end
  end

  @doc """
  Stores an attachable by saving it on the provided directory under the "store" prefix by default.
  When an attachable is stored we'll calculate metadata information before moving the file to its destination.
  """
  def store(upload, opts \\ []) do
    opts = Keyword.put(opts, :prefix, "store")

    with {:ok, atch} <- put(upload, opts) do
      {:ok, Map.replace!(atch, :status, :stored)}
    end
  end

  @doc """
  Moves an attachble from its current destination to another one.
  This function can be used to "promote" cached attachments without having
  to worry about cleaning up the temporary directory.
  """
  def move(%Attachment{status: :cached} = atch, opts \\ []) do
    dest = Keyword.fetch!(opts, :dest)

    with {:ok, atch} <- copy(atch, dest, move: true) do
      {:ok, Map.replace!(atch, :status, :stored)}
    end
  end

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
    Enum.map(transforms, fn
      {:thumbnail, size, params} ->
        Task.Supervisor.async_nolink(Dropkick.TransformTaskSupervisor, fn ->
          with {:ok, transform} <- Dropkick.Transform.thumbnail(atch, size, params),
               {:ok, version} <- store(transform, folder: Path.dirname(transform.key)) do
            {:ok, Map.update!(atch, :versions, fn versions -> [version | versions] end)}
          end
        end)

      transform ->
        raise "Not a valid transform param #{inspect(transform)}"
    end)
  end

  def url(%Attachment{} = atch, opts \\ []) do
    version = Keyword.get(opts, :version)
    atch = (version && version(atch, version)) || atch
    Path.join(Keyword.get(opts, :host, "/"), atch.key)
  end

  def version(%Attachment{} = atch, version) do
    Enum.find(atch.versions, &(&1.version == version))
  end

  def contextualize(%Attachment{} = atch) do
    key = Dropkick.Attachable.key(atch)

    %{
      filename: Path.basename(key),
      extension: Path.extname(key),
      directory: Path.dirname(key)
    }
  end

  @doc """
  Calls the underlyning storage's `put` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def put(upload, opts \\ []), do: storage!().put(upload, opts)

  @doc """
  Calls the underlyning storage's `read` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def read(upload, opts \\ []), do: storage!().read(upload, opts)

  @doc """
  Calls the underlyning storage's `copy` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def copy(upload, dest, opts \\ []), do: storage!().copy(upload, dest, opts)

  @doc """
  Calls the underlyning storage's `delete` function.
  Check the module `Dropkick.Storage` for documentation about the available options.
  """
  def delete(upload, opts \\ []), do: storage!().delete(upload, opts)

  defp storage!(), do: Application.fetch_env!(:dropkick, :storage)
end

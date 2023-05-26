defmodule Dropkick.Transform do
  @moduledoc false
  defstruct [:key, :filename, :content]

  @supervisor Dropkick.TransformTaskSupervisor

  alias __MODULE__

  # def dispatch_transforms(%Dropkick.Ecto.File{} = upload, transforms, storage) do
  #   Task.Supervisor.async_stream_nolink(@supervisor, transforms, fn transform ->
  #     with {:ok, transformed} <- transform!(transform) do
  #       storage.store(transformed_upload)
  #     end
  #   end)
  # end

  # defp transform!(upload, {:thumbnail, size, params}) do
  #   with {:ok, transform} <- thumbnail(upload, size, params), do: transform
  # end

  # defp transform!(_upload, transform) do
  #   raise "Not a valid transform param #{inspect(transform)}"
  # end

  # defp thumbnail(atch, size, opts) do
  #   with {:ok, content} <- Dropkick.Uploadable.content(atch),
  #        {:ok, image} <- Image.from_binary(content),
  #        {:ok, thumbnail} <- Image.thumbnail(image, size, opts) do
  #     Vix.Vips.Image.write_to_binary(thumbnail)
  #   end
  # end
end

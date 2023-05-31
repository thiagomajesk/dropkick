defmodule Dropkick.Transform do
  @moduledoc false
  defstruct [:key, :filename, :content]

  @supervisor Dropkick.TransformTaskSupervisor

  # def dispatch_transforms(transforms, uploader, schema, field, file) do
  #   transforms
  #   |> transform_stream(uploader, schema, field, file)
  #   |> Stream.run()
  # end

  # defp transform_stream(transforms, uploader, schema, field, file) do
  #   Task.Supervisor.async_stream_nolink(@supervisor, transforms, fn transform ->
  #     with {storage, opts} <- uploader.storage(schema, field),
  #          {:ok, binary} <- storage.read(file) do
  #       folder = Keyword.fetch!(opts, :folder)
  #       transform!(binary, file.filename, folder, transform)
  #     end
  #   end)
  # end

  # defp transform!(binary, name, folder, {:thumbnail, opts}) do
  #   with {size, opts} <- Keyword.pop!(opts, :size),
  #        {suffix, opts} = Keyword.pop!(opts, :suffix),
  #        {:ok, image} <- Image.from_binary(binary),
  #        {:ok, thumbnail} <- Image.thumbnail(image, size, opts) do
  #     Vix.Vips.Image.write_to_file(thumbnail, Path.join([folder, suffix, name]))
  #   end
  # end

  # defp transform!(_binary, _name, _folder, transform) do
  #   raise "Not a valid transform param #{inspect(transform)}"
  # end
end

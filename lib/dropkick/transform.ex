defmodule Dropkick.Transform do
  @moduledoc false
  defstruct [:key, :filename, :content]

  alias __MODULE__

  def thumbnail(atch, size, opts) do
    with {:ok, content} <- Dropkick.Attachable.content(atch),
         {:ok, image} <- Image.from_binary(content),
         {:ok, image} <- Image.thumbnail(image, size, opts) do
      content = Vix.Vips.Image.write_to_binary(image)

      directory = Path.dirname(Dropkick.Attachable.key(atch))
      key = Path.join([directory, "thumbnail", size, atch.filename])

      {:ok,
       %Transform{
         content: content,
         filename: atch.filename,
         key: key
       }}
    end
  end
end

defmodule Dropkick.Uploader do
  @callback storage(struct(), atom()) :: {module(), Keyword.t()}

  @doc """
  Validates the given
  """
  @callback validation(struct(), atom(), Dropkick.Ecto.File.t()) ::
              {:ok, Dropkick.Ecto.File.t()} | {:error, String.t()}

  @doc """
  Transforms the file with the given options. The supported options are:

  ## `image/*`
  Image transformations uses the [`image`](https://hexdocs.pm/image) library behind the scenes

    - `{:thumbnail, size, opts}`: Generates an image thumbnail, receives the same options
    as [`Image.thumbnail/3`](https://hexdocs.pm/image/Image.html#thumbnail/3)
  """
  @callback transform(struct(), atom()) ::
              :noaction
              | {:blur, list()}
              | {:resize, float(), list()}
              | {:thumbnail, pos_integer() | String.t(), list()}

  def store(uploader, schema, field, file) do
    with {storage, opts} <- uploader.storage(schema, field),
         {:ok, file} <- uploader.validation(schema, field, file) do
      storage.store(file, opts)
    end
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Dropkick.Uploader

      def store(schema, field, file),
        do: Dropkick.Uploader.store(__MODULE__, schema, field, file)

      def validation(_schema, _field, file), do: {:ok, file}

      defoverridable validation: 3
    end
  end

  # def transform(%Dropkick.Ecto.File{} = upload, transforms) do
  #   upload
  #   |> transform_stream(transforms)
  #   |> Stream.filter(&match?({:ok, _}, &1))
  #   |> Enum.reduce(upload, fn {:ok, version}, upload ->
  #     Map.update!(upload, :versions, fn versions -> [version | versions] end)
  #   end)
  # end

  # defp list_transforms(schema, field) do
  #   schema
  #   |> __MODULE__.transform(field)
  #   |> List.wrap()
  #   |> List.flatten()
  #   |> Enum.reject(&(&1 == :noaction))
  # end

  # defp transform_stream(atch, transforms) do
  #   Task.Supervisor.async_stream_nolink(Dropkick.TransformTaskSupervisor, transforms, fn
  #     {:thumbnail, size, params} ->
  #       with {:ok, transform} <- Dropkick.Transform.thumbnail(atch, size, params),
  #            {:ok, version} <- put(transform, folder: Path.dirname(transform.key)) do
  #         version
  #       end

  #     transform ->
  #       raise "Not a valid transform param #{inspect(transform)}"
  #   end)
  # end
end

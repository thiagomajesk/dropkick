defmodule UploaderTest do
  use ExUnit.Case
  use Dropkick.FileCase

  describe "custom callbacks" do
    defmodule Profile do
      use Dropkick.Uploader

      def filename(%{filename: filename}), do: String.upcase(filename)

      def validate(%{content_type: "image/" <> _}, %{action: :cache}), do: :ok
      def validate(%{content_type: "image/" <> _}, %{action: :store}), do: {:error, "invalid"}
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "validate", %{dir: dir, path: path} do
      upload = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, %{}} = Profile.cache(upload, folder: dir)
      assert {:error, "invalid"} = Profile.store(upload, folder: dir)
    end
  end

  describe "default callbacks" do
    defmodule Avatar do
      use Dropkick.Uploader

      def validate(_, _), do: :ok
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "cache", %{dir: dir, path: path} do
      upload = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, %{key: key}} = Avatar.cache(upload, folder: dir)
      assert File.exists?(key)
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "store", %{dir: dir, path: path} do
      upload = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, %{key: key}} = Avatar.store(upload, folder: dir)
      assert File.exists?(key)
    end
  end
end

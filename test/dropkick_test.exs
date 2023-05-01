defmodule DropkickTest do
  use ExUnit.Case
  use Dropkick.FileCase

  alias Dropkick.Attachment

  describe "api" do
    @tag copy: "test/fixtures/images/puppies.jpg"
    test "cache", %{dir: dir, path: path} do
      atch = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, %{key: key, status: :cached}} = Dropkick.cache(atch, folder: dir)
      assert File.exists?(key)
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "store", %{dir: dir, path: path} do
      atch = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, %{key: key, status: :stored}} = Dropkick.store(atch, folder: dir)
      assert File.exists?(key)
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "promote", %{dir: dir, path: path} do
      atch = %Plug.Upload{
        path: path,
        filename: Path.basename(path),
        content_type: "image/jpg"
      }

      assert {:ok, atch} = Dropkick.cache(atch, folder: dir)

      assert {:ok, %{key: key, status: :stored}} =
               Dropkick.move(atch, dest: Path.join(dir, "cp.jpg"))

      assert File.exists?(key)
    end
  end

  describe "transforms" do
    @tag copy: "test/fixtures/images/puppies.jpg"
    test "thumbnail", %{path: path} do
      atch = %Attachment{
        key: path,
        filename: Path.basename(path),
        storage: Dropkick.Storage.Disk
      }

      transforms = [{:thumbnail, "50x50", [crop: :center]}]
      %Attachment{versions: [%{key: key}]} = Dropkick.transform(atch, transforms)
      assert File.exists?(key)
    end
  end
end

defmodule StorageTest do
  use ExUnit.Case, async: true
  use Dropkick.FileCase

  setup %{path: path} do
    {:ok,
     upload: %{
       path: path,
       filename: Path.basename(path),
       content_type: "image/jpg"
     }}
  end

  describe "disk storage" do
    test "store action", %{dir: dir, upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})

      assert {:ok, %Dropkick.File{key: key, status: :stored}} =
               Dropkick.Storage.Disk.store(file, folder: dir, prefix: "")

      assert File.exists?(key)
    end

    test "read action", %{dir: dir, upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Disk.store(file, folder: dir, prefix: "")

      assert {:ok, "Hello World"} = Dropkick.Storage.Disk.read(file)
    end

    test "copy action", %{dir: dir, upload: upload} do
      dest = Path.join([dir, "copied", "new.jpg"])

      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Disk.store(file, folder: dir, prefix: "")

      assert {:ok, %Dropkick.File{key: ^dest}} = Dropkick.Storage.Disk.copy(file, dest)

      assert File.exists?(dest)
    end

    test "delete action", %{dir: dir, upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Disk.store(file, folder: dir, prefix: "")

      assert {:ok, %Dropkick.File{key: key, status: :deleted}} =
               Dropkick.Storage.Disk.delete(file)

      refute File.exists?(key)
    end
  end

  describe "memory storage" do
    test "store action", %{upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})

      assert {:ok, %Dropkick.File{key: key, status: :stored}} =
               Dropkick.Storage.Memory.store(file)

      assert Process.alive?(Dropkick.Storage.Memory.decode_key(key))
    end

    test "read action", %{upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Memory.store(file)

      assert {:ok, "Hello World"} = Dropkick.Storage.Memory.read(file)
    end

    test "copy action", %{dir: dir, upload: upload} do
      dest = Path.join([dir, "copied", "new.jpg"])
      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Memory.store(file)

      assert {:ok, %Dropkick.File{key: key}} = Dropkick.Storage.Memory.copy(file, dest)
      assert Process.alive?(Dropkick.Storage.Memory.decode_key(key))
    end

    test "delete action", %{upload: upload} do
      {:ok, file} = Dropkick.File.cast(upload, %{})
      {:ok, file} = Dropkick.Storage.Memory.store(file)

      assert {:ok, %Dropkick.File{key: key, status: :deleted}} =
               Dropkick.Storage.Memory.delete(file)

      refute Process.alive?(Dropkick.Storage.Memory.decode_key(key))
    end
  end
end

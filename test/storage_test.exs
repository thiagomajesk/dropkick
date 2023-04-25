defmodule StorageTest do
  use ExUnit.Case, async: true
  use Dropkick.FileCase

  alias Dropkick.{Storage, Attachment}

  setup %{path: path} do
    {:ok,
     upload: %Plug.Upload{
       path: path,
       filename: Path.basename(path),
       content_type: "image/jpg"
     }}
  end

  describe "disk storage" do
    test "put action", %{dir: dir, upload: upload} do
      assert {:ok, %Attachment{key: key}} = Storage.Disk.put(upload, folder: dir)
      assert File.exists?(key)
    end

    test "read action", %{dir: dir, upload: upload} do
      assert {:ok, atch} = Storage.Disk.put(upload, folder: dir)
      assert {:ok, "Hello World"} = Storage.Disk.read(atch)
    end

    test "copy action", %{dir: dir, upload: upload} do
      copy_path = Path.join(dir, "new.jpg")
      assert {:ok, atch} = Storage.Disk.put(upload, folder: dir)
      assert {:ok, %Attachment{key: ^copy_path}} = Storage.Disk.copy(atch, copy_path)
      assert File.exists?(copy_path)
    end

    test "delete action", %{dir: dir, upload: upload} do
      assert {:ok, atch} = Storage.Disk.put(upload, folder: dir)
      assert :ok = Storage.Disk.delete(atch)
      refute File.exists?(atch.key)
    end
  end

  describe "memory storage" do
    test "put action", %{upload: upload} do
      assert {:ok, %Attachment{key: key}} = Storage.Memory.put(upload)
      assert Process.alive?(Storage.Memory.decode_key(key))
    end

    test "read action", %{upload: upload} do
      assert {:ok, atch} = Storage.Memory.put(upload)
      assert {:ok, "Hello World"} = Storage.Memory.read(atch)
    end

    test "copy action", %{dir: dir, upload: upload} do
      copy_path = Path.join(dir, "new.jpg")
      assert {:ok, atch} = Storage.Memory.put(upload)
      assert {:ok, %Attachment{key: key}} = Storage.Memory.copy(atch, copy_path)
      assert Process.alive?(Storage.Memory.decode_key(key))
    end

    test "delete action", %{upload: upload} do
      assert {:ok, atch} = Storage.Memory.put(upload)
      assert Process.alive?(Storage.Memory.decode_key(atch.key))
      assert :ok = Storage.Memory.delete(atch)
      refute Process.alive?(Storage.Memory.decode_key(atch.key))
    end
  end
end

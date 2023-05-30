defmodule RepoTest do
  use ExUnit.Case, async: true
  use Dropkick.FileCase

  defmodule TestUploader do
    use Dropkick.Uploader

    def storage(%TestUser{name: name}, :avatar) do
      {Dropkick.Storage.Disk, folder: "uploads/avatars/#{name}"}
    end

    def transform(%TestUser{name: name}, :avatar) do
      {:thumbnail,
       [
         suffix: "thumbnails",
         size: "250x250",
         crop: :center
       ]}
    end
  end

  setup %{path: path} do
    on_exit(fn -> File.rm_rf!("uploads") end)

    {:ok,
     upload: %{
       path: path,
       filename: Path.basename(path),
       content_type: "image/jpg"
     }}
  end

  test "insert_with_files", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:name, :avatar])

    assert {:ok, %TestUser{avatar: avatar}} = TestRepo.insert_with_files(changeset, TestUploader)
    assert File.exists?(avatar.key)
  end

  test "update_with_files", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo"}, [:name])
    {:ok, inserted_test_user} = TestRepo.insert_with_files(changeset, TestUploader)

    changeset = Ecto.Changeset.cast(inserted_test_user, %{avatar: upload}, [:avatar])

    assert {:ok, %TestUser{avatar: avatar}} = TestRepo.update_with_files(changeset, TestUploader)
    assert File.exists?(avatar.key)
  end

  test "delete_with_files", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:name, :avatar])
    {:ok, inserted_test_user} = TestRepo.insert_with_files(changeset, TestUploader)

    changeset = Ecto.Changeset.cast(inserted_test_user, %{avatar: upload}, [:avatar])

    assert {:ok, %TestUser{avatar: avatar}} = TestRepo.delete_with_files(changeset, TestUploader)
    refute File.exists?(avatar.key)
  end
end

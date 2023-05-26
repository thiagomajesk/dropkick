defmodule ChangesetTest do
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

  @tag filename: "foo.png"
  test "validate_upload_extension/2", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:avatar])

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Ecto.Changeset.validate_upload_extension(changeset, :avatar, ~w(.png))

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Ecto.Changeset.validate_upload_extension(changeset, :avatar, ~w(.gif))
  end

  @tag filename: "foo.gif"
  test "validate_upload_size/2", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:avatar])

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, is: 11)

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, min: 11)

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, max: 11)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, is: 10)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, min: 12)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Ecto.Changeset.validate_upload_size(changeset, :avatar, max: 10)
  end
end

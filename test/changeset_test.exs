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
  test "unsafe_validate_file_extension/2", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:avatar])

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Changeset.unsafe_validate_file_extension(
               changeset,
               :avatar,
               ~w(.png)
             )

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Changeset.unsafe_validate_file_extension(
               changeset,
               :avatar,
               ~w(.gif)
             )
  end

  @tag filename: "foo.png"
  test "unsafe_validate_file_type/2", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:avatar])

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Changeset.unsafe_validate_file_type(
               changeset,
               :avatar,
               ~w(image/jpg)
             )

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Changeset.unsafe_validate_file_type(
               changeset,
               :avatar,
               ~w(image/gif)
             )
  end

  @tag filename: "foo.gif"
  test "unsafe_validate_file_size/2", %{upload: upload} do
    changeset = Ecto.Changeset.cast(%TestUser{}, %{name: "foo", avatar: upload}, [:avatar])

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, is: 11)

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, min: 11)

    assert %Ecto.Changeset{valid?: true} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, max: 11)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, is: 10)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, min: 12)

    assert %Ecto.Changeset{valid?: false} =
             Dropkick.Changeset.unsafe_validate_file_size(changeset, :avatar, max: 10)
  end
end

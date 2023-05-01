defmodule DropkickTest do
  use ExUnit.Case
  use Dropkick.FileCase

  alias Dropkick.Attachment

  describe "transforms" do
    @tag copy: "test/fixtures/images/puppies.jpg"
    test "thumbnail", %{path: path} do
      atch = %Attachment{
        key: path,
        filename: Path.basename(path),
        content_type: "image/jpg",
        storage: Dropkick.Storage.Disk
      }

      transforms = [{:thumbnail, "50x50", [crop: :center]}]
      %Attachment{versions: [%{key: key}]} = Dropkick.transform(atch, transforms)
      assert File.exists?(key)
    end

    @tag copy: "test/fixtures/images/puppies.jpg"
    test "version is also a valid attachment", %{path: path} do
      atch = %Attachment{
        key: path,
        filename: Path.basename(path),
        content_type: "image/jpg",
        storage: Dropkick.Storage.Disk
      }

      transforms = [{:thumbnail, "50x50", [crop: :center]}]
      %Attachment{versions: [version]} = Dropkick.transform(atch, transforms)

      assert %Attachment{
               key: key,
               storage: Dropkick.Storage.Disk,
               filename: "puppies.jpg",
               content_type: "image/jpeg"
             } = version

      assert File.exists?(key)
    end
  end
end

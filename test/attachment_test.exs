defmodule AttachmentTest do
  use ExUnit.Case
  use Dropkick.FileCase

  alias Dropkick.Attachment

  test "cast attachment" do
    atch = %Attachment{key: "/", filename: "", content_type: "", storage: ""}
    assert {:ok, %Attachment{}} = Attachment.cast(atch)
  end

  test "cast map" do
    atch = %{key: "/", filename: "", content_type: "", storage: ""}
    assert {:ok, %Attachment{}} = Attachment.cast(atch)
  end

  test "encrypted token" do
    atch = %Attachment{key: "/foo.jpg", filename: "", content_type: "", storage: ""}
    token = Dropkick.Security.sign(atch)
    assert {:ok, %{key: "/foo.jpg"}} = Attachment.cast(token)
  end

  test "load map" do
    atch = %{
      "key" => "/",
      "filename" => "",
      "content_type" => "",
      "storage" => "Dropkick.Storage.Memory"
    }

    assert {:ok, %Attachment{}} = Attachment.load(atch)
  end

  test "dump attachment" do
    atch = %Attachment{key: "/", filename: "", content_type: "", storage: ""}
    assert {:ok, %{key: "/", filename: "", content_type: "", storage: ""}} = Attachment.dump(atch)
  end

  test "dump map" do
    atch = %{key: "/", filename: "", content_type: "", storage: ""}
    assert {:ok, %{key: "/", filename: "", content_type: "", storage: ""}} = Attachment.dump(atch)
  end
end

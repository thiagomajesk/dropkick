defmodule FileTest do
  use ExUnit.Case
  use Dropkick.FileCase

  test "cast upload" do
    upload = %Dropkick.Ecto.File{
      key: "/",
      filename: "",
      content_type: "",
      status: :cached
    }

    assert {:ok, %Dropkick.Ecto.File{}} = Dropkick.Ecto.File.cast(upload)
  end

  test "cast upload map" do
    upload = %{
      filename: "",
      path: "/",
      content_type: ""
    }

    assert {:ok, %Dropkick.Ecto.File{}} = Dropkick.Ecto.File.cast(upload)
  end

  test "load map" do
    upload = %{
      "key" => "/",
      "filename" => "",
      "content_type" => "",
      "status" => "stored"
    }

    assert {:ok, %Dropkick.Ecto.File{}} = Dropkick.Ecto.File.load(upload)
  end

  test "dump file" do
    upload = %Dropkick.Ecto.File{
      key: "/",
      filename: "",
      content_type: "",
      status: :cached
    }

    assert {:ok, %{key: "/", filename: "", content_type: "", status: :cached}} =
             Dropkick.Ecto.File.dump(upload)
  end

  test "dump map" do
    upload = %{key: "/", filename: "", content_type: "", status: :cached}

    assert {:ok, %{key: "/", filename: "", content_type: "", status: :cached}} =
             Dropkick.Ecto.File.dump(upload)
  end
end

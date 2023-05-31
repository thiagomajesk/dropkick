defmodule FileTest do
  use ExUnit.Case
  use Dropkick.FileCase

  test "cast file" do
    assert {:ok,
            %Dropkick.File{
              key: "/",
              filename: "",
              content_type: "",
              status: :cached
            }} =
             Dropkick.File.cast(%Dropkick.File{
               key: "/",
               filename: "",
               content_type: "",
               status: :cached
             })
  end

  test "cast map" do
    assert {:ok,
            %Dropkick.File{
              key: "/",
              filename: "",
              content_type: ""
            }} =
             Dropkick.File.cast(%{
               filename: "",
               path: "/",
               content_type: ""
             })
  end

  @tag copy: "test/fixtures/images/puppies.jpg"
  test "infer file", %{path: path} do
    assert {:ok,
            %Dropkick.File{
              filename: "puppies.jpg",
              content_type: "image/jpeg"
            }} =
             Dropkick.File.cast(
               %{
                 path: path,
                 filename: Path.basename(path),
                 content_type: "image/jpg"
               },
               %{infer: true}
             )

    assert {:ok,
            %Dropkick.File{
              filename: "puppies.jpg",
              content_type: "image/jpeg"
            }} =
             Dropkick.File.cast(
               %{
                 path: path,
                 filename: "puppies.gif",
                 content_type: "image/gif"
               },
               %{infer: true}
             )
  end

  test "load map" do
    assert {:ok,
            %Dropkick.File{
              key: "/",
              filename: "",
              content_type: "",
              status: :stored
            }} =
             Dropkick.File.load(%{
               "key" => "/",
               "filename" => "",
               "content_type" => "",
               "status" => "stored"
             })
  end

  test "dump file" do
    assert {:ok,
            %{
              key: "/",
              filename: "",
              content_type: "",
              status: :cached
            }} =
             Dropkick.File.dump(%Dropkick.File{
               key: "/",
               filename: "",
               content_type: "",
               status: :cached
             })
  end

  test "dump map" do
    assert {:ok,
            %{
              key: "/",
              filename: "",
              content_type: "",
              status: :cached
            }} =
             Dropkick.File.dump(%{
               key: "/",
               filename: "",
               content_type: "",
               status: :cached
             })
  end
end

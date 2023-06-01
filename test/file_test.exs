defmodule FileTest do
  use ExUnit.Case
  use Dropkick.FileCase

  test "cast file", %{path: path} do
    file = %Dropkick.File{
      key: path,
      filename: Path.basename(path),
      content_type: "image/jpg",
      status: :cached
    }

    assert {:ok, ^file} = Dropkick.File.cast(file)
  end

  test "cast map", %{path: path} do
    name = Path.basename(path)

    map = %{
      path: path,
      filename: name,
      content_type: "image/jpg"
    }

    assert {:ok,
            %Dropkick.File{
              key: ^path,
              filename: ^name,
              content_type: "image/jpg",
              status: :cached
            }} = Dropkick.File.cast(map)
  end

  test "load map", %{path: path} do
    name = Path.basename(path)

    map = %{
      "key" => path,
      "filename" => name,
      "content_type" => "image/jpg",
      "status" => "stored"
    }

    assert {:ok,
            %Dropkick.File{
              key: ^path,
              filename: ^name,
              content_type: "image/jpg",
              status: :stored
            }} = Dropkick.File.load(map)
  end

  test "dump file", %{path: path} do
    name = Path.basename(path)

    file = %Dropkick.File{
      key: path,
      filename: name,
      content_type: "image/jpg",
      status: :stored
    }

    assert {:ok,
            %{
              key: ^path,
              filename: ^name,
              content_type: "image/jpg",
              status: :stored
            }} = Dropkick.File.dump(file)
  end

  test "dump map", %{path: path} do
    name = Path.basename(path)

    map = %{
      key: path,
      filename: name,
      content_type: "image/jpg",
      status: :stored
    }

    assert {:ok,
            %{
              key: ^path,
              filename: ^name,
              content_type: "image/jpg",
              status: :stored
            }} = Dropkick.File.dump(map)
  end

  @tag copy: "test/fixtures/images/puppies.jpg"
  test "infer file with correct info", %{path: path} do
    name = Path.basename(path)

    map = %{
      path: path,
      filename: name,
      content_type: "image/jpeg"
    }

    assert {:ok,
            %Dropkick.File{
              key: ^path,
              filename: ^name,
              content_type: "image/jpeg",
              status: :cached
            }} = Dropkick.File.cast(map, %{infer: true})
  end

  @tag copy: "test/fixtures/images/puppies.jpg"
  test "infer file with wrong info", %{path: path} do
    name = Path.basename(path)

    map = %{
      path: path,
      filename: "puppies.gif",
      content_type: "image/gif"
    }

    assert {:ok,
            %Dropkick.File{
              key: ^path,
              filename: ^name,
              content_type: "image/jpeg",
              status: :cached
            }} = Dropkick.File.cast(map, %{infer: true})
  end
end

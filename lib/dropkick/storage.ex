defmodule Dropkick.Storage do
  @callback store(Dropkick.File.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}

  @callback read(Dropkick.File.t(), Keyword.t()) ::
              {:ok, binary()} | {:error, String.t()}

  @callback copy(Dropkick.File.t(), String.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}

  @callback delete(Dropkick.File.t(), Keyword.t()) ::
              {:ok, Dropkick.File.t()} | {:error, String.t()}
end

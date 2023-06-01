defmodule Dropkick.Task do
  @doc """
  Runs a function asynchronously on a success result tuple `{:ok, result}`.
  Whatever was passed as the first argument is returned imediately and for
  successfull results, `fun` runs with the success value from the tuple.
  """
  def after_success(result_tuple, fun) do
    with {:ok, result} <- result_tuple,
         :ok <- dispatch_task(fn -> fun.(result) end),
         do: {:ok, result}
  end

  defp dispatch_task(fun) do
    sup = Dropkick.TransformTaskSupervisor
    Task.Supervisor.async_nolink(sup, fun) && :ok
  end
end

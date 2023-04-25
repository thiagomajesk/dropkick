defmodule Dropkick.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Dropkick.TransformTaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Dropkick.Supervisor)
  end
end

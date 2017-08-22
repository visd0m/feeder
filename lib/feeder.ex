defmodule Feeder do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("starting feeder 🤖")

    children = [
      worker(Feeder.Scheduler, []),
      worker(Feeder.Fetcher, [])
    ]
    opts = [strategy: :one_for_one, name: Feeder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_type) do
    Logger.info("stopping feeder ☠️")

    Supervisor.stop(Feeder.Supervisor)
  end
end

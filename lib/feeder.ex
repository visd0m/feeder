defmodule Feeder do
  use Application
  require Logger
  alias :mnesia, as: Mnesia

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("starting feeder 🤖")

    Mnesia.start()
    children = [
      worker(Feeder.Scheduler, []),
      worker(Feeder.Telegram.Fetcher, [])
    ]
    opts = [strategy: :one_for_one, name: Feeder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_type) do
    Logger.info("stopping feeder ☠️")

    Mnesia.stop()
    Supervisor.stop(Feeder.Supervisor)
  end
end

defmodule FeederBot do
  import FeederBot.Persistence.DatabaseHandler
  use FeederBot.Persistence.Database
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("starting feeder 🤖")

    children = [
      worker(FeederBot.Scheduler, []),
      worker(FeederBot.Telegram.Bot, []),
      worker(FeederBot.Rss.Fetcher, [])
    ]
    opts = [strategy: :one_for_one, name: FeederBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_type) do
    Logger.info("stopping feeder ☠️")

    Supervisor.stop(FeederBot.Supervisor)
  end

  def list_subscription() do
    exec_operation(fn() ->
      Subscription.where(id > 0)
        |> Amnesia.Selection.values
    end)
  end
end

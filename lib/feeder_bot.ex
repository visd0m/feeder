defmodule FeederBot do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info("starting feeder 🤖")

    children = [
      worker(FeederBot.Telegram.Fetcher, []),
      worker(FeederBot.Scheduler, []),
      worker(FeederBot.Rss.Cache, []),
      worker(FeederBot.Repo, []),
      {Task.Supervisor, name: FeederBot.TaskSupervisor}
    ]
    opts = [strategy: :one_for_one, name: FeederBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_type) do
    Logger.info("stopping feeder ☠️")

    Supervisor.stop(FeederBot.Supervisor)
  end
end

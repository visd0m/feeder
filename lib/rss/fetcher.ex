defmodule Feeder.Rss.Fetcher do
  use GenServer
  use Feeder.Persistence.Database
  require Logger
  import Feeder.Persistence.DatabaseHandler

  def load_subscriptions do
    subscriptions = exec_operation(fn ->
      Subscription.where(:id > 1)
        |> Amnesia.Selection.values
    end)
    Logger.info("actual subscriptions: #{inspect(subscriptions)}")
  end
end

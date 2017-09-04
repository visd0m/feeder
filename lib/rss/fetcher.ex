defmodule FeederBot.Rss.Fetcher do
  use GenServer
  use FeederBot.Persistence.Database
  require Logger
  import FeederBot.Persistence.SubscriptionDao
  import FeederBot.Telegram.Bot
  import FeederBot.Date

  # ======== public
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch_subscription(subscription) do
    GenServer.cast(__MODULE__, {:fetch, subscription})
  end

  def load_subscriptions do
    subscriptions = load_enabled()

    subscriptions
      |> Enum.each(fn(subscription) -> fetch_subscription(subscription) end)
  end

  # ======== callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:fetch, subscription}, _) do
    feed = extract_feed(subscription)
    send_updates({subscription, feed})
    update_subscription({subscription, feed})

    {:noreply, nil}
  end

  # ======== private
  defp extract_feed(subscription) do
    case HTTPoison.get(subscription.url) do
      {:ok, response} ->
        ElixirFeedParser.parse(response.body).entries
        |> Enum.filter(fn(feed) ->
           {:ok, feed_date} = extract_timestamp(feed.updated)
           subscription.last_update < feed_date
         end)
      {:error, _} ->
        []
    end
  end

  defp send_updates({subscription, feed_entries}) do
    feed_entries
      |> Enum.each(fn(entry) -> send({
          subscription.chat_id,
          "#{subscription.tag}\n\n#{entry.title}\n\n#{entry.url}"
        })
      end)
  end

  defp update_subscription({subscription, feed_entries}) do
    case feed_entries do
      [_ | _] ->
        {:ok, feed_date} = extract_timestamp(List.first(feed_entries).updated)
        update(%Subscription{subscription | last_update: feed_date})
        :ok
        _ -> :ok
    end
  end
end

defmodule FeederBot.Rss.Fetcher do
  use FeederBot.Persistence.Database
  require Logger
  import FeederBot.Persistence.SubscriptionDao
  import FeederBot.Telegram
  import FeederBot.Date
  import FeederBot.Rss.Cache
  import FeederBot.Rss

  # ======== public
  def load_subscriptions do
    subscriptions = load_enabled()

    subscriptions
      |> Enum.each(fn(subscription) ->
        Task.Supervisor.async_nolink(FeederBot.TaskSupervisor, fn ->
          fetch_subscription(subscription)
        end)
      end)
  end

  def extract_feed(subscription, filter_fn) do
    extract_feed(subscription) |> Enum.filter(fn(feed) -> filter_fn.(feed) end)
  end

  def extract_feed(subscription) do
    with feed = [_|_] <- try_cache(subscription)
    do
      feed
    else
      [] -> fetch_remotely(subscription)
    end
  end

  # ======== private
  defp fetch_remotely(subscription) do
    case HTTPoison.get(subscription.url) do
      {:ok, response} ->
        with {:ok, feed, _} <- FeederEx.parse(response.body)
        do
          put({subscription.url, feed.entries})
          feed.entries
        else
          _ -> []
        end
      {:error, _} ->
        []
    end
  end

  defp try_cache(subscription) do
    get(subscription.url)
  end

  defp fetch_subscription(subscription) do
    feed = extract_feed(
      subscription,
      fn(feed) ->
        {:ok, feed_date} = extract_timestamp(feed.updated)
        subscription.last_update < feed_date
      end
    )
    send_updates({subscription, feed})
    update_subscription({subscription, feed})
  end

  defp send_updates({subscription, feed_entries}) do
    feed_entries
      |> Enum.each(fn(entry) -> send_message({
          subscription.chat_id,
          "#{subscription.tag}\n\n#{entry.title}\n\n#{entry.link}"
        })
      end)
  end

  defp update_subscription({subscription, feed_entries}) do
    case feed_entries do
      [_ | _] ->
        last_update = extract_max_timestamp(feed_entries)
        update(%Subscription{subscription | last_update: last_update})
        :ok
        _ -> :ok
    end
  end
end

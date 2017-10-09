defmodule FeederBot.Rss.Fetcher do
  require Logger
  import FeederBot.Persistence.SubscriptionDao
  import FeederBot.Telegram
  import FeederBot.Date
  import FeederBot.Rss.Cache
  import FeederBot.Rss
  alias FeederBot.Persistence.Subscription, as: Subscription

  # ======== public
  def load_subscriptions do
    subscriptions = load_enabled

    subscriptions
    |> Enum.each(
         fn (subscription) ->
           Task.Supervisor.async_nolink(
             FeederBot.TaskSupervisor,
             fn ->
               fetch_subscription(subscription)
             end
           )
         end
       )
  end

  def extract_feed(subscription, filter_fn) do
    extract_feed(subscription)
    |> Enum.filter(fn (feed) -> filter_fn.(feed) end)
  end

  def extract_feed(subscription) do
    with feed = [_ | _] <- try_cache(subscription)
      do
      feed
    else
      [] -> fetch_remotely(subscription.url)
    end
  end

  # ======== private
  def fetch_remotely(url) do
    entries = fetch(url)
    put({url, entries})
    entries
  end

  defp try_cache(subscription) do
    get(subscription.url)
  end

  defp fetch_subscription(subscription) do
    feed = extract_feed(
      subscription,
      fn (feed) ->
        {:ok, feed_date} = extract_timestamp(feed.updated)
        subscription.last_update < feed_date
      end
    )
    send_updates({subscription, feed})
    update_subscription({subscription, feed})
  end

  defp send_updates({subscription, feed_entries}) do
    feed_entries
    |> Enum.each(
         fn (entry) ->
           send_message(
             {
               subscription.chat_id,
               "[#{subscription.tag}]\n\n#{entry.title}\n\n#{entry.link}"
             }
           )
         end
       )
  end

  defp update_subscription({subscription, feed_entries}) do
    case feed_entries do
      [_ | _] ->
        last_update = extract_max_timestamp(feed_entries)
        update(subscription, %Subscription{subscription | last_update: last_update})
        :ok
      _ -> :ok
    end
  end
end

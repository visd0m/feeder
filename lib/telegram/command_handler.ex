defmodule FeederBot.Telegram.CommandHandler do
  require Logger
  import FeederBot.Rss
  import FeederBot.Persistence.SubscriptionDao
  use FeederBot.Persistence.Database

  def handle_command(command) do
    parsed_command = {
      command["message"]["text"],
      command["message"]["from"]["id"],
      command["message"]["chat"]["id"]
    }

    fn -> get_handler(parsed_command) end
  end

  # ======== subscribe
  defp get_handler({"/subscribe " <> url, user_id, chat_id}) do
    random_tag = :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)
    with false <- is_already_subscribed(url, user_id)
    do
      try_subscribe(url, random_tag, user_id, chat_id)
    else
      _ -> {:error, {chat_id, "already subscribed to url: '#{url}'"}}
    end
  end

  defp is_already_subscribed(url, user_id) do
    with [] <- load_enabled_by_user_id_and_url(user_id, url)
    do
      false
    else
      _ -> true
    end
  end

  defp try_subscribe(url, tag, user_id, chat_id) do
    with {:ok, timestamp} <- check_subscription(url)
    do
      on_valid_subscription(url, tag, user_id, chat_id, timestamp)
      {:ok, {chat_id, "subscription confirmed to: #{url} ✌️ with tag: #{tag}"}}
    else
      _ -> {:error, {chat_id, "😱 invalid url provided, #{url}"}}
    end
  end

  defp on_valid_subscription(url, tag, user_id, chat_id, timestamp) do
    insert(
      %Subscription{
        user_id: user_id,
        chat_id: chat_id,
        url: url,
        tag: tag,
        enabled: true,
        last_update: timestamp
      }
    )
  end

  # ======== unsubscribe
  defp get_handler({"/unsubscribe " <> url, user_id, chat_id}) do
    load_enabled_by_user_id_and_url(user_id, url)
      |> Enum.each(fn(subscription) ->
        update(%Subscription{subscription | enabled: false})
      end)

    {:ok, {chat_id, "correctly unsubscribed from, '#{url}'"}}
  end

  # ======== list
  defp get_handler({"/list", user_id, chat_id}) do
    subscriptions = load_enabled_by_user_id(user_id)

    urls = subscriptions
      |> Enum.map(fn(subscription) -> "#{subscription.url} with tag: #{subscription.tag}" end)
      |> Enum.join("\n")

    {:ok, {chat_id, "enabled subscriptions:\n#{urls}"}}
  end

  # ======== start
  defp get_handler({"/start" <> _, _, chat_id}) do
    {:ok, {chat_id, "Welcome to the best feed bot ever made 👾\ntype /help to get the list of available commands"}}
  end

  # ======== stop
  defp get_handler({"/stop" <> _, user_id, chat_id}) do
    subscriptions = load_enabled_by_user_id(user_id)

    subscriptions
      |> Enum.each(fn(subscription) ->
        update(%Subscription{subscription | enabled: false})
      end)

    {:ok, {chat_id, "I've always hated goodbyes 😩"}}
  end

  # ======== help
  defp get_handler({"/help" <> _, _, chat_id}) do
    {:ok, {chat_id, "available commands:\n/subscribe <url>\n/unsubscribe <url>\n/list\n"}}
  end

  # ======== unknwon
  defp get_handler({_, _, chat_id}) do
    {:ok, {chat_id, "unknown command .."}}
  end
end

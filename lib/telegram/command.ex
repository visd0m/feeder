defmodule FeederBot.Telegram.Command do
  require Logger
  use FeederBot.Persistence.Database
  import FeederBot.Rss
  import FeederBot.Rss.Fetcher
  import FeederBot.Persistence.SubscriptionDao

  def get_command_handler(command) do
    parsed_command = {
      command["message"]["text"],
      command["message"]["from"]["id"],
      command["message"]["chat"]["id"]
    }

    fn -> get_handler(parsed_command) end
  end

  def is_command(message_wrapper) do
    case text = message_wrapper["message"]["text"] do
      nil ->
        false
      _ ->
        String.starts_with?(text, "/")
    end
  end

  # ======== subscribe (http://an_url.com tag)
  defp get_handler({"/subscribe " <> subscription, user_id, chat_id}) do
    tokens = String.split(subscription, " ")

    url = List.first(tokens)
    tag = case tokens do
      [_, user_tag] ->
        user_tag
      _ ->
        :crypto.strong_rand_bytes(10)
        |> Base.url_encode64
        |> binary_part(0, 10)
    end

    with false <- is_already_subscribed(url, user_id)
      do
      try_subscribe(url, tag, user_id, chat_id)
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
    with timestamp <- get_subscription_timestamp(url)
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
    |> Enum.each(
         fn (subscription) ->
           update(%Subscription{subscription | enabled: false})
         end
       )

    {:ok, {chat_id, "correctly unsubscribed from, '#{url}'"}}
  end

  # ======== contains
  defp get_handler({"/contains " <> q, user_id, chat_id}) do
    message = load_enabled_by_user_id(user_id)
              |> load_by_query(q)

    {:ok, {chat_id, "q: #{q}\n###\n#{message}\n###"}}
  end

  defp get_handler({"/tag_contains " <> args, user_id, chat_id}) do
    tokens = String.split(args, " ")
    case tokens do
      [tag, q] ->
        message = load_enabled_by_user_and_tag(user_id, tag)
                  |> load_by_query(q)
        {:ok, {chat_id, "q: #{q} on tag: #{tag}\n###\n#{message}\n###"}}
      _ ->
        {:ok, {chat_id, "tag_contains invalid arguments"}}
    end


  end

  defp load_by_query(subscriptions, q) do
    subscriptions
    |> Enum.flat_map(
         fn (subscription) ->
           extract_feed(
             subscription,
             fn (feed) ->
               String.contains?(String.downcase(feed.title), String.downcase(q)) or
               String.contains?(String.downcase(feed.summary), String.downcase(q))
             end
           )
         end
       )
    |> format_result
  end

  defp format_result(entries) do
    entries
    |> Enum.map(fn (item) -> "#{item.title}\n#{item.link}" end)
    |> Enum.take(10)
    |> Enum.join("\n\n")
  end

  # ======== list
  defp get_handler({"/list", user_id, chat_id}) do
    subscriptions = load_enabled_by_user_id(user_id)

    urls = subscriptions
           |> Enum.map(fn (subscription) -> "#{subscription.url} with tag: #{subscription.tag}" end)
           |> Enum.join("\n")

    {:ok, {chat_id, "enabled subscriptions:\n#{urls}"}}
  end

  # ======== list
  defp get_handler({"/list_k", user_id, chat_id}) do
    subscriptions = load_enabled_by_user_id(user_id)

    buttons = subscriptions
              |> Enum.map(fn (subscription) -> ["/recent #{subscription.tag}"] end)

    {
      :ok,
      {
        chat_id,
        "enabled subscriptions:",
        Poison.encode!(%FeederBot.Telegram.Keyboard{keyboard: buttons})
      }
    }
  end

  # ======== recent
  defp get_handler({"/recent " <> tag, user_id, chat_id}) do
    message = load_enabled_by_user_and_tag(user_id, tag)
              |> Enum.flat_map(fn (subscription) -> extract_feed(subscription)  end)
              |> format_result
    {:ok, {chat_id, "###\n#{message}\n###"}}
  end

  # ======== start
  defp get_handler({"/start" <> _, _, chat_id}) do
    {:ok, {chat_id, "Welcome to the best feed bot ever made 👾\ntype /help to get the list of available commands"}}
  end

  # ======== stop
  defp get_handler({"/stop" <> _, user_id, chat_id}) do
    subscriptions = load_enabled_by_user_id(user_id)

    subscriptions
    |> Enum.each(
         fn (subscription) ->
           update(%Subscription{subscription | enabled: false})
         end
       )

    {:ok, {chat_id, "Farewell 😩"}}
  end

  # ======== help
  defp get_handler({"/help" <> _, _, chat_id}) do
    {:ok, {chat_id, "available commands:\n/subscribe <url>\n/unsubscribe <url>\n/list\n"}}
  end

  # ======== retag
  defp get_handler({"/retag " <> args, user_id, chat_id}) do
    tokens = String.split(args, " ")
    case tokens do
      [url, new_tag] ->
        load_enabled_by_user_id_and_url(user_id, url)
        |> Enum.each(fn (subscription) -> update(%Subscription{subscription | tag: new_tag}) end)
        {:ok, {chat_id, "retagged"}}
      _ ->
        {:ok, {chat_id, "retag invalid arguments"}}
    end
  end

  # ======== unknwon
  defp get_handler({_, _, chat_id}) do
    {:ok, {chat_id, "unknown command .."}}
  end
end

defmodule Feeder.Telegram.TelegramService do
  require Logger
  @base_url "https://api.telegram.org"

  # ==> get_updates
  @get_updates_path "getUpdates"
  @offset_query_param "offset"

  # ==> send_message
  @send_message_path "sendMessage"
  @chat_id_query_param "chat_id"
  @text_query_param "text"
  @bot_id File.read!(Application.get_env(:feeder, :token_file))

  # ==> fetch messages
  def fetch_messages(last_id) do
    Logger.info("fetching messages ...")

    options = case get_offset(last_id) do
      nil ->
        []
      offset ->
        [{@offset_query_param, offset}]
    end

    Logger.info("REQ ==> #{@base_url}/#{@bot_id}/#{@get_updates_path}")
    message_beans = HTTPoison.get!(
      "#{@base_url}/#{@bot_id}/#{@get_updates_path}",
      [],
      [{:params, options}]
    ).body
      |> Poison.decode!()
      |> Map.get("result")

    Logger.info("fetched messages: #{inspect(message_beans)}")
    message_beans
  end

  defp get_offset(nil) do
    nil
  end

  defp get_offset(last_id) do
    last_id + 1
  end

  # ==> send message
  def send_message({chat_id, text}) do
    options = [
      {@chat_id_query_param, chat_id},
      {@text_query_param, text}
    ]

    message = HTTPoison.get!(
      "#{@base_url}/#{@bot_id}/#{@send_message_path}",
      [],
      [{:params, options}]
    ).body
      |> Poison.decode!()

    Logger.info("#{inspect(message)}")
  end
end

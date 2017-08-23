defmodule Feeder.Telegram.TelegramService do
  require Logger

  @base_url "https://api.telegram.org"
  @bot_id File.read!(Application.get_env(:feeder, :token_file))

  # get_updates
  @get_updates_path "getUpdates"
  @offset_query_param "offset"

  # send_message
  @send_message_path "sendMessage"
  @chat_id_query_param "chat_id"
  @text_query_param "text"

  # fetch messages
  @spec fetch_messages(String.t) :: Feeder.Telegram.Model.MessageWrapper
  def fetch_messages(last_id) do
    url = "#{@base_url}/#{@bot_id}/#{@get_updates_path}"

    options = case last_id do
      nil ->
        []
      offset ->
        [{@offset_query_param, offset + 1}]
    end

    Poison.decode!(
      exec_req(url, fn() -> HTTPoison.get!(url, [], [{:params, options}]) end)
    )["result"]
  end

  # send message
  def send_message({chat_id, text}) do
    url = "#{@base_url}/#{@bot_id}/#{@send_message_path}"

    options = [
      {@chat_id_query_param, chat_id},
      {@text_query_param, text}
    ]

    Poison.decode!(exec_req(url, fn() -> HTTPoison.get!(url, [], [{:params, options}]) end))
  end

  defp exec_req(url, req) do
    Logger.info("[REQ] ==> #{url}")
    body = req.().body
    Logger.info("[RES] <== #{body}")
    body
  end
end

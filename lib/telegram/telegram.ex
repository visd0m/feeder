defmodule FeederBot.Telegram do
  require Logger

  @base_url "https://api.telegram.org"
  @bot_id Application.get_env(:feeder_bot, :telegram_token)

  # get_updates
  @get_updates_path "getUpdates"
  @offset_query_param "offset"
  @tiemout_query_param "timeout"

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
        [
          {@tiemout_query_param, 20},
          {@offset_query_param, offset + 1}
        ]
    end

    Logger.info("[REQ] ==> #{url}")
    case HTTPoison.get(url, [], [{:params, options}, {:recv_timeout, 25000}]) do
      {:ok, response} ->
        body = response.body
        Logger.info("[RES] ==> #{body}")
        Poison.decode!(body)["result"]
      {:error, _} ->
        []
    end
  end

  # send message
  def send_message({chat_id, text}) do
    url = "#{@base_url}/#{@bot_id}/#{@send_message_path}"

    options = [
      {@chat_id_query_param, chat_id},
      {@text_query_param, text}
    ]

    Logger.info("[REQ] ==> #{url}")
    case HTTPoison.get(url, [], [{:params, options}]) do
      {:ok, response} ->
        body = response.body
        Logger.info("[RES] ==> #{body}")
        Poison.decode!(body)["result"]
      {:error, _} ->
        []
    end
  end
end

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
  @disable_preview_query_param "disable_web_page_preview"
  @text_query_param "text"

  # fetch messages
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

    get(url, options, 25000)
  end

  # send message
  def send_message({chat_id, text}) do
    url = "#{@base_url}/#{@bot_id}/#{@send_message_path}"

    options = [
      {@chat_id_query_param, chat_id},
      {@text_query_param, text},
      {@disable_preview_query_param, true}
    ]

    get(url, options)
  end

  defp get(url, query_params, time_out \\ nil) do
    case get_request(url, query_params, time_out).() do
      {:ok, response} ->
        body = response.body
        Logger.info("[RES] ==> #{body}")
        Poison.decode!(body)["result"]
      {:error, _} ->
        []
    end
  end

  defp get_request(url, query_params, nil) do
    fn ->
      Logger.info("[REQ] ==> #{url}")
      HTTPoison.get(url, [], [{:params, query_params}])
    end
  end

  defp get_request(url, query_params, timeout) do
    fn ->
      Logger.info("[REQ] ==> #{url}")
      HTTPoison.get(url, [], [{:params, query_params}, {:recv_timeout, timeout}])
    end
  end
end

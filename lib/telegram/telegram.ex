defmodule FeederBot.Telegram do
  require Logger

  @base_url "https://api.telegram.org"
  @bot_id Application.get_env(:feeder_bot, :telegram_token)

  # get_updates
  @get_updates_path "getUpdates"
  @offset_query_param "offset"
  @tiemout_query_param "timeout"
  @reply_markup_query_param "reply_markup"

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
  def send_message({chat_id, text, keyboard}) do
    options = [
      {@chat_id_query_param, chat_id},
      {@text_query_param, text},
      {@disable_preview_query_param, false},
      {@reply_markup_query_param, keyboard}
    ]

    send(options)
  end

  # send message
  def send_message({chat_id, text}) do
    options = [
      {@chat_id_query_param, chat_id},
      {@disable_preview_query_param, false},
      {@text_query_param, text},
    ]

    send(options)
  end

  defp send(options) do
    url = "#{@base_url}/#{@bot_id}/#{@send_message_path}"
    get(url, options)
  end

  defp get(url, query_params, time_out \\ nil) do
    with {:ok, response} <- get_request(url, query_params, time_out).() do
      Logger.info("[RES] ==> #{response.body}")
      case response.status_code do
        200 -> Poison.decode!(response.body)["result"]
        _ -> []
      end
    else
      _ -> []
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

defmodule FeederBot.Telegram.Bot do
  require Logger
  use GenServer
  import FeederBot.Telegram
  import FeederBot.Telegram.MessageHandler

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch() do
    GenServer.call(__MODULE__, :fetch, 25000)
  end

  def send(message) do
    GenServer.cast(__MODULE__, {:send, message})
  end

  # callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_call(:fetch, _from, last_id) do
    new_last_id = case messages = fetch_messages(last_id) do
      [_ | _] ->
        messages
          |> Enum.filter(fn(message_wrapper) -> is_command(message_wrapper) end)
          |> Enum.each(fn(command) -> handle_command(command) end)

        List.last(messages)["update_id"]
      _ ->
        nil
    end

    {:reply, messages, new_last_id}
  end

  def handle_cast({:send, message}, last_id) do
    send_message(message)

    {:noreply, last_id}
  end

  # private
  defp is_command(message_wrapper) do
    case text = message_wrapper["message"]["text"] do
      nil ->
        false
      _ ->
        String.starts_with?(text, "/")
    end
  end
end

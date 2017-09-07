defmodule FeederBot.Telegram.Bot do
  require Logger
  use GenServer
  import FeederBot.Telegram
  import FeederBot.Telegram.CommandHandler

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch() do
    GenServer.call(__MODULE__, :fetch, 25000)
  end

  # callbacks
  def init(_) do
    {:ok, nil}
  end

  def handle_call(:fetch, _from, last_id) do
    new_last_id = case messages = fetch_messages(last_id) do
      [_ | _] ->
        new_state = List.last(messages)["update_id"]

        Task.Supervisor.async_nolink(FeederBot.TaskSupervisor, fn ->
          messages
            |> Enum.filter(fn(message_wrapper) -> is_command(message_wrapper) end)
            |> Enum.map(fn(command) -> handle_command(command) end)
            |> Enum.map(fn(handler) -> handler.() end)
            |> Enum.each(fn({_, message}) -> send_message(message) end)
        end)

        new_state
      _ ->
        nil
    end

    {:reply, messages, new_last_id}
  end

  def handle_info(_, state) do
    {:noreply, state}
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

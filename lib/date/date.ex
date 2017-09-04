defmodule FeederBot.Date do
  def extract_timestamp(date) do
    case date do
      nil ->
        {:ok, -1}
      _ ->
        case date |> Timex.parse("{RFC1123}") do
          {:ok, date_time} ->
            {:ok, DateTime.to_unix(date_time)}
          {:error, _} ->
            {:error, "date can not be parsed using RFC1123"}
        end
    end
  end
end

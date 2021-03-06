defmodule FeederBot.Rss do
  import FeederBot.Date

  def get_subscription_timestamp(url) do
    fetch(url)
    |> extract_max_timestamp
  end

  def fetch(url) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        with {:ok, feed, _} <- FeederEx.parse(response.body)
          do
          feed.entries
        else
          _ -> []
        end
      {:error, _} ->
        []
    end
  end

  def get_rss_last_update(response) do
    headers = response.headers
    with [_ | _] <- headers
                    |> extract_rss_content_type,
         {:ok, last_update} <- extract_last_update(headers)
      do
      {:ok, last_update}
    else
      _ -> error()
    end
  end

  defp extract_rss_content_type(headers) do
    headers
    |> Enum.filter(
         fn ({key, value}) ->
           key == "Content-Type" and String.contains?(value, "text/xml")
         end
       )
  end

  def extract_last_update(headers) do
    case headers
         |> Enum.filter(fn ({key, value}) -> key == "Last-Modified" end)
         |> Enum.map(fn ({_, value}) -> FeederBot.Date.extract_timestamp(value) end) do
      [result] -> result
      _ -> error()
    end
  end

  defp error do
    {:error, "invalid url"}
  end

  def extract_max_timestamp(entries) do
    case entries
         |> Enum.map(fn (entry) -> FeederBot.Date.extract_timestamp(entry.updated) end)
         |> Enum.map(fn ({_, timestamp}) -> timestamp end) do
      elems = [_ | _] -> Enum.max(elems)
      _ -> -1
    end
  end
end
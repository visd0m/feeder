defmodule FeederBot.Rss do
  import FeederBot.Date

  def check_subscription(url = "http" <> _) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        check_feed(response.body)
      {:error, _} ->
        error()
    end
  end

  def check_subscription(_) do
    error()
  end

  defp check_feed("") do
    error()
  end

  defp check_feed(body) do
    body
      |> ElixirFeedParser.parse
      |> check_rss
  end

  defp check_rss(feed) do
    case feed do
      nil ->
        error()
      {:error, _} ->
        error()
      _ ->
        last_item = feed.entries
          |> List.first
        extract_timestamp(last_item.updated)
    end
  end

  defp error do
    {:error, "invalid url"}
  end
end

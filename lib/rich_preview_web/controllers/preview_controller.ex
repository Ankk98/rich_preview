defmodule RichPreviewWeb.PreviewController do
  use RichPreviewWeb, :controller
  require Logger

  def show(conn, %{"url" => url}) do
    Logger.info("Fetching preview for URL: #{url}")
    case fetch_and_parse(url) do
      {:ok, metadata} -> json(conn, metadata)
      {:error, _} -> send_resp(conn, 422, "Preview failed")
    end
  end

  defp fetch_and_parse(url) do
    with {:ok, validated_url} <- validate_url(url),
         {:ok, response} <- fetch_url(validated_url),
         {:ok, metadata} <- parse_html(response.body) do
      {:ok, metadata}
    else
      {:error, :invalid_url} -> {:error, "Invalid URL format"}
      {:error, :fetch_failed} -> {:error, "Failed to fetch URL"}
      {:error, :parse_failed} -> {:error, "Failed to parse content"}
      _ -> {:error, "Unknown error"}
    end
  end

  defp validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: "http" <> _, host: host} when not is_nil(host) ->
        {:ok, url}
      _ ->
        {:error, :invalid_url}
    end
  end

  defp fetch_url(url) do
    headers = [
      {"User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"},
      {"Accept-Language", "en-US,en;q=0.5"}
    ]

    middleware = [
      {Tesla.Middleware.FollowRedirects, max_redirects: 5},
      {Tesla.Middleware.Timeout, timeout: 10_000}
    ]

    client = Tesla.client(middleware)

    case Task.async(fn -> Tesla.get(client, url, headers: headers) end) |> Task.await(11_000) do
      {:ok, %{status: status} = response} when status in 200..299 -> {:ok, response}
      _ -> {:error, :fetch_failed}
    end
  end

  defp parse_html(html) do
    try do
      case Task.async(fn -> RichPreview.Parser.parse_metadata(html) end) |> Task.await() do
        {:ok, metadata} -> {:ok, metadata}
        {:error, :no_metadata} -> {:error, :parse_failed}
        _ -> {:error, :parse_failed}
      end
    rescue
      _ -> {:error, :parse_failed}
    end
  end
end

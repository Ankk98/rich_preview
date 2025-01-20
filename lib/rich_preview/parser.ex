defmodule RichPreview.Parser do
  def parse_metadata(html) do
    {:ok, doc} = Floki.parse_document(html)

    metadata = %{
      title: first_available(doc, ["og:title", "twitter:title", "title"]),
      description: first_available(doc, ["og:description", "twitter:description", "description", "name"]),
      image: first_available(doc, ["og:image", "twitter:image", "image"]),
      url: first_available(doc, ["og:url", "canonical"])
    }

    if Enum.all?(Map.values(metadata), &is_nil/1) do
      {:error, :no_metadata}
    else
      {:ok, Map.reject(metadata, fn {_, v} -> is_nil(v) || v == "" end)}
    end
  end

  defp first_available(doc, selectors) do
    Enum.reduce_while(selectors, nil, fn
      "title", _acc -> # Special case for HTML title
        case Floki.find(doc, "title") |> Floki.text() do
          "" -> {:cont, nil}
          text -> {:halt, String.trim(text)}
        end

      selector, _acc ->
        cond do
          content = find_meta_content(doc, "property", selector) -> {:halt, content}
          content = find_meta_content(doc, "name", selector) -> {:halt, content}
          true -> {:cont, nil}
        end
    end)
  end

  defp find_meta_content(doc, attr_type, selector) do
    case Floki.attribute(doc, "meta[#{attr_type}='#{selector}']", "content") do
      [content | _] when content != "" -> content
      _ -> nil
    end
  end
end

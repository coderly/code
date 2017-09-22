defmodule C.ExURI do
  
  def merge_query_params(%URI{query: nil}=uri, query_params) do
    uri = %{uri | query: ""}
    merge_query_params(uri, query_params)
  end
  def merge_query_params(%URI{query: query}=uri, query_params) do
    new_query = query
                |> URI.decode_query()
                |> Map.merge(query_params)
                |> URI.encode_query()
    %{uri | query: new_query}
  end
  def merge_query_params(uri_string, query_params) when is_binary(uri_string) do
    uri_string
    |> URI.parse()
    |> merge_query_params(query_params)
    |> URI.to_string()
  end

  def merge(uri, base, keys) when is_binary(uri) and is_binary(base)  do
    merge(URI.parse(uri), URI.parse(base), keys)
    |> URI.to_string()
  end
  def merge(%URI{}=uri, %URI{}=base, keys) do
    merge_map = Map.take(base, keys)
    Map.merge(uri, merge_map, &merge_resolve/3)
  end

  defp merge_resolve(_k, v1, nil), do: v1
  defp merge_resolve(_k, _v1, v2), do: v2
  
  end
  
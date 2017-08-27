defmodule Sloc do

  defmodule Node do
    defstruct [:path, :type, line_count: 0, children: %{}]

    def deep_map(%Node{type: :file}=node, func) do
      func.(node)
    end
    def deep_map(%Node{type: :directory, children: children}=node, func) do
      new_children = for {k, n} <- children, into: %{}, do: {k, deep_map(n, func)}
      func.(%{node | children: new_children})
    end
  end

  @path "../turtle/turtle-api/lib"
  @whitelist ~w(.ex .exs .rb .js)

  def run do
    report = get_report(@path)
    IO.puts(format_report(report))
  end

  def format_report(node), do: format_report(node, 0)
  def format_report(%Node{path: path, line_count: line_count, children: children}, depth) do
    [
      String.duplicate("  ", depth),
      Path.basename(path), " (", to_string(line_count), ")",
      format_report(Map.values(children), depth + 1)
    ]
  end
  def format_report(nodes, depth) when is_list(nodes) do
    nodes
    |> Enum.sort_by(fn n -> -n.line_count end)
    |> Enum.map(fn n -> ["\n", format_report(n, depth + 1)] end)
  end

  def get_report(path) do
    get_tree(path)
    |> Node.deep_map(&calculate_line_count/1)
    |> Node.deep_map(&normalize_path(&1, path))
    |> Node.deep_map(&aggregate/1)
  end

  def normalize_path(%Node{path: path}=node, root) do
    %{node | path: Path.relative_to(path, root)}
  end

  def calculate_line_count(%Node{type: :file, path: path}=node) do
    %{node | line_count: line_count(path)}
  end
  def calculate_line_count(%Node{type: :directory}=node), do: node

  def aggregate(%Node{type: :file}=node), do: node
  def aggregate(%Node{type: :directory, children: children}=node) do
    line_count = children |> Map.values() |> Enum.map(&Map.get(&1, :line_count)) |> Enum.sum()
    %{node | line_count: line_count}
  end

  def get_tree(path) do
    cond do
      File.regular?(path) ->
        %Node{type: :file, path: path}
      File.dir?(path) ->
        children = for subpath <- get_filtered_subpaths(path), into: %{} do
          {Path.basename(subpath), get_tree(subpath)}
        end
        %Node{type: :directory, path: path, children: children}
      true -> nil
    end
  end

  def line_count(filepath) do
    File.stream!(filepath)
    |> Stream.reject(&Regex.match?(~r/^\s*$/, &1))
    |> Enum.count()
  end

  def get_filtered_subpaths(path) do
    path
    |> File.ls!()
    |> Enum.map(&Path.join(path, &1))
    |> Enum.reject(&is_dotfile?/1)
    |> Enum.filter(fn p ->
      File.dir?(p) || has_ext?(p, @whitelist)
    end)
  end

  defp is_dotfile?(path) do
    case Path.basename(path) do
      "." <> _ -> true
      _ -> false
    end
  end

  defp has_ext?(path, extensions) do
    Enum.member?(extensions, Path.extname(path))
  end

end

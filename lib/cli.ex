defmodule C.CLI do

  def main(args) do
    {_opts, args, _} = OptionParser.parse(args)

    [cmd | rest_args] = args
    execute(cmd, rest_args)
  end

  # @grep_opts ~w(--break --heading --line-number --ignore-case --color=always --all-match)
  @grep_opts ~w(--ignore-case --color=always --all-match --name-only)
  def execute("look", keywords) do
    with {:ok, commits} <- rev_list(),
         {:ok, lines} <- cmd_value("git", ["grep"] ++ @grep_opts ++ match_patterns(keywords) ++ commits) do
      extract_file_names(lines) |> IO.inspect()
    end
  end
  def execute("sloc", args) do
    report = Sloc.get_report(get_path(args))
    IO.puts(Sloc.format_report(report))
  end
  def execute("req", _) do
    C.GitHub.API.list!() |> IO.inspect()
  end
  def execute("pwd", _), do: cmd("pwd")

  def get_path([]), do: File.cwd!()
  def get_path([path]), do: path

  def extract_file_names(commit_files) do
    commit_files
    |> String.split("\n")
    |> Enum.map(fn line ->
      [sha, file] = String.split(line, ":")
      %{file: file, sha: sha}
    end)
    |> group_by_map(&Map.get(&1, :file), &Map.get(&1, :sha))
  end

  def group_by_map(items, grouper, mapper) do
    items
    |> Enum.group_by(grouper)
    |> Enum.map(fn {k, values} -> {k, Enum.map(values, mapper)} end)
  end

  def cmd(command, args \\ []) do
    case System.cmd(command, args, [into: IO.stream(:stdio, :line), stderr_to_stdout: true, parallelism: false]) do
      {value, 0} -> {:ok, value}
      {_, 1} -> :error
    end
  end

  def cmd_value(command, args) do
    case System.cmd(command, args) do
      {value, 0} -> {:ok, String.trim(value)}
      {err, 1} -> {:error, err}
    end
  end

  def match_patterns(keywords) do
    Enum.flat_map(keywords, fn k -> ["-e", k] end)
  end

  def rev_list() do
    with {rev_list, 0} <- System.cmd("git", ["rev-list", "--all"]) do
      commits = rev_list |> String.trim() |> String.split("\n")
      {:ok, commits}
    end
  end

end

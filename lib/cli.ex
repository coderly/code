defmodule C.CLI do
  import C.Util, only: [cmd_value: 2, cmd: 1, cmd: 2]

  def main(args) do
    {_opts, args, _} = OptionParser.parse(args)

    [cmd | rest_args] = args
    execute(cmd, rest_args)
  end

  def execute("look", keywords) do
    C.Git.search_history(keywords)
    |> format_look()
    |> IO.puts()
  end
  def execute("sloc", args) do
    report = Sloc.get_report(get_path(args))
    IO.puts(Sloc.format_report(report))
  end
  def execute("req", _) do
    C.GitHub.API.list!()
  end
  def execute("pr", _) do
  end
  def execute("branch", _) do
    args = ~w{for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'}
    cmd("git", ["status"])
  end
  def execute("pwd", _), do: cmd("pwd")

  def get_path([]), do: File.cwd!()
  def get_path([path]), do: path

  def format_look(entries) do
    Enum.map_join(entries, "\n\n", &format_entry/1)
  end
  def format_entry(%{file: file, commit: %{hash: hash, author_date: author_date, subject: subject}, matches: matches}) do
    matches = Enum.map_join(matches, "\n", fn {line, text} -> to_string(line) <> ":" <> text end)
    file <> ":" <> hash <> "\n" <> format_date(author_date) <> " " <> subject <> "\n" <> matches
  end

  def format_date(date) do
    [date, _time] = String.split(date, "T", parts: 2)
    date
  end

end

defmodule C.CLI do
  import C.Util, only: [cmd: 2]

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
  def execute("show", [commit_and_file]) do
    C.Git.show_in_editor(commit_and_file)
  end
  def execute("sloc", args) do
    report = Sloc.get_report(get_path(args))
    IO.puts(Sloc.format_report(report))
  end
  def execute("files", patterns) do
    pattern = Enum.join([""] ++ patterns ++ [""], "*")
    {:ok, matches} = C.Util.cmd("find", [".", "-type", "f", "-path", pattern])
    IO.puts(matches)
  end
  def execute("req", _) do
    C.GitHub.API.list!()
  end
  def execute("pr", _) do
    %{"html_url" => url} = C.Git.get_current_matching_pr()
    C.Util.open_in_browser(url)
  end
  def execute("gh", ["search", language | keywords]) do
    params = %{
      "type" => "Code",
      "l" => language
    }
    search_uri = C.ExURI.merge_query_params("https://github.com/search", params) <> "&q=" <> Enum.join(keywords, "+")
    C.Util.open_in_browser(search_uri)
  end
  def execute("pwd", _), do: cmd("pwd", [])

  def get_path([]), do: File.cwd!()
  def get_path([path]), do: path

  def format_look(entries) do
    Enum.map_join(entries, "\n\n", &format_entry/1)
  end
  def format_entry(%{file: file, commit: %{hash: hash, author_date: author_date, subject: subject}, matches: matches}) do
    matches = Enum.map_join(matches, "\n", fn {line, text} -> to_string(line) <> ":" <> text end)
    hash <> ":" <> file <> "\n" <> format_date(author_date) <> " " <> subject <> "\n" <> matches
  end

  def format_date(date) do
    [date, _time] = String.split(date, "T", parts: 2)
    date
  end

end

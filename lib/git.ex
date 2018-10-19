defmodule C.Git do
  alias C.Git.Repo, as: R

  import C.Util, only: [cmd: 2, cmd: 3, result: 2, result: 3, open_in_editor: 1]

  defmodule Commit do
    defstruct [:hash, :subject, :body,
      :author_date, :author_email, :author_name,
      :committer_date, :committer_email, :comitter_name]
  end
  defmodule GrepEntry do
    defstruct [:commit, :file, :matches]
  end

  def checkout(%{hash: hash}, dir), do: checkout(hash, dir)
  def checkout(commit_hash, dir) when is_binary(commit_hash) do
    cmd("git", ["checkout", commit_hash], dir: dir)
  end

  def push(origin, branch) do
    cmd("git", ["push", origin, branch <> ":" <> branch])
  end

  def reduce_over_commits(dir, reducer) do
    {:ok, commits} = list_commits(dir)
    Enum.reduce(commits, reducer)
  end

  def show_in_editor(commit_with_file_path) do
    [_commit, file_path] = String.split(commit_with_file_path, ":", parts: 2)
    tmp_dir = System.tmp_dir()
    file_name = Path.basename(file_path)
    tmp_file_path = Path.join(tmp_dir, file_name)
    Porcelain.exec("git", ["show", commit_with_file_path], out: {:path, tmp_file_path})
    open_in_editor(tmp_file_path)
    {:ok, tmp_file_path}
  end

  @grep_opts ~w(--ignore-case --all-match --heading --break --line-number)
  def search_history(keywords) do
    with {:ok, commits} <- list_commits(),
          commit_hashes <- Enum.map(commits, &Map.get(&1, :hash)),
          {:ok, raw} <- result("git", ["grep"] ++ @grep_opts ++ match_patterns(keywords) ++ commit_hashes),
          entries <- parse_search_history(raw, commits),
          do: filter_to_latest(entries)
  end
  def parse_search_history(raw, commits) do
    commits_by_hash = for c <- commits, into: %{}, do: {c.hash, c}
    raw
    |> String.split("\n\n")
    |> Enum.map(&parse_grep_entry/1)
    |> Enum.map(fn %GrepEntry{commit: hash}=entry ->
      %{entry | commit: Map.get(commits_by_hash, hash) }
    end)
  end
  def filter_to_latest(entries) do
    entries
    |> Enum.group_by(&Map.get(&1, :file))
    |> Enum.map(fn {_k, items} ->
      Enum.max_by(items, fn e -> e.commit.author_date end)
    end)
    |> Enum.sort_by(fn e -> e.commit.author_date end,  &>=/2)
  end

  @commit_fields %{hash: "%H", subject: "%s", body: "%b",
                   author_date: "%aI", author_email: "%ae", author_name: "%an", committer_date: "%cI",
                   committer_email: "%ce", committer_name: "%cn"}
  @delimiter "$$;;"

  def list_commits() do
    {:ok, cwd} = File.cwd()
    list_commits(cwd)
  end
  def list_commits(dir) do
    fields = [:hash, :author_date, :author_name, :subject]
    format = rev_parse_format(fields)
    filter = ["head"]
    with {:ok, commit_string} <- result("git", ["rev-list"] ++ filter ++ ["--format=#{format}"], [dir: dir]),
      do: {:ok, parse_commits(commit_string, fields)}
  end

  def parse_commits(commit_string, fields) do
    commit_string
    |> String.split("\n")
    |> Enum.reject(fn
      "commit " <> _ -> true
      _ -> false
    end)
    |> Enum.map(&parse_commit(&1, fields))
  end

  def parse_commit(line, fields) do
    values = String.split(line, @delimiter)
    attrs = Enum.zip(fields, values) |> Enum.into([])
    struct(Commit, attrs)
  end

  def parse_grep_entry(entry_string) do
    [header | raw_matches] = String.split(entry_string, "\n")
    [commit, file] = String.split(header, ":", parts: 2)
    matches = Enum.map(raw_matches, fn m ->
      [line, text] = String.split(m, ":", parts: 2)
      {String.to_integer(line), text}
    end)
    %GrepEntry{commit: commit, file: file, matches: matches}
  end

  def rev_parse_format(fields) do
    fields
    |> Enum.map(&Map.get(@commit_fields, &1))
    |> Enum.join(@delimiter)
  end

  def create_pull_request(repo) do
    {:ok, {org, repo_name}} = github_org_and_repo()
    branch = R.current_branch(repo)
    C.GitHub.API.get_pull_requests(org: org, repo: repo_name, head: branch, base: "master")
  end

  def get_current_matching_pr(repo) do
    with {:ok, {org, repo_name}} <- github_org_and_repo(),
         branch <- R.current_branch(repo),
         do: get_matching_pull_request(org, repo_name, "master", branch)
  end

  def get_matching_pull_request(org, repo, base, branch) do
    resp = C.GitHub.API.get_pull_requests(org: org, repo: repo, head: "#{org}:#{branch}", base: base)
    case resp.resp_body do
      [pr] -> pr
      _ -> nil
    end
  end

  def github_org_and_repo() do
    with "git@github.com:" <> git_path <- git_url("origin"),
         [org, repo] <- git_path |> String.replace(~r/\.git$/, "") |> String.split("/") do
      {:ok, {org, repo}}
    else
      _ -> {:error, "failed to find org and repo for github project"}
    end
  end

  def git_url(remote_name) do
    with {:ok, url} <- result("git", ["ls-remote", "--get-url", remote_name]), do: url
  end

  def set_config(key, value) do
    cmd("git", ["config", "--global", key, value])
  end
  def get_config(key) do
    result("git", ["config", "--get", key])
  end

  def match_patterns(keywords) do
    Enum.flat_map(keywords, fn k -> ["-e", k] end)
  end

end

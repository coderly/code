defmodule C.Git do

  def current_branch() do
    {:ok, "refs/heads/" <> branch_name} = cmd_value("git", ["symbolic-ref", "HEAD"])
    branch_name
  end

  def create_pull_request do
    {org, repo} = github_org_and_repo()
    branch = current_branch()
    C.GitHub.API.get_pull_requests(org: org, repo: repo, head: branch, base: "master")
  end

  def github_org_and_repo() do
    "git@github.com:" <> git_path = git_url("origin")
    [org, repo] = git_path |> String.replace(~r/\.git$/, "") |> String.split("/")
    {org, repo}
  end

  def git_url(remote_name) do
    with {:ok, url} <- cmd_value("git", ["ls-remote", "--get-url", remote_name]), do: url
  end

  def set_config(key, value) do
    cmd_value("git", ["config", "--global", key, value])
  end
  def get_config(key) do
    cmd_value("git", ["config", "--get", key])
  end

  def cmd_value(command, args) do
    case System.cmd(command, args, cd: "/Users/venkat/Code/turtle/turtle-api") do
      {value, 0} -> {:ok, String.trim(value)}
      {err, 1} -> {:error, err}
    end
  end

end

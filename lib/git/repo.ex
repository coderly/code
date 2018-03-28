defmodule C.Git.Repo do
  defstruct [:dir, master_branch: "master"]
  alias C.Git.Repo, as: R
  import C.Util, only: [cmd: 2, cmd: 3, result: 2, result: 3]

  def new(opts), do: struct(R, opts)

  def pull(%R{dir: dir}, origin_name, branch_name) do
    cmd("git", ["pull", origin_name, "#{branch_name}:#{branch_name}"], dir: dir)
  end

  def current_branch(%R{dir: dir}) do
    {:ok, "refs/heads/" <> branch_name} = result("git", ["symbolic-ref", "HEAD"], dir: dir)
    branch_name
  end

  def create_branch(%R{dir: dir}, branch_name, source) do
    cmd("git", ["checkout", "-b", branch_name, source], dir: dir)
  end
  def checkout_branch(%R{dir: dir}, branch_name) when is_binary(branch_name) do
    cmd("git", ["checkout", branch_name], dir: dir)
  end

  def delete_branch(%R{dir: dir}, branch_name) do
    cmd("git", ["branch", "-d", branch_name])
  end

  def ensure_changes_committed!(repo) do
    case uncommitted_changes?(repo) do
      true -> raise "You have uncommitted changes. Please stash them or commit them first."
      false -> nil
    end
  end

  def checkout(%R{dir: dir}, %{hash: hash}), do: checkout(hash, dir)
  def checkout(%R{dir: dir}, commit_hash) when is_binary(commit_hash) do
    cmd("git", ["checkout", commit_hash], dir: dir)
  end

  def uncommitted_changes?(%R{dir: dir}) do
    case result("git", ["status", "--porcelain"], dir: dir) do
      {:ok, v} when v != "" -> true
      _ -> false
    end
  end

  def stash!(%R{dir: dir}) do
    cmd("git", ["stash"], dir: dir)
  end

  def stash_pop!(%R{dir: dir}) do
    cmd("git", ["stash", "pop"], dir: dir)
  end

end

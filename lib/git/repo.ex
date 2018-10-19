defmodule C.Git.Repo do
  defstruct [:dir, master_branch: "master", protected_branches: []]
  alias C.Git.Repo, as: R
  import C.Util, only: [cmd: 3, result: 3]

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
    cmd("git", ["branch", "-d", branch_name], dir: dir)
  end

  def branches(%R{dir: dir}) do
    with {:ok, lines} <- result("git", ["for-each-ref", "--shell", "--format='%(refname)'", "refs/heads/"], dir: dir),
         do: {:ok, parse_branch_list(lines)}
  end
  def merged_branches(%R{dir: dir, protected_branches: protected_branches}, base_branch) do
    with {:ok, lines} <- result("git", ["for-each-ref", "--shell", "--merged", base_branch, "--format='%(refname)'", "refs/heads/"], dir: dir) do
      branches = parse_branch_list(lines)
      List.delete(branches, base_branch) -- protected_branches
    end
  end

  defp parse_branch_list(text) do
    text
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&clean_branch_name/1)
  end
  defp clean_branch_name(branch_name) do
    branch_name
    |> String.replace_prefix("''refs/heads/", "")
    |> String.replace_suffix("''", "")
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

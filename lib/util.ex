defmodule C.Util do

  @editor "code"

  def cmd(command, args) do
    case Porcelain.exec(command, args, err: :out) do
      %{status: 0, out: result} -> {:ok, String.trim(result)}
      %{status: 1, out: err} -> {:error, err}
    end
  end

  def open_in_browser(url) do
    cmd("open", [url])
  end

  def open_in_editor(path) do
    cmd(@editor, [path])
  end
  
end

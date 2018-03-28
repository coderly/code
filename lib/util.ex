defmodule C.Util do

  @editor "code"
  @browser "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

  def cmd(command, args, opts \\ []) do
    opts = opts ++ [err: :out, out: IO.binstream(:standard_io, :line)]
    IO.puts(IO.ANSI.green() <> Enum.join([command | args], " ") <> IO.ANSI.reset())
    case Porcelain.exec(command, args, opts) do
      %{status: 1} -> exit(:shutdown)
      result -> result
    end
  end

  def result(command, args, opts \\ []) do
    opts = opts ++ [err: :out]
    case Porcelain.exec(command, args, opts) do
      %{status: 0, out: result} -> {:ok, String.trim(result)}
      %{status: 1, out: err} -> {:error, err}
    end
  end

  def open_in_browser(url) do
    cmd(@browser, ["--args", url])
  end

  def open_in_editor(path) do
    cmd(@editor, [path])
  end

end

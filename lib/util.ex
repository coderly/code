defmodule C.Util do

  def cmd(command, args \\ []) do
    case System.cmd(command, args, [into: IO.stream(:stdio, :line), stderr_to_stdout: true, parallelism: false]) do
      {value, 0} -> {:ok, value}
      {err, 1} -> {:error, err}
    end
  end

  def cmd_value(command, args) do
    case System.cmd(command, args, [stderr_to_stdout: true]) do
      {value, 0} -> {:ok, String.trim(value)}
      {err, 1} -> {:error, err}
    end
  end

end

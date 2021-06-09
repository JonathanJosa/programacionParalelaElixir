defmodule Mix.Tasks.Edeliver do
    use Mix.Task
  
    @shortdoc "Build and deploy releases"

    @spec run(OptionParser.argv) :: :ok
    def run(args) do
      edeliver = Path.join [Mix.Project.config[:deps_path], "edeliver", "bin", "edeliver"]
      if (res = run_edeliver(Enum.join([edeliver | args] ++ ["--runs-as-mix-task"], " "))) > 0, do: System.halt(res)
    end
  
    defp run_edeliver(command) do
      port = Port.open({:spawn, shell_command(command)}, [:stream, :binary, :exit_status, :use_stdio, :stderr_to_stdout])
      stdin_pid = Process.spawn(__MODULE__, :forward_stdin, [port], [:link])
      print_stdout(port, stdin_pid)
    end
  
    @doc """
      Forwards stdin to the edeliver script which was spawned as port.
    """
    @spec forward_stdin(port::port) :: :ok
    def forward_stdin(port) do
      case IO.gets(:stdio, "") do
        :eof -> :ok
        {:error, reason} -> throw reason
        data -> Port.command(port, data)
      end
    end
  
  
    # Prints the output received from the port running the edeliver command to stdout.
    # If the edeliver command terminates, it returns the exit code of the edeliver script.
    @spec print_stdout(port::port, stdin_pid::pid) :: exit_status::non_neg_integer
    defp print_stdout(port, stdin_pid) do
      receive do
        {^port, {:data, data}} ->
          IO.write(data)
          print_stdout(port, stdin_pid)
        {^port, {:exit_status, status}} ->
          Process.unlink(stdin_pid)
          Process.exit(stdin_pid, :kill)
          status
      end
    end
  
    # Finding shell command logic from :os.cmd in OTP
    # https://github.com/erlang/otp/blob/8deb96fb1d017307e22d2ab88968b9ef9f1b71d0/lib/kernel/src/os.erl#L184
    defp shell_command(command) do
      case :os.type do
        {:unix, _} ->
          command = command
            |> String.replace("\"", "\\\"")
            |> :binary.bin_to_list
          'sh -c "' ++ command ++ '"'
  
        {:win32, osname} ->
          command = :binary.bin_to_list(command)
          case {System.get_env("COMSPEC"), osname} do
            {nil, :windows} -> 'command.com /c ' ++ command
            {nil, _}        -> 'cmd /c ' ++ command
            {cmd, _}        -> '#{cmd} /c ' ++ command
          end
      end
    end
  end
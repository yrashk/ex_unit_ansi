defmodule ExUnit.ANSIFormatter do
  @moduledoc false

  use GenServer.Behaviour

  defrecord Config, counter: 0, failures: [], isatty: false

  import Exception, only: [format_stacktrace: 1]

  def start do
    { :ok, pid } = :gen_server.start_link(__MODULE__, [], [])
    pid
  end

  def init(_args) do
    { :ok, Config.new(isatty: :eisatty.detect) }
  end

  def handle_call({:each, _test_case, _test, nil }, _from, Config[isatty: false] = config) do
    IO.write "."
    { :reply, :ok, config.increment_counter }
  end

  def handle_call({:each, _test_case, _test, nil }, _from, Config[isatty: true] = config) do
    IO.write ANSI.green(".") <> ANSI.reset
    { :reply, :ok, config.increment_counter }
  end

  def handle_call({:each, test_case, test, failure }, _from, Config[isatty: false] = config) do
    IO.write "F"
    { :reply, :ok, config.increment_counter.
      prepend_failures([{test_case, test, failure}]) }
  end

  def handle_call({:each, test_case, test, failure }, _from, Config[isatty: true] = config) do
    IO.write ANSI.red("F") <> ANSI.reset
    { :reply, :ok, config.increment_counter.
      prepend_failures([{test_case, test, failure}]) }
  end

  def handle_call({:each_case, _test_case}, _from, config) do
    { :reply, :ok, config }
  end

  def handle_call(:finish, _from, config) do
    IO.write "\n\n"
    Enum.reduce Enum.reverse(config.failures), 1, print_failure(&1, &2, config)
    failures_count = length(config.failures)
    if config.isatty do
      IO.puts "#{config.counter} tests, #{ANSI.green(config.counter - failures_count) <> ANSI.reset} passed, #{ANSI.red(failures_count) <> ANSI.reset} failed."
    else
      IO.puts "#{config.counter} tests, #{config.counter - failures_count} passed, #{failures_count} failed."    
    end
    { :reply, failures_count, config }
  end

  defp print_failure({test_case, test, { kind, reason, stacktrace }}, acc, config) do
    if config.isatty, do: IO.write ANSI.red
    IO.puts "#{acc}) #{test} (#{inspect test_case})"
    IO.puts "  ** #{format_catch(kind, reason)}\n  stacktrace:"
    Enum.each filter_stacktrace(stacktrace), fn(s) -> IO.puts "    #{format_stacktrace(s)}" end
    IO.write "\n"
    if config.isatty, do: IO.write ANSI.reset
    acc + 1
  end

  defp format_catch(:error, exception) do
    "(#{inspect exception.__record__(:name)}) #{exception.message}"
  end

  defp format_catch(kind, reason) do
    "(#{kind}) #{inspect(reason)}"
  end

  defp filter_stacktrace([{ ExUnit.Assertions, _, _, _ }|t]), do: filter_stacktrace(t)
  defp filter_stacktrace([h|t]), do: [h|filter_stacktrace(t)]
  defp filter_stacktrace([]), do: []
end
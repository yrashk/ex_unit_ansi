defmodule ExUnit.Formatter.ANSI do
  @moduledoc false

  use GenServer.Behaviour

  defrecord Config, counter: 0, failures: [], isatty: false

  import Exception, only: [format_entry: 1]

  ## New API

  def suite_started() do
    :gen_server.start_link({ :local, __MODULE__ }, __MODULE__, [], [])
  end

  def suite_started(opts) do
    { :ok, pid } = :gen_server.start_link(__MODULE__, [], [])
    pid
  end

  def suite_finished(id // __MODULE__) do
    :gen_server.call(id, :finish)
  end

  def case_started(_id // __MODULE__, _) do
    :ok
  end

  def case_finished(_id // __MODULE__, _) do
    :ok
  end

  def test_started(_id // __MODULE__, _test_case, _test) do
    :ok
  end

  def test_finished(id // __MODULE__, test_case, test, result) do
    :gen_server.call(id, { :each, test_case, test, result })
  end

  ## Old API

  def start do
    { :ok, pid } = :gen_server.start_link(__MODULE__, [], [])
    pid
  end

  def init(_args) do
    { :ok, Config.new(isatty: :eisatty.detect) }
  end

  def handle_call({:each, _test_case, _test, nil }, _from, Config[isatty: false] = config) do
    IO.write "."
    { :reply, :ok, config.update_counter(&1 + 1) }
  end

  def handle_call({:each, _test_case, _test, nil }, _from, Config[isatty: true] = config) do
    IO.write ANSI.green <> "." <> ANSI.reset
    { :reply, :ok, config.update_counter(&1 + 1) }
  end

  def handle_call({:each, test_case, test, failure }, _from, Config[isatty: false] = config) do
    IO.write "F"
    { :reply, :ok, config.update_counter(&1 + 1).
      update_failures([{test_case, test, failure}|&1]) }
  end

  def handle_call({:each, test_case, test, failure }, _from, Config[isatty: true] = config) do
    IO.write ANSI.red <> "F" <> ANSI.reset
    { :reply, :ok, config.update_counter(&1 + 1).
      update_failures([{test_case, test, failure}|&1]) }
  end

  def handle_call({:each_case, _test_case}, _from, config) do
    { :reply, :ok, config }
  end

  def handle_call(:finish, _from, config) do
    IO.write "\n\n"
    Enum.reduce Enum.reverse(config.failures), 1, print_failure(&1, &2, config)
    failures_count = length(config.failures)
    if config.isatty do
      IO.puts "#{config.counter} tests, #{ANSI.green} #{inspect (config.counter - failures_count)} #{ANSI.reset} passed, #{ANSI.red} #{inspect failures_count} #{ANSI.reset} failed."
    else
      IO.puts "#{config.counter} tests, #{config.counter - failures_count} passed, #{failures_count} failed."    
    end
    { :reply, failures_count, config }
  end

  defp print_failure({test_case, test, { kind, reason, stacktrace }}, acc, config) do
    if config.isatty, do: IO.write ANSI.red
    IO.puts "#{acc}) #{test} (#{inspect test_case})"
    IO.puts "  ** #{format_catch(kind, reason)}\n  stacktrace:"
    Enum.each filter_stacktrace(stacktrace), fn(s) -> IO.puts "    #{format_entry(s)}" end
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

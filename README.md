# ExUnit.ANSIFormatter

An ANSI color sequence enabling formatter for ExUnit. If its printing to a TTY, it will print using ANSI sequences, otherwise it will revert to colorless printing.

## Usage

Just add

```elixir
ExUnit.configure formatter: ExUnit.Formatter.ANSI
```

after `ExUnit.start` in your test/test_helper.exs file

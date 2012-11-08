# ExUnit.Formatter.ANSI

An ANSI color sequence enabling formatter for ExUnit. If its printing to a TTY, it will print using ANSI sequences, otherwise it will revert to colorless printing.

## Usage

Just add

```elixir
ExUnit.configure formatter: ExUnit.Formatter.ANSI
```

after `ExUnit.start` in your test/test_helper.exs file

You can also use this formatter globally. To enable this, create a file
called $HOME/.ex_unit.exs with this content:

```elixir
[formatter: ExUnit.Formatter.ANSI]
```

and update your user-wide ERL_LIBS to point to directories that include ex_unit_ansi and ex_unit_ansi's deps.
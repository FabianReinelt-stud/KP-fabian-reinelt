defmodule CLI do
  @moduledoc """
  Reads a single arithmetic expression from the command line and evaluates it.
  """

  def main do
    case System.argv() do
      [expr] ->
        expr
        |> Tokenizer.tokenize()
        |> tap(&IO.puts("Tokens: " <> PrettyPrinter.format_tokens(&1)))
        |> ShuntingYard.to_rpn()
        |> tap(&IO.puts("RPN:    " <> PrettyPrinter.format_rpn(&1)))
        |> RPNcalc.eval()
        |> tap(&IO.puts("Result: " <> PrettyPrinter.format_result(&1)))

      _ ->
        IO.puts("Usage: mix run -e 'CLI.main()' \"EXPRESSION\"")
    end
  end
end

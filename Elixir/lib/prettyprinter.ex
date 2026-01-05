defmodule PrettyPrinter do
  @doc "Pretty-print tokenizer output (infix tokens) without token types."
  def format_tokens({:ok, tokens}), do: format_tokens(tokens)
  def format_tokens({:error, _} = err), do: format_error(err)

  def format_tokens(tokens) when is_list(tokens) do
    tokens
    |> Enum.map(&token_to_string/1)
    |> Enum.join(" ")
  end

  @doc "Pretty-print Shunting Yard output (RPN tokens) without token types."
  def format_rpn({:ok, tokens}), do: format_rpn(tokens)
  def format_rpn({:error, _} = err), do: format_error(err)

  def format_rpn(tokens) when is_list(tokens) do
    tokens
    |> Enum.map(&rpn_token_to_string/1)
    |> Enum.join(" ")
  end

  @doc "Pretty-print final evaluation result (number) or error."
  def format_result({:ok, n}) when is_number(n), do: number_to_string(n)
  def format_result({:error, _} = err), do: format_error(err)

  # ---- token to string helpers ----

  defp token_to_string({:num, n}), do: number_to_string(n)
  defp token_to_string({:op, op}), do: Atom.to_string(op)
  defp token_to_string(:lpar), do: "("
  defp token_to_string(:rpar), do: ")"

  # RPN is just numbers + operators
  defp rpn_token_to_string({:num, n}), do: number_to_string(n)
  defp rpn_token_to_string({:op, op}), do: Atom.to_string(op)

  # Print 2.0 as "2", keep decimals for non-integers
  defp number_to_string(n) do
    if n == trunc(n), do: Integer.to_string(trunc(n)), else: Float.to_string(n)
  end

  defp format_error({:error, reason}), do: "ERROR: " <> inspect(reason)
end

defmodule RPNcalc do
  @moduledoc """
  RPN (Reverse Polish Notation) calculator.

  Consumes an RPN token stream (numbers + operators) and evaluates it using a stack.

  Expected tokens:
    {:num, float()}
    {:op, :+ | :- | :* | :/}

  Notes:
  - Unary operators are not supported (the Shunting Yard stage should already reject them).
  - Negative results are still possible (e.g. 0 3 - => -3).
  """

  @type op :: :+ | :- | :* | :/
  @type token :: {:num, float()} | {:op, op()}

  # Check for errors during tokenizing or shunting yard algorithm
  @spec eval({:ok, [token()]} | {:error, term()}) :: {:ok, float()} | {:error, term()}
  def eval({:error, _} = err), do: err
  def eval({:ok, rpn_tokens}), do: eval(rpn_tokens)

  @doc """
  Evaluate a list of RPN tokens.

  Returns:
    {:ok, result} on success
    {:error, reason} on malformed RPN (stack underflow, leftover items, invalid operator, etc.)
  """
  @spec eval([token()]) :: {:ok, float()} | {:error, term()}
  def eval(tokens) when is_list(tokens) do
    # Stack-based evaluation:
    # - Push numbers onto the stack
    # - On an operator, pop two values (b, a) and push (b op a)
    # The stack is represented as a list, with the head as the top.
    init_stack = []

    with {:ok, stack} <- Enum.reduce_while(tokens, {:ok, init_stack}, &step/2),
         {:ok, result} <- finalize(stack) do
      {:ok, result}
    end
  end

  # -------------------------
  # Per-token evaluation step
  # -------------------------

  # Number: push onto stack
  defp step({:num, n}, {:ok, stack}) when is_number(n) do
    {:cont, {:ok, [n | stack]}}
  end

  # Operator: pop two operands and apply the operation
  defp step({:op, op}, {:ok, [a, b | rest]}) do
    # Operand Order: In RPN "b a op" means "b op a"
    case apply_op(op, b, a) do
      {:ok, value} -> {:cont, {:ok, [value | rest]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  # Operator but not enough operands on stack => malformed RPN (stack underflow)
  defp step({:op, op}, {:ok, _stack}) do
    {:halt, {:error, {:stack_underflow, op}}}
  end

  # Unknown token => malformed RPN
  defp step(tok, {:ok, _stack}) do
    {:halt, {:error, {:unexpected_token, tok}}}
  end

  # -------------------------
  # Operation helpers
  # -------------------------

  defp apply_op(:+, b, a), do: {:ok, b + a}
  defp apply_op(:-, b, a), do: {:ok, b - a}
  defp apply_op(:*, b, a), do: {:ok, b * a}

  defp apply_op(:/, _b, a) when a == 0.0, do: {:error, :division_by_zero}

  defp apply_op(:/, b, a), do: {:ok, b / a}

  defp apply_op(other, _b, _a), do: {:error, {:unknown_operator, other}}

  # -------------------------
  # Finalization
  # -------------------------

  # After consuming all tokens, the stack must contain exactly one result.
  defp finalize([result]), do: {:ok, result}
  defp finalize([]), do: {:error, :empty_expression}
  defp finalize(stack), do: {:error, {:leftover_stack_items, Enum.reverse(stack)}}
end

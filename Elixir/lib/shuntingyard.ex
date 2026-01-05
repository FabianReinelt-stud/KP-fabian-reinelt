defmodule ShuntingYard do
  @moduledoc """
  Shunting Yard implementation.
  Converts a token list in infix order to RPN.

  Input tokens (from the Tokenizer):
    {:num, float()}
    {:op, :+ | :- | :* | :/}
    :lpar
    :rpar

  Output tokens (RPN):
    {:num, float()}
    {:op, :+ | :- | :* | :/}
  """

  @type op :: :+ | :- | :* | :/
  @type token :: {:num, float()} | {:op, op()} | :lpar | :rpar
  @type rpn_token :: {:num, float()} | {:op, op()}

  # Operator precedence table (higher value = higher precedence)
  # Used to decide when operators are popped from the stack.
  @prec %{:+ => 1, :- => 1, :* => 2, :/ => 2}

  # Check for errors during tokenizing
  @spec to_rpn({:ok, [token()]} | {:error, term()}) :: {:ok, [rpn_token()]} | {:error, term()}
  def to_rpn({:error, _} = err), do: err
  def to_rpn({:ok, tokens}), do: to_rpn(tokens)


  @spec to_rpn([token()]) :: {:ok, [rpn_token()]} | {:error, term()}
  def to_rpn(tokens) when is_list(tokens) do

    # Data format: {[output_stack][operator_stack], previous_token}
    init = {[], [], :start}

    # For clarification: reduce_while(enumerable, acc, fun) reduces enumerable as long as fun returns {:cont, term} and stops on {:halt, term}; fun is called like this: fun.(element, acc)
    with {:ok, {out_rev, ops, _prev}} <- Enum.reduce_while(tokens, {:ok, init}, &step/2),
         {:ok, out_rev2} <- drain_ops(ops, out_rev) do
      {:ok, Enum.reverse(out_rev2)}
    end
  end


  # -------------------------
  # Per-token step function
  # -------------------------

  # Number: goes directly to output queue
  defp step({:num, _} = t, {:ok, {out_rev, ops, _prev}}) do
    {:cont, {:ok, {[t | out_rev], ops, :value}}}
  end

  # Left parenthesis: always pushed to operator stack
  defp step(:lpar, {:ok, {out_rev, ops, _prev}}) do
    {:cont, {:ok, {out_rev, [:lpar | ops], :lpar}}}
  end

  # Right parenthesis: pop operators until matching :lpar is found
  defp step(:rpar, {:ok, {out_rev, ops, _prev}}) do
    case pop_until_lpar(ops, out_rev) do
      {:ok, {ops2, out2}} -> {:cont, {:ok, {out2, ops2, :value}}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  # Operator: precedence handling + unary operator rejection
  defp step({:op, op} = t, {:ok, {out_rev, ops, prev}}) do
    # Reject unary operators
    if unary_position?(prev) do
      reason =
        if op == :- do
          :unary_minus_not_supported
        else
          {:operator_in_unary_position, op}
        end

      {:halt, {:error, reason}}
    else
      # While there is an operator on top of the stack with >= precedence,
      # pop it to output (left-associative operators).
      {ops2, out2} = pop_ops_by_precedence(op, ops, out_rev)
      {:cont, {:ok, {out2, [t | ops2], :op}}}
    end
  end

  # Anything else is unexpected
  defp step(other, _state), do: {:halt, {:error, {:unexpected_token, other}}}


  # -------------------------
  # Helpers
  # -------------------------

  # An operator is "unary-position" if it appears:
  # - at the start
  # - right after another operator
  # - right after '('
  defp unary_position?(:start), do: true
  defp unary_position?(:op), do: true
  defp unary_position?(:lpar), do: true
  defp unary_position?(:value), do: false

  # Pop ops from stack to output while top has >= precedence than current op
  defp pop_ops_by_precedence(op, [{:op, top} = top_tok | rest], out_rev) do
    if @prec[top] >= @prec[op] do
      pop_ops_by_precedence(op, rest, [top_tok | out_rev])
    else
      {[{:op, top} | rest], out_rev}
    end
  end

  defp pop_ops_by_precedence(_op, ops, out_rev), do: {ops, out_rev}

  # Pop until :lpar is found; drop the :lpar (do not output it)
  defp pop_until_lpar([:lpar | rest], out_rev), do: {:ok, {rest, out_rev}}
  defp pop_until_lpar([{:op, _} = tok | rest], out_rev), do: pop_until_lpar(rest, [tok | out_rev])
  defp pop_until_lpar([], _out_rev), do: {:error, :mismatched_parentheses}

  # Drain operator stack to output at the end
  defp drain_ops([], out_rev), do: {:ok, out_rev}
  defp drain_ops([:lpar | _], _out_rev), do: {:error, :mismatched_parentheses}
  defp drain_ops([{:op, _} = tok | rest], out_rev), do: drain_ops(rest, [tok | out_rev])
end

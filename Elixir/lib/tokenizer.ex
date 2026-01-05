defmodule Tokenizer do
    @moduledoc """
    Lexical analyzer for arithmetic expressions.
    Splits input into tokens used by the Shunting Yard algorithm.
    """

    # Supported binary operators (unary minus is intentionally not supported)
    @type op :: :+ | :- | :* | :/

    # Token stream produced by the lexer
    @type token :: {:num, float()} | {:op, op()} | :lpar | :rpar

    # Entry point for tokenization, wraps the recursive scanner
    @spec tokenize(String.t()) :: {:ok, [token()]} | {:error, {non_neg_integer(), term()}}
    def tokenize(expr) when is_binary(expr) do
      expr
      |> do_tokenize(0, [])
      |> case do
        {:ok, toks} -> {:ok, Enum.reverse(toks)}
        {:error, _} = err -> err
      end
    end


    # do_tokenize/3: Recursive scanner over the input binary.
    # 'pos' tracks the byte offset for error reporting, 'acc' collects tokens in reverse order

    # Empty binary, End of input
    defp do_tokenize(<<>>, _pos, acc), do: {:ok, acc}

    # Skip whitespace
    defp do_tokenize(<<c, rest::binary>>, pos, acc) when c in [?\s, ?\t, ?\n, ?\r] do
      do_tokenize(rest, pos + 1, acc)
    end

    # Opening parenthesis
    defp do_tokenize(<<"(", rest::binary>>, pos, acc),
      do: do_tokenize(rest, pos + 1, [:lpar | acc])

    # Closing parenthesis
    defp do_tokenize(<<")", rest::binary>>, pos, acc),
      do: do_tokenize(rest, pos + 1, [:rpar | acc])

    # Recognize operators and store them as atoms for easy pattern matching later
    defp do_tokenize(<<c, rest::binary>>, pos, acc) when c in [?\+, ?\-, ?\*, ?\/] do
      op =
        case c do
          ?\+ -> :+
          ?\- -> :-
          ?\* -> :*
          ?\/ -> :/
        end

      do_tokenize(rest, pos + 1, [{:op, op} | acc])
    end

    # Numbers (integers and floats)
    defp do_tokenize(<<c, _::binary>> = bin, pos, acc)
         when (c >= ?0 and c <= ?9) do
      case read_number(bin) do
        {:ok, n, consumed, rest} ->
          do_tokenize(rest, pos + consumed, [{:num, n} | acc])

        {:error, reason} ->
          {:error, {pos, reason}}
      end
    end

    # If this is reached, there is an unexpected character
    defp do_tokenize(<<bad, _::binary>>, pos, _acc), do: {:error, {pos, {:invalid_char, <<bad>>}}}

    # read_number/1: Reads a number (integer or float) from the beginning of the binary
    defp read_number(bin) do

      # Consume consecutive numbers
      {int_part, rest1} = take_digits(bin)

      # Check for potential decimal point and remove it
      {dot?, rest2} =
        case rest1 do
          <<".", r::binary>> -> {true, r}
          _ -> {false, rest1}
        end

      # Consume fractional part if it is there
      {frac_part, rest3} = take_digits(rest2)


      cond do
        # Validation, fraction must contain a digit
        dot? and frac_part == "" ->
          {:error, :expected_fractional_digit}

        true ->
          # Build numeric literal string
          num_str =
            if dot? do
              int_part <> "." <> frac_part
            else
              int_part
            end

          # Attempt to parse the full literal string to a float
          case Float.parse(num_str) do
            {num, ""} ->
              consumed = byte_size(bin) - byte_size(rest3)
              {:ok, num, consumed, rest3}

            _ ->
              {:error, {:invalid_number, num_str}}
          end
      end
    end


    # take_digits/1 and /2: Helper function to consume consecutive digit characters from the binary

    # Wrapper-function, initialize accumulator
    defp take_digits(bin), do: take_digits(bin, "")

    # Digit found, continue recursion
    defp take_digits(<<c, rest::binary>>, acc) when c >= ?0 and c <= ?9 do
      take_digits(rest, acc <> <<c>>)
    end

    # Non-digit found, return accumulated digits and remaining binary
    defp take_digits(rest, acc), do: {acc, rest}
  end

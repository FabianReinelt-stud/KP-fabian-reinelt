# test/tokenizer_test.exs
defmodule TokenizerTest do
  use ExUnit.Case, async: true

  describe "Tokenizer.tokenize/1" do
    test "tokenizes numbers, operators, and parentheses (with whitespace)" do
      assert {:ok, toks} = Tokenizer.tokenize("2 * (0 - 3) + 1/2")

      assert toks == [
               {:num, 2.0},
               {:op, :*},
               :lpar,
               {:num, 0.0},
               {:op, :-},
               {:num, 3.0},
               :rpar,
               {:op, :+},
               {:num, 1.0},
               {:op, :/},
               {:num, 2.0}
             ]
    end

    test "tokenizes floats with decimal point" do
      assert {:ok, toks} = Tokenizer.tokenize("12.34 + 0.5")
      assert toks == [{:num, 12.34}, {:op, :+}, {:num, 0.5}]
    end

    test "tokenizes integer-looking numbers as floats" do
      assert {:ok, toks} = Tokenizer.tokenize("42")
      assert toks == [{:num, 42.0}]
    end

    test "skips whitespace of various kinds" do
      assert {:ok, toks} = Tokenizer.tokenize(" \t\n 1 \r + \t 2 \n")
      assert toks == [{:num, 1.0}, {:op, :+}, {:num, 2.0}]
    end

    test "reports invalid character with position" do
      # "1 + a" -> 'a' is at byte position/index 4
      assert {:error, {4, {:invalid_char, "a"}}} = Tokenizer.tokenize("1 + a")
    end
  end
end

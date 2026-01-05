defmodule ShuntingYardTest do
  use ExUnit.Case, async: true

  describe "ShuntingYard.to_rpn/1 (list input)" do
    test "converts simple expression to RPN (precedence)" do
      toks = [
        {:num, 1.0},
        {:op, :+},
        {:num, 2.0},
        {:op, :*},
        {:num, 3.0}
      ]

      assert {:ok, rpn} = ShuntingYard.to_rpn(toks)
      assert rpn == [
               {:num, 1.0},
               {:num, 2.0},
               {:num, 3.0},
               {:op, :*},
               {:op, :+}
             ]
    end

    test "handles parentheses correctly" do
      toks = [
        :lpar,
        {:num, 1.0},
        {:op, :+},
        {:num, 2.0},
        :rpar,
        {:op, :*},
        {:num, 3.0}
      ]

      assert {:ok, rpn} = ShuntingYard.to_rpn(toks)
      assert rpn == [
               {:num, 1.0},
               {:num, 2.0},
               {:op, :+},
               {:num, 3.0},
               {:op, :*}
             ]
    end

    test "more complex example: 2 * (0 - 3) + 1/2" do
      assert {:ok, toks} = Tokenizer.tokenize("2 * (0 - 3) + 1/2")
      assert {:ok, rpn} = ShuntingYard.to_rpn(toks)

      assert rpn == [
               {:num, 2.0},
               {:num, 0.0},
               {:num, 3.0},
               {:op, :-},
               {:op, :*},
               {:num, 1.0},
               {:num, 2.0},
               {:op, :/},
               {:op, :+}
             ]
    end

    test "errors on mismatched parentheses: missing ')'" do
      toks = [:lpar, {:num, 1.0}, {:op, :+}, {:num, 2.0}]
      assert {:error, :mismatched_parentheses} = ShuntingYard.to_rpn(toks)
    end

    test "errors on mismatched parentheses: unexpected ')'" do
      toks = [{:num, 1.0}, :rpar]
      assert {:error, :mismatched_parentheses} = ShuntingYard.to_rpn(toks)
    end

    test "rejects unary minus at expression start" do
      toks = [{:op, :-}, {:num, 3.0}]
      assert {:error, :unary_minus_not_supported} = ShuntingYard.to_rpn(toks)
    end

    test "rejects unary minus right after '('" do
      toks = [:lpar, {:op, :-}, {:num, 3.0}, :rpar]
      assert {:error, :unary_minus_not_supported} = ShuntingYard.to_rpn(toks)
    end

    test "rejects operator in unary position after another operator" do
      toks = [{:num, 2.0}, {:op, :*}, {:op, :-}, {:num, 3.0}]
      assert {:error, :unary_minus_not_supported} = ShuntingYard.to_rpn(toks)
    end

    test "errors on unexpected token type" do
      assert {:error, {:unexpected_token, :foo}} = ShuntingYard.to_rpn([:foo])
    end
  end

  describe "ShuntingYard.to_rpn/1 (tuple input)" do
    test "passes through {:error, ...} unchanged" do
      assert {:error, :nope} = ShuntingYard.to_rpn({:error, :nope})
    end

    test "accepts {:ok, tokens} and converts" do
      input = {:ok, [{:num, 1.0}, {:op, :+}, {:num, 2.0}]}
      assert {:ok, [{:num, 1.0}, {:num, 2.0}, {:op, :+}]} = ShuntingYard.to_rpn(input)
    end
  end
end

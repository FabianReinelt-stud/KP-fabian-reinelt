defmodule RPNcalcTest do
  use ExUnit.Case, async: true

  describe "RPNcalc.eval/1 (list input)" do
    test "evaluates addition" do
      assert {:ok, 3.0} = RPNcalc.eval([{:num, 1.0}, {:num, 2.0}, {:op, :+}])
    end

    test "respects operand order for subtraction (b a -)" do
      assert {:ok, 7.0} = RPNcalc.eval([{:num, 10.0}, {:num, 3.0}, {:op, :-}])
    end

    test "respects operand order for division (b a /)" do
      assert {:ok, 2.5} = RPNcalc.eval([{:num, 5.0}, {:num, 2.0}, {:op, :/}])
    end

    test "division by zero returns error (covers +0.0 and -0.0 via guard)" do
      assert {:error, :division_by_zero} =
               RPNcalc.eval([{:num, 1.0}, {:num, 0.0}, {:op, :/}])

      # -0.0 is distinct in IEEE-754; guard (a == 0.0) should still catch it
      assert {:error, :division_by_zero} =
               RPNcalc.eval([{:num, 1.0}, {:num, -0.0}, {:op, :/}])
    end

    test "empty token list yields empty_expression" do
      assert {:error, :empty_expression} = RPNcalc.eval([])
    end

    test "stack underflow when operator appears without enough operands" do
      assert {:error, {:stack_underflow, :+}} = RPNcalc.eval([{:op, :+}])
      assert {:error, {:stack_underflow, :*}} = RPNcalc.eval([{:num, 2.0}, {:op, :*}])
    end

    test "unexpected token returns error" do
      assert {:error, {:unexpected_token, :lpar}} = RPNcalc.eval([:lpar])
    end

    test "leftover stack items if too many numbers" do
      assert {:error, {:leftover_stack_items, [1.0, 2.0]}} = RPNcalc.eval([{:num, 1.0}, {:num, 2.0}])
    end

    test "unknown operator returns error" do
      assert {:error, {:unknown_operator, :^}} =
               RPNcalc.eval([{:num, 2.0}, {:num, 3.0}, {:op, :^}])
    end
  end

  describe "RPNcalc.eval/1 (tuple input)" do
    test "passes through {:error, ...} unchanged (pipe-friendly)" do
      assert {:error, :bad} = RPNcalc.eval({:error, :bad})
    end

    test "accepts {:ok, tokens} and evaluates" do
      assert {:ok, 6.0} =
               RPNcalc.eval({:ok, [{:num, 2.0}, {:num, 3.0}, {:op, :*}]})
    end
  end

  describe "integration: Tokenizer -> ShuntingYard -> RPNcalc" do
    test "evaluates a full expression end-to-end" do
      expr = "2 * (0 - 3) + 1/2"

      result =
        Tokenizer.tokenize(expr)
        |> ShuntingYard.to_rpn()
        |> RPNcalc.eval()

      assert {:ok, value} = result
      assert_in_delta value, -5.5, 1.0e-12
    end

    test "propagates unary minus error end-to-end" do
      expr = "2 * -3"

      result =
        Tokenizer.tokenize(expr)
        |> ShuntingYard.to_rpn()
        |> RPNcalc.eval()

      assert {:error, :unary_minus_not_supported} = result
    end
  end
end

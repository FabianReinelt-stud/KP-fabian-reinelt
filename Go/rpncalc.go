package main

import (
	"fmt"
)

// -------------------------
// RPN Calculator
// -------------------------

type stackState struct {
	stack []float64
}

func CalcRPN(tokens []Token) (float64, error) {
	if len(tokens) == 0 {
		return 0, ErrEmptyExpr
	}

	init := stackState{stack: make([]float64, 0, len(tokens))}
	st, err := Reduce(tokens, init, stepRPN)
	if err != nil {
		return 0, err
	}

	if len(st.stack) != 1 {
		return 0, fmt.Errorf("%w: %v", ErrLeftover, st.stack)
	}
	return st.stack[0], nil
}

func stepRPN(st stackState, tok Token) (stackState, error) {
	switch tok.Kind {

	case TokNum:
		st.stack = append(st.stack, tok.Num)
		return st, nil

	case TokOp:
		if len(st.stack) < 2 {
			return st, fmt.Errorf("%w: %c", ErrStackUnderflow, rune(tok.Op))
		}
		a := st.stack[len(st.stack)-1]
		b := st.stack[len(st.stack)-2]
		st.stack = st.stack[:len(st.stack)-2]

		val, err := applyOp(tok.Op, b, a)
		if err != nil {
			return st, err
		}
		st.stack = append(st.stack, val)
		return st, nil

	default:
		return st, fmt.Errorf("unexpected token kind in RPN: %v", tok.Kind)
	}
}

func applyOp(op Op, b, a float64) (float64, error) {
	switch op {
	case OpAdd:
		return b + a, nil
	case OpSub:
		return b - a, nil
	case OpMul:
		return b * a, nil
	case OpDiv:
		if a == 0.0 {
			return 0, ErrDivByZero
		}
		return b / a, nil
	default:
		return 0, fmt.Errorf("unknown operator: %c", rune(op))
	}
}

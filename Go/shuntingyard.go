package main

import "fmt"

// -------------------------
// Shunting Yard
// -------------------------

type prevKind int

const (
	prevStart prevKind = iota
	prevValue
	prevOp
	prevLPar
)

type syState struct {
	out  []Token
	ops  []Token
	prev prevKind
}

func precedence(op Op) int {
	switch op {
	case OpAdd, OpSub:
		return 1
	case OpMul, OpDiv:
		return 2
	default:
		return -1
	}
}

// ToRPN converts infix tokens to RPN using Reduce + step function.
func ToRPN(tokens []Token) ([]Token, error) {
	init := syState{
		out:  make([]Token, 0, len(tokens)),
		ops:  make([]Token, 0, len(tokens)),
		prev: prevStart,
	}

	st, err := Reduce(tokens, init, stepSY)
	if err != nil {
		return nil, err
	}

	// drain ops
	for len(st.ops) > 0 {
		top := st.ops[len(st.ops)-1]
		st.ops = st.ops[:len(st.ops)-1]
		if top.Kind == TokLPar || top.Kind == TokRPar {
			return nil, ErrMismatchedParens
		}
		st.out = append(st.out, top)
	}

	return st.out, nil
}

func stepSY(st syState, tok Token) (syState, error) {
	switch tok.Kind {

	case TokNum:
		st.out = append(st.out, tok)
		st.prev = prevValue
		return st, nil

	case TokLPar:
		st.ops = append(st.ops, tok)
		st.prev = prevLPar
		return st, nil

	case TokRPar:
		found := false
		for len(st.ops) > 0 {
			top := st.ops[len(st.ops)-1]
			st.ops = st.ops[:len(st.ops)-1]
			if top.Kind == TokLPar {
				found = true
				break
			}
			st.out = append(st.out, top)
		}
		if !found {
			return st, ErrMismatchedParens
		}
		st.prev = prevValue
		return st, nil

	case TokOp:
		// reject unary position (start, after op, after '(')
		if st.prev == prevStart || st.prev == prevOp || st.prev == prevLPar {
			if tok.Op == OpSub {
				return st, ErrUnaryMinusNotSupp
			}
			return st, fmt.Errorf("%w: %c", ErrOpInUnaryPos, rune(tok.Op))
		}

		// pop operators with >= precedence
		for len(st.ops) > 0 {
			top := st.ops[len(st.ops)-1]
			if top.Kind == TokLPar {
				break
			}
			if precedence(top.Op) >= precedence(tok.Op) {
				st.ops = st.ops[:len(st.ops)-1]
				st.out = append(st.out, top)
				continue
			}
			break
		}
		st.ops = append(st.ops, tok)
		st.prev = prevOp
		return st, nil

	default:
		return st, fmt.Errorf("unexpected token kind: %v", tok.Kind)
	}
}

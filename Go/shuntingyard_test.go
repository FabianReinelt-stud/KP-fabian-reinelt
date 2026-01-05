package main

import (
	"testing"
)

func assertTokenSeq(t *testing.T, got, want []Token) {
	t.Helper()

	if len(got) != len(want) {
		t.Fatalf("len mismatch: got %d, want %d\n got: %#v\nwant: %#v", len(got), len(want), got, want)
	}

	for i := range want {
		g := got[i]
		w := want[i]

		if g.Kind != w.Kind {
			t.Fatalf("token %d kind mismatch: got %v, want %v\n got: %#v\nwant: %#v", i, g.Kind, w.Kind, g, w)
		}

		// Compare only relevant fields depending on kind
		switch w.Kind {
		case TokNum:
			if g.Num != w.Num {
				t.Fatalf("token %d num mismatch: got %v, want %v", i, g.Num, w.Num)
			}
		case TokOp:
			if g.Op != w.Op {
				t.Fatalf("token %d op mismatch: got %c, want %c", i, g.Op, w.Op)
			}
		}
	}
}

func TestShuntingYardParens_Deep(t *testing.T) {
	toks := []Token{
		{Kind: TokLPar},
		{Kind: TokNum, Num: 1},
		{Kind: TokOp, Op: OpAdd},
		{Kind: TokNum, Num: 2},
		{Kind: TokRPar},
		{Kind: TokOp, Op: OpMul},
		{Kind: TokNum, Num: 3},
	}

	rpn, err := ToRPN(toks)
	if err != nil {
		t.Fatal(err)
	}

	// Expected RPN: 1 2 + 3 *
	want := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokNum, Num: 2},
		{Kind: TokOp, Op: OpAdd},
		{Kind: TokNum, Num: 3},
		{Kind: TokOp, Op: OpMul},
	}
	assertTokenSeq(t, rpn, want)
}

func TestShuntingYardPrecedence_Deep(t *testing.T) {
	toks := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokOp, Op: OpAdd},
		{Kind: TokNum, Num: 2},
		{Kind: TokOp, Op: OpMul},
		{Kind: TokNum, Num: 3},
	}

	rpn, err := ToRPN(toks)
	if err != nil {
		t.Fatal(err)
	}

	// Expected RPN: 1 2 3 * +
	want := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokNum, Num: 2},
		{Kind: TokNum, Num: 3},
		{Kind: TokOp, Op: OpMul},
		{Kind: TokOp, Op: OpAdd},
	}
	assertTokenSeq(t, rpn, want)
}

func TestShuntingYardMismatchedParens(t *testing.T) {
	toks := []Token{
		{Kind: TokLPar},
		{Kind: TokNum, Num: 1},
		{Kind: TokOp, Op: OpAdd},
		{Kind: TokNum, Num: 2},
		// missing RPar
	}

	_, err := ToRPN(toks)
	if err == nil {
		t.Fatal("expected mismatched parentheses error")
	}
}

func TestShuntingYardUnaryMinusRejected(t *testing.T) {
	toks := []Token{
		{Kind: TokOp, Op: OpSub},
		{Kind: TokNum, Num: 3},
	}

	_, err := ToRPN(toks)
	if err == nil {
		t.Fatal("expected unary minus error")
	}
}

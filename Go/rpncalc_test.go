package main

import "testing"

func TestRPNEvalAdd(t *testing.T) {
	rpn := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokNum, Num: 2},
		{Kind: TokOp, Op: OpAdd},
	}

	res, err := CalcRPN(rpn)
	if err != nil {
		t.Fatal(err)
	}

	if res != 3 {
		t.Errorf("expected 3, got %v", res)
	}
}

func TestRPNEvalDivision(t *testing.T) {
	rpn := []Token{
		{Kind: TokNum, Num: 5},
		{Kind: TokNum, Num: 2},
		{Kind: TokOp, Op: OpDiv},
	}

	res, err := CalcRPN(rpn)
	if err != nil {
		t.Fatal(err)
	}

	if res != 2.5 {
		t.Errorf("expected 2.5, got %v", res)
	}
}

func TestDivisionByZero(t *testing.T) {
	rpn := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokNum, Num: 0},
		{Kind: TokOp, Op: OpDiv},
	}

	_, err := CalcRPN(rpn)
	if err == nil {
		t.Fatal("expected division by zero error")
	}
}

package main

import "testing"

func assertTokenKindsAndValues(t *testing.T, got, want []Token) {
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

func TestTokenizeSimple_Deep(t *testing.T) {
	toks, err := Tokenize("1 + 2")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	want := []Token{
		{Kind: TokNum, Num: 1},
		{Kind: TokOp, Op: OpAdd},
		{Kind: TokNum, Num: 2},
	}
	assertTokenKindsAndValues(t, toks, want)
}

func TestTokenizeParensAndOps_Deep(t *testing.T) {
	toks, err := Tokenize("2*(0-3)")
	if err != nil {
		t.Fatal(err)
	}

	want := []Token{
		{Kind: TokNum, Num: 2},
		{Kind: TokOp, Op: OpMul},
		{Kind: TokLPar},
		{Kind: TokNum, Num: 0},
		{Kind: TokOp, Op: OpSub},
		{Kind: TokNum, Num: 3},
		{Kind: TokRPar},
	}

	assertTokenKindsAndValues(t, toks, want)
}

func TestTokenizerInvalidChar(t *testing.T) {
	_, err := Tokenize("1 + a")
	if err == nil {
		t.Fatal("expected error for invalid character")
	}
}

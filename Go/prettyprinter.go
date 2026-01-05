package main

import (
	"math"
	"strconv"
	"strings"
)

// -------------------------
// Pretty printing for nice console IO
// -------------------------

func FormatTokens(tokens []Token) string {
	parts := make([]string, 0, len(tokens))
	for _, t := range tokens {
		switch t.Kind {
		case TokNum:
			parts = append(parts, formatNumber(t.Num))
		case TokOp:
			parts = append(parts, string(rune(t.Op)))
		case TokLPar:
			parts = append(parts, "(")
		case TokRPar:
			parts = append(parts, ")")
		}
	}
	return strings.Join(parts, " ")
}

func FormatRPN(tokens []Token) string {
	parts := make([]string, 0, len(tokens))
	for _, t := range tokens {
		switch t.Kind {
		case TokNum:
			parts = append(parts, formatNumber(t.Num))
		case TokOp:
			parts = append(parts, string(rune(t.Op)))
		}
	}
	return strings.Join(parts, " ")
}

func formatNumber(x float64) string {
	if x == math.Trunc(x) {
		return strconv.FormatInt(int64(x), 10)
	}
	return strconv.FormatFloat(x, 'f', -1, 64)
}

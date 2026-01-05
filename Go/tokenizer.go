package main

import (
	"fmt"
	"strconv"
)

// -------------------------
// Tokenizer
// -------------------------

func Tokenize(expr string) ([]Token, error) {
	var toks []Token
	i := 0

	for i < len(expr) {
		c := expr[i]

		// whitespace
		if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
			i++
			continue
		}

		// parentheses
		if c == '(' {
			toks = append(toks, Token{Kind: TokLPar})
			i++
			continue
		}
		if c == ')' {
			toks = append(toks, Token{Kind: TokRPar})
			i++
			continue
		}

		// operators
		if c == '+' || c == '-' || c == '*' || c == '/' {
			toks = append(toks, Token{Kind: TokOp, Op: Op(c)})
			i++
			continue
		}

		// number
		if c >= '0' && c <= '9' {
			tok, next, err := readNumber(expr, i)
			if err != nil {
				return nil, fmt.Errorf("pos %d: %w", i, err)
			}
			toks = append(toks, tok)
			i = next
			continue
		}

		return nil, fmt.Errorf("pos %d: %w: %q", i, ErrInvalidChar, string(c))
	}

	return toks, nil
}

func readNumber(s string, start int) (Token, int, error) {
	i := start

	// integer part
	for i < len(s) && s[i] >= '0' && s[i] <= '9' {
		i++
	}
	intPart := s[start:i]

	// optional dot
	dot := false
	if i < len(s) && s[i] == '.' {
		dot = true
		i++
	}

	// fractional part digits
	fracStart := i
	for i < len(s) && s[i] >= '0' && s[i] <= '9' {
		i++
	}
	fracPart := s[fracStart:i]

	// If there is a dot, require at least one digit after it
	if dot && fracPart == "" {
		return Token{}, start, ErrExpectedDigit
	}

	numStr := intPart
	if dot {
		numStr = intPart + "." + fracPart
	}

	val, err := strconv.ParseFloat(numStr, 64)
	if err != nil {
		return Token{}, start, fmt.Errorf("%w: %s", ErrInvalidNumber, numStr)
	}
	return Token{Kind: TokNum, Num: val}, i, nil
}

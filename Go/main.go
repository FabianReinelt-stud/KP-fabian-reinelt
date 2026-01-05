package main

import (
	"fmt"
	"os"
	"strings"
)

// -------------------------
// CLI
// -------------------------

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		fmt.Println("Usage: go run . \"EXPR\"")
		return
	}
	expr := strings.Join(args, " ")

	toks, err := Tokenize(expr)
	if err != nil {
		fmt.Println("Tokenizer error:", err)
		return
	}
	fmt.Println("Tokens:", FormatTokens(toks))

	rpn, err := ToRPN(toks)
	if err != nil {
		fmt.Println("Shunting Yard error:", err)
		return
	}
	fmt.Println("RPN:   ", FormatRPN(rpn))

	res, err := CalcRPN(rpn)
	if err != nil {
		fmt.Println("RPN eval error:", err)
		return
	}
	fmt.Println("Result:", formatNumber(res))
}

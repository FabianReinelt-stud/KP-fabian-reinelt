package main

import "errors"

// -------------------------
// Shared types
// -------------------------

type TokenKind int

const (
	TokNum TokenKind = iota
	TokOp
	TokLPar
	TokRPar
)

type Op rune

const (
	OpAdd Op = '+'
	OpSub Op = '-'
	OpMul Op = '*'
	OpDiv Op = '/'
)

type Token struct {
	Kind TokenKind
	Num  float64
	Op   Op
}

// -------------------------
// Generic Reduce
// -------------------------

func Reduce[T any, A any](slice []T, init A, step func(A, T) (A, error)) (A, error) {
	acc := init
	for _, x := range slice {
		var err error
		acc, err = step(acc, x)
		if err != nil {
			return acc, err
		}
	}
	return acc, nil
}

// -------------------------
// Errors
// -------------------------

var (
	ErrInvalidChar       = errors.New("invalid character")
	ErrExpectedDigit     = errors.New("expected digit")
	ErrInvalidNumber     = errors.New("invalid number")
	ErrMismatchedParens  = errors.New("mismatched parentheses")
	ErrUnaryMinusNotSupp = errors.New("unary minus not supported")
	ErrOpInUnaryPos      = errors.New("operator in unary position")
	ErrStackUnderflow    = errors.New("stack underflow")
	ErrLeftover          = errors.New("leftover stack items")
	ErrEmptyExpr         = errors.New("empty expression")
	ErrDivByZero         = errors.New("division by zero")
)

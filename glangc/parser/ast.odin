package glangc_parser

import "../common"
import "../report"

Span :: report.Span

InSpan :: struct($T: typeid) {
	using span: Span `fmt:"-"`,
	item:       T,
}

AST :: struct {
	target: common.Target,
	decls:  [dynamic]Decl,
}

Decl :: union {
	Builtin_Type,
	Function,
	Global,
}

SymbolDecl :: struct {
	using span: Span `fmt:"-"`,
	name:       Identifier,
}

Builtin_Type :: distinct SymbolDecl

Global_Kind :: enum {
	Normal,
	Uniform,
	Builtin,
}

Global :: struct {
	using span: Span `fmt:"-"`,
	symbol:     SymbolDecl,
	kind:       Global_Kind,
	type:       Type,
	value:      Maybe(Expr),
}

Param :: struct {
	using span: Span,
	type:       Type,
	name:       Maybe(Identifier),
}

Function :: struct {
	using span: Span `fmt:"-"`,
	symbol:     SymbolDecl,
	params:     [dynamic]Param,
	returns:    Maybe(Type),
	block:      Maybe(Block_Stmt), // nil ? builtin
}

// ============== statements ==============

Stmt :: union {
	Block_Stmt,
	Return_Stmt,
	Expr_Stmt,
}

Block_Stmt :: struct {
	using span: Span `fmt:"-"`,
	statements: [dynamic]Stmt,
}

Return_Stmt :: struct {
	using span: Span `fmt:"-"`,
	expr:       Maybe(Expr),
}

Expr_Stmt :: struct {
	expr: Expr,
}

// ============== expressions ==============

Expr :: union {
	Assign_Expr,
	Binary_Expr,
	Call_Expr,
	Literal_Expr,
	Identifier,
}

Assign_Expr :: struct {
	using span: Span `fmt:"-"`,
	dest:       ^Expr,
	expr:       ^Expr,
}

Binary_Expr :: struct {
	using span: Span `fmt:"-"`,
	op:         Token_Kind,
	lhs:        ^Expr,
	rhs:        ^Expr,
}

Call_Expr :: struct {
	using span: Span `fmt:"-"`,
	callee:     Identifier,
	args:       [dynamic]Expr,
}

Literal_Expr :: struct {
	using token: Token `fmt:"-"`,
}

Identifier :: struct {
	pos:  Pos `fmt:"-"`,
	text: string,
}

// ============== types ==============

Type :: union {
	Identifier,
}

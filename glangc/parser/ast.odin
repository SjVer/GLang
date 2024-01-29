package glangc_parser

import "../common"

Span :: struct {
	start, end: Pos,
}

InSpan :: struct($T: typeid) {
	using span: Span `fmt:"-"`,
	item:       T,
}

Module :: struct {
	target: common.Target,
	decls: [dynamic]Decl,
}

Decl :: union {
	Function,
	Global
}

Global_Kind :: enum {
	Normal,
	Uniform,
	Builtin,
}

Global :: struct {
	using span: Span `fmt:"-"`,
	kind: Global_Kind,
	type: Type,
	name: InSpan(string),
	value: Maybe(Expr),
}

Param :: struct {
	type: Type,
	name: Maybe(InSpan(string))
}

Function :: struct {
	using span: Span `fmt:"-"`,
	name:       InSpan(string),
	params:		[dynamic]Param,
	returns:	Maybe(Type),
	block:      Maybe(Block_Stmt), // nil ? builtin
}

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

Expr :: union {
	Assign_Expr,
	Binary_Expr,
	Literal_Expr,
}

Assign_Expr :: struct {
	using span: Span `fmt:"-"`,
	dest: ^Expr,
	expr: ^Expr,
}

Binary_Expr :: struct {
	using span: Span `fmt:"-"`,
	op: Token_Kind,
	lhs: ^Expr,
	rhs: ^Expr,
}

Literal_Expr :: struct {
	pos:  Pos `fmt:"-"`,
	kind: Token_Kind,
}

Type :: InSpan(string)
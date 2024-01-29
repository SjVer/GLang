package glangc_parser

Span :: struct {
	start, end: Pos,
}

InSpan :: struct($T: typeid) {
	using span: Span `fmt:"-"`,
	item:       T,
}

Module :: struct {
	decls: [dynamic]Decl,
}

Decl :: union {
	Function
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
	Literal_Expr,
}

Literal_Expr :: struct {
	pos:  Pos `fmt:"-"`,
	kind: Token_Kind,
}

Type :: InSpan(string)
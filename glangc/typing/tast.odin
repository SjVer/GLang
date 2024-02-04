package glangc_typing

import "../report"

TAST :: struct {
	decls: [dynamic]Decl,
}

Symbol :: struct($TypeType: typeid) {
	type: TypeType,
	name: string,
}

Decl :: struct {
	span: report.Span,
	decl: _Decl,
}

_Decl :: union {
	Builtin,
	Global,
	Function,
}

Builtin :: union {
	Symbol(Type),
	Symbol(FuncType),
}

Global_Kind :: enum {
	Normal,
	Uniform,
}

Global :: struct {
	using symbol: Symbol(Type),
	kind:         Global_Kind,
	value:        Maybe(Expr),
}

Function :: struct {
	using symbol: Symbol(FuncType),
	// params' types point to the symbol type
	// so no need for memory fuckery
	params:       [dynamic]Symbol(^Type),
	block:        Block_Stmt,
}

// ============== statements ==============

Stmt :: union {
	Block_Stmt,
	Return_Stmt,
	Expr_Stmt,
}

Block_Stmt :: struct {
	statements: [dynamic]Stmt,
}

Return_Stmt :: struct {
	expr: Maybe(Expr),
}

Expr_Stmt :: struct {
	expr: Expr,
}

// ============== expressions ==============

Expr :: union {
	Assign_Expr,
	Binary_Expr,
	Call_Expr,
	Cast_Expr,
	Literal_Expr,
	identifier,
}

Assign_Expr :: struct {
	dest: ^Expr,
	expr: ^Expr,
}

Binary_Op :: enum {
	Eq, // =
	Add, // +
	Sub, // -
	Mul, // *
	Div, // /
	And, // &
	Or, // |
	Xor, // ~
	Shl, // <<
	Shr, // >>
	Cmp_And, // &&
	Cmp_Or, // ||
	Cmp_Eq, // ==
	Not_Eq, // !=
	Lt, // <
	Gt, // >
	Lt_Eq, // <=
	Gt_Eq, // >=
}

Binary_Expr :: struct {
	op:  Binary_Op,
	lhs: ^Expr,
	rhs: ^Expr,
}

Call_Expr :: struct {
	callee: string,
	args:   [dynamic]Expr,
}

Cast_Expr :: struct {
	type: Type,
	expr: ^Expr,
}

Literal_Expr :: union {
	Lit_Integer,
	Lit_Float,
}

identifier :: distinct string

Lit_Integer :: union {
	bool,
	rune,
	int,
	uint,
	i8,
	u8,
	i16,
	u16,
	i32,
	u32,
	i64,
	u64,
	i128,
	u128,
}

Lit_Float :: union {
	f16,
	f32,
	f64,
}

// ============== types ==============

FuncType :: struct {
	params:  [dynamic]Type,
	returns: Type,
}

Type :: union {
	identifier,
	Primitive_Type,
}

Primitive_Type :: enum {
	Integer,
	Float,
	Void,
}

type_to_string :: proc(type: Type) -> string {
	switch type in type {
		case nil:
			return "<error>"

		case Primitive_Type:
			switch type {
				case .Integer:
					return "#int"
				case .Float:
					return "#float"
				case .Void:
					return "#void"
			}

		case identifier:
			return auto_cast type
	}

	assert(false, "invalid type")
	return ""
}

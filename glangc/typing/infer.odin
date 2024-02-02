package glangc_typing

import p "../parse"
import "../report"
import "core:strconv"

infer_expr :: proc(expr: p.Expr, lvalue := false) -> (Expr, Type) {
	switch expr in expr {
		case p.Assign_Expr:
			return infer_assign_expr(expr)
		case p.Binary_Expr:
			return infer_binary_expr(expr)
		case p.Call_Expr:
			return infer_call_expr(expr)
		case p.Literal_Expr:
			return infer_literal(expr)
		case p.Identifier:
			ident := cast(identifier)expr.text
			return ident, get_symbol_type(expr.text)

	}
	panic("invalid AST expr")
}

infer_assign_expr :: proc(expr: p.Assign_Expr) -> (Assign_Expr, Type) {
	ret: Assign_Expr

	dest, dest_type := infer_expr(expr.dest^, true)
	src, src_type := infer_expr(expr.expr^)
	res := unify(dest_type, src_type, p.get_expr_span(expr.expr^))

	ret.dest = new_clone(dest)
	casted_src := maybe_cast(src, src_type, res)
	if !can_cast(res, dest_type) { 	// just makin sure
		res_str := type_to_string(res)
		dest_str := type_to_string(dest_type)
		rep := report.error(
			p.get_expr_span(expr.expr^),
			"cannot cast from inferred type '%s' to '%s'",
			res_str,
			dest_str,
		)
		report.add_note(
			rep,
			p.get_expr_span(expr.dest^),
			"assignment destination type is '%s'",
			dest_str,
		)
	}
	ret.expr = new_clone(maybe_cast(casted_src, res, dest_type))

	return ret, dest_type
}

infer_binary_expr :: proc(expr: p.Binary_Expr) -> (Binary_Expr, Type) {
	ret: Binary_Expr

	#partial switch expr.op {
		case .Eq:
			ret.op = .Eq
		case .Add:
			ret.op = .Add
		case .Sub:
			ret.op = .Sub
		case .Mul:
			ret.op = .Mul
		case .Div:
			ret.op = .Div
		case .And:
			ret.op = .And
		case .Or:
			ret.op = .Or
		case .Xor:
			ret.op = .Xor
		case .Shl:
			ret.op = .Shl
		case .Shr:
			ret.op = .Shr
		case .Cmp_And:
			ret.op = .Cmp_And
		case .Cmp_Or:
			ret.op = .Cmp_Or
		case .Cmp_Eq:
			ret.op = .Cmp_Eq
		case .Not_Eq:
			ret.op = .Not_Eq
		case .Lt:
			ret.op = .Lt
		case .Gt:
			ret.op = .Gt
		case .Lt_Eq:
			ret.op = .Lt_Eq
		case .Gt_Eq:
			ret.op = .Gt_Eq

		case:
			panic("invalid AST binary operator")
	}

	// TODO: infer based on binary operator

	lhs, lhs_type := infer_expr(expr.lhs^)
	rhs, rhs_type := infer_expr(expr.rhs^)
	type := unify(lhs_type, rhs_type, p.get_expr_span(expr.rhs^))

	ret.lhs = new_clone(maybe_cast(lhs, lhs_type, type))
	ret.rhs = new_clone(maybe_cast(rhs, rhs_type, type))

	free(expr.lhs)
	free(expr.rhs)

	return ret, type
}

infer_call_expr :: proc(expr: p.Call_Expr) -> (Call_Expr, Type) {
	ret := Call_Expr {
		callee = expr.callee.text,
		args = {},
	}

	funcname := expr.callee.text
	if funcname not_in function_types do return ret, nil
	functype := function_types[funcname]

	if len(functype.params) != len(expr.args) {
		rep := report.error(
			expr.span,
			"expected %d arguments, found %d",
			len(functype.params),
			len(expr.args),
		)
		report.add_note(
			rep,
			function_spans[funcname],
			"function '%s' defined here",
			funcname,
		)
		return ret, functype.returns
	}

	for a, i in expr.args {
		arg, type := infer_expr(a)

		res := unify(type, functype.params[i], p.get_expr_span(a))
		// TODO: add 'parameter defined here' note?

		append(&ret.args, maybe_cast(arg, type, res))
	}

	return ret, functype.returns
}

infer_literal :: proc(lit: p.Literal_Expr) -> (Literal_Expr, Type) {
	#partial switch lit.kind {
		case .Char:
			char := cast(u8)lit.text[0]
			assert(0 <= char && char <= 0xff, "invalid AST char literal")
			// TODO: return proper type
			return cast(Lit_Integer)char, Primitive_Type.Integer

		case .Integer:
			// TODO: determine the integer's type first
			i, ok := strconv.parse_int(lit.text)
			assert(ok, "invalid AST integer literal")
			return cast(Lit_Integer)i, Primitive_Type.Integer

		case .Float:
			// TODO: determine the float's type first
			f, ok := strconv.parse_f32(lit.text)
			assert(ok, "invalid AST float literal")
			return cast(Lit_Float)f, Primitive_Type.Float
	}
	panic("invalid AST literal kind")
}

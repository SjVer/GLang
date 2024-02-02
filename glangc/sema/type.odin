package glangc_sema

import "../report"

Span :: report.Span

type_to_string :: proc(type: Type) -> string {
    switch type in type {
        case nil: return "<error>"
        case identifier: return auto_cast type
    }

    assert(false, "invalid type")
    return ""
}

typecheck_expr :: proc(expr: Expr, type: Type, span: Span) {
	unify(infer_expr(expr, span), type, span)
}

unify :: proc(expected, got: Type, span: Span) -> Type {
	switch expected in expected {
		case identifier:
			got, is_ident := got.(identifier)
			if is_ident && expected == got do return expected
	}

	expected := type_to_string(expected)
	got := type_to_string(got)
	report.error(span, "expected type '%s', found type '%s'", expected, got)
    return nil
}

infer_expr :: proc(expr: Expr, span: Span) -> Type {
	switch e in expr {
		case Assign_Expr:
		// TODO

		case Binary_Expr:
			// TODO: operator-specific inference
			lhs := infer_expr(e.lhs^, span)
			rhs := infer_expr(e.rhs^, span)
			return unify(lhs, rhs, span)

		case Call_Expr:
		// TODO

		case Literal_Expr:
		// TODO: make better
            switch lit in e {
                case Lit_Integer: return cast(identifier)"int"
                case Lit_Float: return cast(identifier)"float"
            }

		case identifier:
			return scope.symbol_types[auto_cast e]
	}

    assert(false, "invalid expr")
    return nil
}

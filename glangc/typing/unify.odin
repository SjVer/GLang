package glangc_typing

import "../report"

can_cast :: proc(from, to: Type) -> bool {
	if from == nil || to == nil do return true
	
	// TODO
	return from == to
}

unify :: proc(
	expected, found: Type,
	span: report.Span,
	note: Maybe(report.Report) = nil,
	loc := #caller_location,
) -> Type {
	if expected == nil do return found
	if found == nil do return nil

	e := expected;f := found
	if ident, ok := expected.(identifier); ok do e = typedef_types[ident]
	if ident, ok := found.(identifier); ok do f = typedef_types[ident]

	// TODO: do a better job
	if can_cast(found, expected) do return f
	else {
		estr := type_to_string(expected)
		fstr := type_to_string(found)
		rep := report.error(span, "expected type '%s', found type '%s'", estr, fstr, loc = loc)

		// if ident, ok := expected.(identifier); ok {
		// 	report.add_note(rep, typedef_spans[ident], "type '%s' defined here", ident)
		// }
		// if ident, ok := found.(identifier); estr != fstr && ok {
		// 	report.add_note(rep, typedef_spans[ident], "type '%s' defined here", ident)
		// }
		if note, ok := note.?; ok do append(&rep.related, note)

		return nil
	}
}

maybe_cast :: proc(expr: Expr, from, to: Type) -> Expr {
	// TODO: make better
	if from == to do return expr
	else do return Cast_Expr{expr = new_clone(expr), type = to}
}

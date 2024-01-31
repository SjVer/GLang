package glangc_sema

import p "../parser"
import "../report"

Scope :: struct {
	depth:   int,
	symbols: map[string]p.Span,
}

state_stack: [dynamic]Scope
scope := Scope {
	depth   = 0,
	symbols = make_map(map[string]p.Span),
}

types := make_map(map[string]p.Span)

had_error := false

push_state :: proc() {
	depth := scope.depth + 1
	append(&state_stack, scope)

	scope := Scope {
		depth   = depth,
		symbols = make_map(map[string]p.Span),
	}
}

pop_state :: proc() {
	assert(len(state_stack) >= 1)
	scope = pop(&state_stack)
}

check_symbol_exists :: proc(name: string, pos: p.Pos) {
	if name in scope.symbols do return
	#reverse for s in state_stack {
		if name in s.symbols do return
	}

	had_error = true
	rep := report.error(
		report.span_of_pos(pos, len(name)),
		"use of undefined symbol '%s'",
		name,
	)
	if name in types {
		report.add_note(rep, types[name], "type '%s' defined here", name)
	}
}

check_type_exists :: proc(name: string, pos: p.Pos) {
	if name in types do return

	had_error = true
	rep := report.error(
		report.span_of_pos(pos, len(name)),
		"use of undefined type '%s'",
		name,
	)
	// hint if symbol with same name exists
	symbol_span: Maybe(p.Span) = nil
	if name in scope.symbols do symbol_span = scope.symbols[name]
	else {
		#reverse for s in state_stack {
			if name in s.symbols {
				symbol_span = s.symbols[name]
				break
			}
		}
	}
	if s, ok := symbol_span.?; ok {
		report.add_note(rep, s, "symbol '%s' defined here", name)
	}
}

add_local :: proc(name: string, span: p.Span) {
	// top level cannot have locals
	if len(state_stack) == 0 do return

	if name in scope.symbols {
		had_error = true
		rep := report.error(span, "redefinition of local '%s'", name)
		report.add_note(rep, scope.symbols[name], "previously defined here")
	} else {
		scope.symbols[name] = span
	}
}

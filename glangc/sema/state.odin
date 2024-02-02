package glangc_sema

import p "../parse"
import "../report"

Scope :: struct {
	depth:   int,
	symbol_spans: map[string]p.Span,
	symbol_types: map[string]Type,
	symbol_functypes: map[string]FuncType,
}

scope_stack: [dynamic]Scope
scope := Scope {
	depth   = 0,
	symbol_spans = make_map(map[string]p.Span),
	symbol_types = make_map(map[string]Type),
	symbol_functypes = make_map(map[string]FuncType),
}

types := make_map(map[string]p.Span)

push_state :: proc() {
	depth := scope.depth + 1
	append(&scope_stack, scope)
	
	scope := Scope {
		depth   = depth,
		symbol_spans = make_map(map[string]p.Span),
		symbol_types = make_map(map[string]Type),
		symbol_functypes = make_map(map[string]FuncType),
	}
}

pop_state :: proc() {
	assert(len(scope_stack) >= 1)
	scope = pop(&scope_stack)
}

check_symbol_exists :: proc(name: string, pos: p.Pos) {
	if name in scope.symbol_spans do return
	#reverse for s in scope_stack {
		if name in s.symbol_spans do return
	}

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

	rep := report.error(
		report.span_of_pos(pos, len(name)),
		"use of undefined type '%s'",
		name,
	)
	// hint if symbol with same name exists
	symbol_span: Maybe(p.Span) = nil
	if name in scope.symbol_spans do symbol_span = scope.symbol_spans[name]
	else {
		#reverse for s in scope_stack {
			if name in s.symbol_spans {
				symbol_span = s.symbol_spans[name]
				break
			}
		}
	}
	if s, ok := symbol_span.?; ok {
		report.add_note(rep, s, "symbol '%s' defined here", name)
	}
}

add_type :: proc(name: string, span: p.Span) {
	if name in types {
		rep := report.error(span, "redeclaration of type '%s'", name)
		report.add_note(rep, types[name], "previously declared here")
	} else {
		types[name] = span
	}
}

_add_symbol :: proc(what, name: string, span: p.Span) -> bool {
	if name in scope.symbol_spans {
		rep := report.error(span, "redefinition of %s '%s'", what, name)
		report.add_note(rep, scope.symbol_spans[name], "previously defined here")
		return false
	}

	scope.symbol_spans[name] = span
	return true
}

add_global :: proc(name: string, type: Type, span: p.Span) {
	assert(len(scope_stack) == 0, "global in non-top level")
	
	if _add_symbol("global", name, span) {
		scope.symbol_types[name] = type
	}
}

add_function :: proc(name: string, type: FuncType, span: p.Span) {
	assert(len(scope_stack) == 0, "function in non-top level")
	
	if _add_symbol("global", name, span) {
		scope.symbol_functypes[name] = type
	}
}

add_local :: proc(name: string, type: Type, span: p.Span) {
	assert(len(scope_stack) > 0, "local in top level")

	if _add_symbol("local", name, span) {
		scope.symbol_types[name] = type
	}
}

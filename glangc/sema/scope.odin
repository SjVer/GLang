package glangc_sema

import p "../parse"

Scope :: struct {
	symbols: map[string]p.Span,
}

scope_stack: [dynamic]Scope
scope := Scope {
	symbols = make_map(map[string]p.Span),
}

types := make_map(map[string]p.Span)

push_scope :: proc() {
	append(&scope_stack, scope)

	scope := Scope {
		symbols = make_map(map[string]p.Span),
	}
}

pop_scope :: proc() {
	assert(len(scope_stack) >= 1)
	scope = pop(&scope_stack)
}

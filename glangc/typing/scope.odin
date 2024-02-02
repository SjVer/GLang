package glangc_typing

import p "../parse"
import "../report"

Scope :: struct {
	symbol_types: map[string]Type,
	symbol_spans: map[string]p.Span,
	return_type:  Type,
}

scope_stack: [dynamic]Scope
scope := Scope {
	symbol_types = make_map(map[string]Type),
	symbol_spans = make_map(map[string]p.Span),
	return_type  = nil,
}

typedef_types := make_map(map[identifier]Type)
typedef_spans := make_map(map[identifier]p.Span)

function_types := make_map(map[string]FuncType)
function_spans := make_map(map[string]p.Span)

push_scope :: proc(return_type: Type = nil) {
	append(&scope_stack, scope)

	scope := Scope {
		symbol_types = make_map(map[string]Type),
		symbol_spans = make_map(map[string]p.Span),
		return_type  = return_type,
	}
}

pop_scope :: proc() {
	assert(len(scope_stack) >= 1)
	scope = pop(&scope_stack)
}

get_return_type :: proc() -> Type {
	if scope.return_type != nil do return scope.return_type

	#reverse for s in scope_stack {
		if s.return_type != nil do return s.return_type
	}

	return nil
}

get_symbol_type :: proc(name: string) -> Type {
	return scope.symbol_types[name] or_else nil
}

add_typedef :: proc(ident: identifier, type: Type, span: p.Span) {
	if ident not_in typedef_types {
		assert(ident not_in typedef_spans, "huh")
		typedef_types[ident] = type
		typedef_spans[ident] = span
	} else do assert(ident in typedef_spans, "huh")
}

add_function :: proc(name: string, type: FuncType, span: p.Span) {
	if name not_in function_types {
		assert(name not_in function_spans, "huh")
		function_types[name] = type
		function_spans[name] = span
	} else do assert(name in function_spans, "huh")
}

add_symbol :: proc(name: string, type: Type, span: p.Span) {
	if name not_in scope.symbol_types {
		assert(name not_in scope.symbol_spans, "huh")
		scope.symbol_types[name] = type
		scope.symbol_spans[name] = span
	} else do assert(name in scope.symbol_spans, "huh")
}

package glangc_sema

import p "../parse"
import "../report"

import "core:slice"
import "core:strings"

did_you_mean_symbol :: proc(rep: ^report.Report, query: string) {
	found := "";found_dist := 4

	append(&scope_stack, scope)
	#reverse for s in scope_stack {
		for name in s.symbols {
			dist, _ := strings.levenshtein_distance(name, query)
			if dist < found_dist {
				found = name
				found_dist = dist
			}
		}
	}
    pop(&scope_stack)

	if len(found) > 0 {
		report.add_note(rep, nil, "did you mean '%s'?", found)
	}
}

did_you_mean_type :: proc(rep: ^report.Report, query: string) {
	found := "";found_dist := 4

	for name in types {
        dist, _ := strings.levenshtein_distance(name, query)
        if dist < found_dist {
            found = name
            found_dist = dist
        }
    }

	if len(found) > 0 {
		report.add_note(rep, nil, "did you mean '%s'?", found)
	}
}

check_symbol_exists :: proc(name: string, pos: p.Pos) {
	if name in scope.symbols do return
	#reverse for s in scope_stack {
		if name in s.symbols do return
	}

	rep := report.error(
		report.span_of_pos(pos, len(name)),
		"use of undefined symbol '%s'",
		name,
	)
	did_you_mean_symbol(rep, name)
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
    did_you_mean_type(rep, name)
	// hint if symbol with same name exists
	symbol_span: Maybe(p.Span) = nil
	if name in scope.symbols do symbol_span = scope.symbols[name]
	else {
		#reverse for s in scope_stack {
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

add_type :: proc(name: string, span: p.Span) {
	if name in types {
		rep := report.error(span, "redeclaration of type '%s'", name)
		report.add_note(rep, types[name], "previously declared here")
	} else {
		types[name] = span
	}
}

add_global :: proc(name: string, span: p.Span) {
	assert(len(scope_stack) == 0, "global in non-top level")

	if name in scope.symbols {
		rep := report.error(span, "redefinition of global '%s'", name)
		report.add_note(rep, scope.symbols[name], "previously defined here")
	} else {
		scope.symbols[name] = span
	}
}

add_local :: proc(name: string, span: p.Span) {
	assert(len(scope_stack) > 0, "local in top level")

	if name in scope.symbols {
		rep := report.error(span, "redefinition of local '%s'", name)
		report.add_note(rep, scope.symbols[name], "previously defined here")
	} else {
		scope.symbols[name] = span
	}
}

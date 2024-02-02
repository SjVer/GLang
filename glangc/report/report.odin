package glangc_report

import "core:fmt"
import "core:os"
import "core:runtime"
import "core:sort"

Report_Type :: enum {
	Note,
	Warning,
	Error,
	Fatal,
	COUNT,
}

Report :: struct {
	loc:     runtime.Source_Code_Location,
	type:    Report_Type,
	message: string,
	span:    Maybe(Span),
	related: [dynamic]Report,
}

reports: [dynamic]Report

sort_reports :: proc() {
	// filter out multiple reports on the same span
	spans: map[Span]bool
	for r, i in reports {
		if span, ok := r.span.?; ok {
			if span in spans do unordered_remove(&reports, i)
			else do spans[span] = true
		}
	}

	sort.sort(SORT_INTERFACE)
}

has_error :: proc() -> bool {
	for r in reports {
		if r.type == .Error do return true
	}
	return false
}

// the returned report is not owned by the caller!
make :: proc(
	type: Report_Type,
	span: Maybe(Span),
	msg: string,
	args: ..any,
	loc := #caller_location,
) -> ^Report {
	rep := Report {
		loc = loc,
		type = type,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {},
	}
	append(&reports, rep)
	return &reports[len(reports) - 1]
}

note :: proc(
	span: Maybe(Span),
	msg: string,
	args: ..any,
	loc := #caller_location,
) -> ^Report {
	return make(.Note, span, msg, ..args, loc = loc)
}
warning :: proc(
	span: Maybe(Span),
	msg: string,
	args: ..any,
	loc := #caller_location,
) -> ^Report {
	return make(.Warning, span, msg, ..args, loc = loc)
}
error :: proc(
	span: Maybe(Span),
	msg: string,
	args: ..any,
	loc := #caller_location,
) -> ^Report {
	return make(.Error, span, msg, ..args, loc = loc)
}

fatal :: proc(msg: string, args: ..any, exit := true, loc := #caller_location) {
	rep := Report {
		loc = loc,
		type = .Fatal,
		message = fmt.aprintf(msg, ..args),
		span = nil,
		related = {},
	}
	render(rep)
	if exit do os.exit(1)
}

add_note :: proc(
	report: ^Report,
	span: Maybe(Span),
	msg: string,
	args: ..any,
	loc := #caller_location,
) {
	rep := Report {
		loc = loc,
		type = .Note,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {},
	}
	append(&report.related, rep)
}

package glangc_report

import "core:fmt"
import "core:sort"
import "core:os"

Report_Type :: enum {
	Note,
	Warning,
	Error,
	Fatal,
	COUNT,
}

Report :: struct {
	type:    Report_Type,
	message: string,
	span:    Maybe(Span),
	related: [dynamic]Report,
}

reports: [dynamic]Report

sort_reports :: proc() {
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
) -> ^Report {
	rep := Report {
		type = type,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {},
	}
	append(&reports, rep)
	return &reports[len(reports) - 1]
}

note :: proc(span: Maybe(Span), msg: string, args: ..any) -> ^Report {
	return make(.Note, span, msg, ..args)
}
warning :: proc(span: Maybe(Span), msg: string, args: ..any) -> ^Report {
	return make(.Warning, span, msg, ..args)
}
error :: proc(span: Maybe(Span), msg: string, args: ..any) -> ^Report {
	return make(.Error, span, msg, ..args)
}

fatal :: proc(msg: string, args: ..any) {
	rep := Report{
		type = .Fatal,
		message = fmt.aprintf(msg, ..args),
		span = nil,
		related = {},
	}
	render(rep)
	os.exit(1)
}

add_note :: proc(
	report: ^Report,
	span: Maybe(Span),
	msg: string,
	args: ..any,
) {
	rep := Report {
		type = .Note,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {},
	}
	append(&report.related, rep)
}

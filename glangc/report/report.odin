package glangc_report

import "core:fmt"

Pos :: struct {
	file:   string,
	offset: int, // starting at 0
	line:   int, // starting at 1
	column: int, // starting at 1
}

Span :: struct {
	start, end: Pos,
}

span_of_pos :: proc(pos: Pos, length := 0) -> Span {
	end := pos
	end.column += length
	end.offset += length
	return Span{pos, end}
}

Report_Type :: enum {
	Note,
	Warning,
	Error,
	COUNT
}

Report :: struct {
	type:    Report_Type,
	message: string,
	span:    Maybe(Span),
	related: [dynamic]Report,
}

make :: proc(type: Report_Type, span: Maybe(Span), msg: string, args: ..any) -> Report {
	return Report{
		type = type,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {}
	}
}
note :: proc(span: Maybe(Span), msg: string, args: ..any) -> Report {
	return make(.Note, span, msg, ..args)
}
warning :: proc(span: Maybe(Span), msg: string, args: ..any) -> Report {
	return make(.Warning, span, msg, ..args)
}
error :: proc(span: Maybe(Span), msg: string, args: ..any) -> Report {
	return make(.Error, span, msg, ..args)
}

add_note :: proc(report: ^Report, span: Maybe(Span), msg: string, args: ..any) {
	append(&report.related, note(span, msg, ..args))
}

dispatch_error_at_span :: proc(span: Span, msg: string, args: ..any) {
	dispatch(Report{
		type = .Error,
		message = fmt.aprintf(msg, ..args),
		span = span,
		related = {}
	})
}

dispatch_simple_note :: proc(msg: string, args: ..any) {
	dispatch(Report{
		type = .Note,
		message = fmt.aprintf(msg, ..args),
		span = nil,
		related = {}
	})
}
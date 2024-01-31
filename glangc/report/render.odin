package glangc_report

import "core:fmt"
import "core:os"

RESET :: "\x1b[0m"
BOLD_CYAN :: "\x1b[1;36m"
BOLD_RED :: "\x1b[1;31m"
BOLD_YELLOW :: "\x1b[1;33m"
BOLD_WHITE :: "\x1b[1;37m"
BOLD_GREY :: "\x1b[1;90m"

REPORT_TYPE_COLORS := [Report_Type.COUNT]string {
	BOLD_CYAN,
	BOLD_YELLOW,
	BOLD_RED,
	BOLD_RED,
}
REPORT_TYPE_NAMES := [Report_Type.COUNT]string {
	"note",
	"warning",
	"error",
	"fatal",
}

handle := os.stderr

@(private)
has_reported := false

render_header :: proc(type: Report_Type, message: string) {
	fmt.fprintf(
		handle,
		"%s%s%s: %s%s",
		REPORT_TYPE_COLORS[type],
		REPORT_TYPE_NAMES[type],
		BOLD_WHITE,
		message,
		RESET,
	)
	fmt.fprintln(handle)
}

render_span :: proc(type: Report_Type, span: Span) {
	fmt.fprintf(
		handle,
		" -> " + BOLD_CYAN + "%s" + RESET,
		span_to_string(span),
	)
	fmt.fprintln(handle)
}

render_related :: proc(report: Report) {
	render_header(report.type, report.message)
	if span, ok := report.span.?; ok do render_span(report.type, span)
}

render :: proc(report: Report) {
	if has_reported do fmt.fprintln(handle)
	else do has_reported = true

	render_header(report.type, report.message)
	if span, ok := report.span.?; ok do render_span(report.type, span)

	for r in report.related do render_related(r)
}

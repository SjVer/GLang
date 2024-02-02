package glangc_report

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

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

@(private)
get_lines :: proc(file: string, line: int) -> (Maybe(string), string) {
	assert(line >= 1, "invalid line number")

	// read the file
	data, ok := os.read_entire_file_from_filename(file)
	if !ok do fatal("could not open file %s", file)
	lines := strings.split_lines(string(data))

	assert(line <= len(lines), "line number too large")

	line_before: Maybe(string) = line > 1 ? lines[line - 2] : nil
	curr_line := lines[line - 1]
	// line_after: Maybe(string) = line < len(lines) ? lines[line] : nil

	return line_before, curr_line
}

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

render_span :: proc(
	type: Report_Type,
	span: Span,
	is_last := true,
	msg: Maybe(string) = nil,
) {
	if span == {} {
		fmt.fprintf(
			handle,
			" " + BOLD_CYAN + "<invalid source location> %s" + RESET,
			span_to_string(span),
		)
		fmt.fprintln(handle)
		if msg != nil do fmt.fprintln(handle, "  ", msg)
		return
	}

	fmt.fprintf(handle, " " + BOLD_CYAN + "%s" + RESET, span_to_string(span))
	fmt.fprintln(handle)

	line := span.start.line
	line_before, curr_line := get_lines(span.start.file, line)

	highlight_col := type == .Note ? BOLD_WHITE : REPORT_TYPE_COLORS[type]

	// the length of the highlighted bit
	highlight_len :=
		line == span.end.line \
		? span.end.column - span.start.column \
		: len(curr_line) - span.start.column

	// find the width of the largest lineno
	lineno_len := len(fmt.aprint(line))

	// line before
	if line_before, ok := line_before.?; ok {
		fmt.fprintf(
			handle,
			BOLD_CYAN + "  %*d │" + RESET + " %s",
			lineno_len,
			line - 1,
			line_before,
		)
		fmt.fprintln(handle)
	}
	// current line
	{
		part_before := curr_line[0:span.start.column - 1]
		highlighted_part := curr_line[span.start.column - 1:][:highlight_len]
		part_after := curr_line[span.start.column - 1 + highlight_len:]

		fmt.fprintf(
			handle,
			BOLD_CYAN + "  %*d │" + RESET + " %s%s%s" + RESET + "%s",
			lineno_len,
			line,
			part_before,
			highlight_col,
			highlighted_part,
			part_after,
		)
		fmt.fprintln(handle)
	}
	// underline
	{
		// tail
		tail, _ := strings.right_justify(
			is_last ? "╵" : "│",
			lineno_len + 2,
			" ",
		)
		defer delete(tail)
		fmt.fprintf(handle, BOLD_CYAN + "  %s" + RESET, tail)

		// column padding
		col_padding := strings.repeat(" ", span.start.column)
		defer delete(col_padding)

		// squiggly underline

		underline := strings.repeat("~", max(highlight_len - 1, 0))
		defer delete(underline)

		fmt.fprintf(handle, "%s%s^%s ", col_padding, highlight_col, underline)

		// message
		if msg, ok := msg.?; ok do fmt.fprint(handle, msg)

		fmt.fprintln(handle, RESET)
	}
	// connecting tail
	if !is_last {
		tail, _ := strings.right_justify("│", lineno_len + 2, " ")
		defer delete(tail)
		fmt.fprintf(handle, BOLD_CYAN + "  %s" + RESET, tail)
		fmt.fprintln(handle)
	}
}

render_related :: proc(report: Report, is_last: bool) {
	if span, ok := report.span.?; ok {
		render_span(report.type, span, is_last, report.message)
	} else {
		fmt.fprintf(
			handle,
			" %srelated %s" + BOLD_WHITE + ":" + RESET + " %s",
			REPORT_TYPE_COLORS[report.type],
			REPORT_TYPE_NAMES[report.type],
			report.message,
		)
		fmt.fprintln(handle)
	}
}

render :: proc(report: Report) {
	if has_reported do fmt.fprintln(handle)
	else do has_reported = true

	log.debug("report source:", report.loc)
	render_header(report.type, report.message)
	if span, ok := report.span.?; ok {
		render_span(report.type, span, len(report.related) == 0)
	}

	for r, i in report.related {
		is_last := i + 1 == len(report.related)
		render_related(r, is_last)
	}
}

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

span_to_string :: proc(span: Span, verbose := false) -> string {
	str := fmt.aprintf(
		"%s:%d:%d",
		span.start.file,
		span.start.line,
		span.start.column,
	)

	if !verbose do return str
	else {
		assert(span.start.file == span.end.file, "huh")
		return fmt.aprintf("%s-%d:%d", str, span.end.line, span.end.column)
	}
}

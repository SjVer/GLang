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

span_to_string :: proc(span: Span) -> string {
	return fmt.aprintf(
		"%s:%d:%d",
		span.start.file,
		span.start.line,
		span.start.column,
	)
}

package glangc_report

import "core:fmt"

RESET :: "\x1b[0m"
CYAN :: "\x1b[1;36m"
RED :: "\x1b[1;31m"
YELLOW :: "\x1b[1;33m"
DARK_GREY :: "\x1b[1;90m"

Pos :: struct {
	file:   string,
	offset: int, // starting at 0
	line:   int, // starting at 1
	column: int, // starting at 1
}

Span :: struct {
	start, end: Pos,
}

error_at_pos :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprint(RED + "error" + RESET + ": ")
	fmt.eprintf(msg, ..args)
	fmt.eprintln()
	fmt.eprintf(" -> " + CYAN + "%s:%d:%d" + RESET, pos.file, pos.line, pos.column)
	fmt.eprintln()
}

error_at_span :: proc(span: Span, msg: string, args: ..any) {
	// TODO: improve
	error_at_pos(span.start, msg, ..args)
}

note_at_pos :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprint(CYAN + "note" + RESET + ": ")
	fmt.eprintf(msg, ..args)
	fmt.eprintln()
	fmt.eprintf(" -> " + CYAN + "%s:%d:%d" + RESET, pos.file, pos.line, pos.column)
	fmt.eprintln()
}

note_at_span :: proc(span: Span, msg: string, args: ..any) {
	// TODO: improve
	note_at_pos(span.start, msg, ..args)
}
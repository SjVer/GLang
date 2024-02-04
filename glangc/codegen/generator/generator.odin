package glangc_codegen_generator

import c "../../common"
import t "../../typing"
import "core:fmt"
import "core:strings"

Generator :: struct {
	// filled in dynamically
	target:       c.Target,
	builder:      strings.Builder,
	indent_level: int,

	// static properties
	comment_fmt:  string,
	indent_str:   string,

	// must all be implemented
	gen_prelude:  proc(_: ^Generator),
	gen_epilogue: proc(_: ^Generator),
	gen_builtin:  proc(_: ^Generator, _: t.Builtin),
	gen_global:   proc(_: ^Generator, _: t.Global),
	gen_function: proc(_: ^Generator, _: t.Function),
}

gindent :: proc(g: ^Generator) {
	indent, _ := strings.repeat(g.indent_str, g.indent_level)
	fmt.sbprint(&g.builder, indent)
}

gprint :: proc(g: ^Generator, args: ..any) {
	fmt.sbprint(&g.builder, ..args)
}

gprintln :: proc(g: ^Generator, args: ..any) {
	fmt.sbprintln(&g.builder, ..args)
}

gprintf :: proc(g: ^Generator, msg: string, args: ..any) {
	fmt.sbprintf(&g.builder, msg, ..args)
}

gprintfln :: proc(g: ^Generator, fmt: string, args: ..any) {
	gprintf(g, fmt, ..args)
	gprintln(g)
}

gprintfcln :: proc(g: ^Generator, msg: string, args: ..any) {
	msg := fmt.aprintf(msg, ..args)
	gprintfln(g, g.comment_fmt, msg)
}

package glangc_codegen_generator

import c "../../common"
import t "../../typing"
import "core:fmt"
import "core:strings"

Generator :: struct {
	// filled in dynamically
	target:       c.Target,
	builder:      strings.Builder,

	// must all be implemented
	gen_prelude:  proc(_: ^Generator),
	gen_epilogue: proc(_: ^Generator),
	gen_builtin:  proc(_: ^Generator, _: t.Builtin),
	gen_global:   proc(_: ^Generator, _: t.Global),
	gen_function: proc(_: ^Generator, _: t.Function),
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

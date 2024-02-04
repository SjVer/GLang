package glangc_codegen_generators

import t "../../typing"
import g "../generator"

import "core:fmt"
import "core:strings"

GLSL_300_ES_GENERATOR :: g.Generator {
	comment_fmt  = "// %s",
	gen_prelude  = glsl_300_es_gen_prelude,
	gen_epilogue = glsl_300_es_gen_epilogue,
	gen_builtin  = glsl_gen_builtin,
	gen_global   = glsl_gen_global,
	gen_function = c_gen_function,
}

glsl_300_es_gen_prelude :: proc(gen: ^g.Generator) {
	g.gprintln(gen)
	g.gprintln(gen, "#version 300 es")
	
	g.gprintln(gen)
	g.gprintfcln(gen, "set precision using <TODO>")
	g.gprintln(gen, "precision mediump float")
}

glsl_300_es_gen_epilogue :: proc(gen: ^g.Generator) {
}

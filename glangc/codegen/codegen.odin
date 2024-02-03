package glangc_codegen

import "core:strings"

import "../common"
import t "../typing"

import "generator"
import "generators"

TARGET_GENERATORS: map[common.Target]generator.Generator = {
	.C = generators.C_GENERATOR,
}

gen_code :: proc(tast: t.TAST, target: common.Target) -> string {
	assert(target in TARGET_GENERATORS)
	g := TARGET_GENERATORS[target]

	// set things up
	g.target = target
	g.builder = strings.builder_make()

	// prelude
	g.gen_prelude(&g)

	// codegen for each TAST item
	for decl in tast.decls {
		switch decl in decl {
			case t.Builtin:
				g.gen_builtin(&g, decl)
			case t.Global:
				g.gen_global(&g, decl)
			case t.Function:
				g.gen_function(&g, decl)
		}
	}

	// epilogue
	g.gen_epilogue(&g)

	// clean up and return the result
	code := strings.clone(strings.to_string(g.builder))
	strings.builder_destroy(&g.builder)
	return code
}

package glangc_codegen_generators

import "../../report"
import t "../../typing"
import g "../generator"

import "core:strings"

glsl_gen_float_prec_opt :: proc(gen: ^g.Generator, leave_if_unspec: bool) {
	prec := "medium";qual := "mediump"
	if "float-precision" in gen.options {
		switch opt := gen.options["float-precision"]; opt {
			case "low":
				prec = "low"
				qual = "lowp"
			case "medium":
				prec = "medium"
				qual = "mediump"
			case "high":
				prec = "high"
				qual = "highp"
			case:
				report.error(nil, "invalid precision qualifier '%s'", opt)
		}
	} else if leave_if_unspec do return

	g.gprintln(gen)
	g.gprintfcln(gen, "-opt:float-precision:%s", prec)
	g.gprintfln(gen, "precision %s float", qual)
}

glsl_gen_builtin :: proc(gen: ^g.Generator, builtin: t.Builtin) {
	// we assume builtins are actually builtin
	switch symbol in builtin {
		case t.Symbol(t.Type):
			g.gprintfcln(
				gen,
				"builtin %s %s;",
				c_of_type(symbol.type),
				symbol.name,
			)

		case t.Symbol(t.FuncType):
			params: [dynamic]string
			for t, i in symbol.type.params do append(&params, c_of_type(t))
			params_str, _ := strings.join(params[:], ", ")

			g.gprintfcln(
				gen,
				"builtin %s %s(%s);",
				c_of_type(symbol.type.returns),
				symbol.name,
				params_str,
			)
	}
}

glsl_gen_global :: proc(gen: ^g.Generator, glob: t.Global) {
	switch glob.kind {
		case .Normal:
			break
		case .Uniform:
			g.gprint(gen, "uniform ")
	}

	g.gprintf(gen, "%s %s", c_of_type(glob.type), glob.name)

	if value, ok := glob.value.?; ok {
		value_str := c_of_expr(value)
		g.gprintfln(gen, "= %s", value_str)
	}

	g.gprintln(gen, ";")
}

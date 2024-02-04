package glangc_codegen_generators

import t "../../typing"
import g "../generator"

import "core:fmt"
import "core:strings"

C_GENERATOR :: g.Generator {
	comment_fmt  = "// %s",
	gen_prelude  = c_gen_prelude,
	gen_epilogue = c_gen_epilogue,
	gen_builtin  = c_gen_builtin,
	gen_global   = c_gen_global,
	gen_function = c_gen_function,
}

c_gen_prelude :: proc(gen: ^g.Generator) {
}

c_gen_epilogue :: proc(gen: ^g.Generator) {
}

c_gen_builtin :: proc(gen: ^g.Generator, builtin: t.Builtin) {
	switch symbol in builtin {
		case t.Symbol(t.Type):
			g.gprintfln(
				gen,
				"extern %s %s;",
				c_of_type(symbol.type),
				symbol.name,
			)

		case t.Symbol(t.FuncType):
			g.gprintf(
				gen,
				"extern %s %s(",
				c_of_type(symbol.type.returns),
				symbol.name,
			)

			for t, i in symbol.type.params {
				g.gprint(gen, c_of_type(t))
				if i + 1 != len(symbol.type.params) do g.gprint(gen, ", ")
			}
			g.gprintln(gen, ");")
	}
}

c_gen_global :: proc(gen: ^g.Generator, glob: t.Global) {
	switch glob.kind {
		case .Normal:
			break
		case .Uniform:
			g.gprint(gen, "/* uniform */ ")
	}

	g.gprintf(gen, "%s %s", c_of_type(glob.type), glob.name)

	if value, ok := glob.value.?; ok {
		value_str := c_of_expr(value)
		g.gprintfln(gen, "= %s", value_str)
	}

	g.gprintln(gen, ";")
}

c_gen_function :: proc(gen: ^g.Generator, func: t.Function) {
	g.gprintf(gen, "%s %s(", c_of_type(func.type.returns), func.name)
	for p, i in func.params {
		g.gprintf(gen, "%s %s", c_of_type(p.type^), p.name)
		if i + 1 != len(func.params) do g.gprintf(gen, ", ")
	}
	g.gprintln(gen, ") ")
	c_gen_block_stmt(gen, func.block)
}

// ============= statements =============

c_gen_stmt :: proc(gen: ^g.Generator, stmt: t.Stmt) {
	switch stmt in stmt {
		case t.Block_Stmt:
			c_gen_block_stmt(gen, stmt)
		case t.Return_Stmt:
			c_gen_return_stmt(gen, stmt)
		case t.Expr_Stmt:
			c_gen_expr_stmt(gen, stmt)
	}
}

c_gen_block_stmt :: proc(gen: ^g.Generator, block: t.Block_Stmt) {
	g.gindent(gen);g.gprintln(gen, "{")
	gen.indent_level += 1

	for stmt in block.statements {
		c_gen_stmt(gen, stmt)
	}

	gen.indent_level -= 1
	g.gindent(gen);g.gprintln(gen, "}")
}

c_gen_return_stmt :: proc(gen: ^g.Generator, stmt: t.Return_Stmt) {
	g.gindent(gen)
	g.gprint(gen, "return")

	if expr, ok := stmt.expr.?; ok {
		g.gprintf(gen, " %s", c_of_expr(expr))
	}
	g.gprintln(gen, ";")
}

c_gen_expr_stmt :: proc(gen: ^g.Generator, stmt: t.Expr_Stmt) {
	g.gindent(gen)
	g.gprintfln(gen, "%s;", c_of_expr(stmt.expr))
}

// ============= expressions =============

c_of_expr :: proc(expr: t.Expr) -> string {
	switch expr in expr {
		case t.Assign_Expr:
			return c_of_assign_expr(expr)
		case t.Binary_Expr:
			return c_of_binary_expr(expr)
		case t.Call_Expr:
			return c_of_call_expr(expr)
		case t.Cast_Expr:
			return c_of_cast_expr(expr)
		case t.Literal_Expr:
			return c_of_literal(expr)
		case t.identifier:
			return auto_cast expr
	}
	panic("invalid TAST expr")
}

c_of_assign_expr :: proc(expr: t.Assign_Expr) -> string {
	dest := c_of_expr(expr.dest^)
	src := c_of_expr(expr.expr^)

	return fmt.aprintf("%s = %s", dest, src)
}

c_of_binary_expr :: proc(expr: t.Binary_Expr) -> string {
	lhs := c_of_expr(expr.lhs^)
	rhs := c_of_expr(expr.rhs^)

	op := ""
	switch expr.op {
		case .Eq: op = "="
		case .Add: op = "+"
		case .Sub: op = "-"
		case .Mul: op = "*"
		case .Div: op = "/"
		case .And: op = "&"
		case .Or: op = "|"
		case .Xor: op = "~"
		case .Shl: op = "<<"
		case .Shr: op = ">>"
		case .Cmp_And: op = "&&"
		case .Cmp_Or: op = "||"
		case .Cmp_Eq: op = "=="
		case .Not_Eq: op = "!="
		case .Lt: op = "<"
		case .Gt: op = ">"
		case .Lt_Eq: op = "<="
		case .Gt_Eq: op = ">="
	}

	return fmt.aprintf("%s %s %s", lhs, op, rhs)
}

c_of_call_expr :: proc(expr: t.Call_Expr) -> string {
	params: [dynamic]string
	for p, i in expr.args do append(&params, c_of_expr(p))
	params_str, _ := strings.join(params[:], ", ")

	return fmt.aprintf("%s(%s)", expr.callee, params_str)
}

c_of_cast_expr :: proc(expr: t.Cast_Expr) -> string {
	return fmt.aprintf("(%s)(%s)", c_of_type(expr.type), c_of_expr(expr.expr^))
}

c_of_literal :: proc(lit: t.Literal_Expr) -> string {
	// TODO: improve
	return fmt.aprint(lit)
}

// ============= type =============

c_of_type :: proc(type: t.Type) -> string {
	switch type in type {
		case t.identifier:
			return auto_cast type
		case t.Primitive_Type:
			switch type {
				case .Integer:
					return "int"
				case .Float:
					return "float"
				case .Void:
					return "void"
			}
	}
	panic("invalid TAST type")
}

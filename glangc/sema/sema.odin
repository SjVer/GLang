package glangc_sema

import p "../parse"
import r "../report"

// ============== toplevel ==============

analyze :: proc(ast: p.AST) {
	// gather top-level symbols
	for d in ast.decls {
		name: string = ---
		span: p.Span = ---

		switch d in d {
			case p.Builtin_Type:
				add_type(d.name.text, d.span)
			case p.Global:
				add_global(d.symbol.name.text, d.symbol.span)
			case p.Function:
				add_global(d.symbol.name.text, d.symbol.span)
		}
	}

	// analyze them
	for d in ast.decls do a_decl(d)
}

a_decl :: proc(decl: p.Decl) {
	switch d in decl {
		case p.Builtin_Type:
			a_builtin_type(d)
		case p.Global:
			a_global(d)
		case p.Function:
			a_function(d)
	}
}

a_builtin_type :: proc(type: p.Builtin_Type) {
	// already checked
}

a_global :: proc(glob: p.Global) {
	a_type(glob.type)

	switch glob.kind {
		case .Builtin:
			assert(glob.value == nil, "builtin global cannot have value")

		case .Normal:
			if v, ok := glob.value.?; ok do a_expr(v)

		case .Uniform:
			assert(glob.value == nil, "uniform global cannot have value")
	}
}

a_function :: proc(func: p.Function) {
	a_function_type(func.params, func.returns, func.symbol.end)

	if block, ok := func.block.?; ok {
		// normal function

		// we analyze the block in a new scope
		// so we gather the params as well
		push_scope()

		for i in 0 ..< len(func.params) {
			name := "<anonymous>"
			if ident, ok := func.params[i].name.?; ok {
				name = ident.text
			}

			add_local(name, func.params[i].span)
		}

		a_block_stmt(block)
		pop_scope()
	}
}

// ============== statements ==============

a_stmt :: proc(stmt: p.Stmt) {
	switch s in stmt {
		case p.Block_Stmt:
			a_block_stmt(s)
		case p.Return_Stmt:
			a_return_stmt(s)
		case p.Expr_Stmt:
			a_expr(s.expr)
	}
}

a_block_stmt :: proc(stmt: p.Block_Stmt) {
	push_scope()
	for s in stmt.statements {
		a_stmt(s)
	}
	pop_scope()
}

a_return_stmt :: proc(stmt: p.Return_Stmt) {
	if expr, ok := stmt.expr.?; ok {
		a_expr(expr)
	}
}

// ============== expressions ==============

a_expr :: proc(expr: p.Expr) {
	switch e in expr {
		case p.Assign_Expr:
			a_assign_expr(e)
		case p.Binary_Expr:
			a_binary_expr(e)
		case p.Call_Expr:
			a_call_expr(e)
		case p.Literal_Expr:
			a_literal_expr(e)
		case p.Identifier:
			check_symbol_exists(e.text, e.pos)
	}
}

a_assign_expr :: proc(expr: p.Assign_Expr) {
	a_expr(expr.dest^)
	a_expr(expr.expr^)
}

a_binary_expr :: proc(expr: p.Binary_Expr) {
	a_expr(expr.lhs^)
	a_expr(expr.rhs^)
}

a_call_expr :: proc(expr: p.Call_Expr) {
	check_symbol_exists(expr.callee.text, expr.callee.pos)
	for arg in expr.args do a_expr(arg)
}

a_literal_expr :: proc(expr: p.Literal_Expr) {
	// dont need to do anything really
}

// ============== types ==============

a_function_type :: proc(
	params: [dynamic]p.Param,
	returns: Maybe(p.Type),
	end_pos: p.Pos,
) {
	for param in params do a_type(param.type)
	if returns, ok := returns.?; ok do a_type(returns)
}

a_type :: proc(type: p.Type) {
	switch t in type {
		case p.Identifier:
			check_type_exists(t.text, t.pos)
	}
}

package glangc_sema

import p "../parse"
import r "../report"
import "core:strconv"

// ============== toplevel ==============

analyze :: proc(ast: p.AST) -> Module {
	decls: [dynamic]Decl

	// gather top-level symbols
	for d in ast.decls {
		name: string = ---
		span: p.Span = ---

		switch d in d {
			case p.Builtin_Type:
				add_type(d.name.text, d.span)

			case p.Global:
				name = d.symbol.name.text
				span = d.symbol.span
				type, _ := a_type(d.type)
				// TODO: do smth if type was invalid?
				add_global(name, type, span)

			case p.Function:
				name = d.symbol.name.text
				span = d.symbol.span
				type, _ := a_function_type(d.params, d.returns, d.symbol.end)
				// TODO: do smth if type was invalid?
				add_function(name, type, span)
		}
	}

	// ananlyze them
	for d in ast.decls {
		decl, ok := a_decl(d)
		if ok && decl != nil do append(&decls, decl)
	}

	return auto_cast decls
}

a_decl :: proc(decl: p.Decl) -> (ret: Decl, ok: bool) {
	switch d in decl {
		case p.Builtin_Type:
			return a_builtin_type(d)
		case p.Global:
			return a_global(d)
		case p.Function:
			return a_function(d)
	}
	assert(false, "invalid AST decl")
	return nil, false
}

a_builtin_type :: proc(type: p.Builtin_Type) -> (ret: Decl, ok: bool) {
	// TODO: store types in module too
	return nil, true
}

a_global :: proc(glob: p.Global) -> (ret: Decl, ok: bool) {
	type := a_type(glob.type) or_return
	symbol := Symbol(Type){type, glob.symbol.name.text}

	kind: Global_Kind = ---
	value: Maybe(Expr) = nil

	switch glob.kind {
		case .Builtin:
			assert(glob.value == nil, "builtin global cannot have value")
			return cast(Builtin)symbol, true

		case .Normal:
			if v, ok := glob.value.?; ok {
				vvalue := a_expr(v) or_return
				typecheck_expr(vvalue, type, p.get_expr_span(v))
				value = vvalue
			}
			kind = .Normal

		case .Uniform:
			assert(glob.value == nil, "uniform global cannot have value")
			kind = .Uniform
	}

	return Global{symbol, kind, value}, true
}

a_function :: proc(func: p.Function) -> (ret: Decl, ok: bool) {
	type := a_function_type(
		func.params,
		func.returns,
		func.symbol.end,
	) or_return
	symbol := Symbol(FuncType){type, func.symbol.name.text}

	if block, ok := func.block.?; ok {
		// normal function

		// we analyze the block in a new scope
		// so we gather the params as well
		push_state()

		params: [dynamic]Symbol(^Type)
		for i in 0 ..< len(func.params) {
			type := &type.params[i]
			name := "<anonymous>"
			if ident, ok := func.params[i].name.?; ok {
				name = ident.text
			}

			append(&params, Symbol(^Type){type, name})
			add_local(name, type^, func.params[i].span)
		}

		block := a_block_stmt(block) or_return
		pop_state()

		return Function{symbol, params, block}, true
	} else {
		// builtin function
		return cast(Builtin)symbol, true
	}
}

// ============== statements ==============

a_stmt :: proc(stmt: p.Stmt) -> (ret: Stmt, ok: bool) {
	switch s in stmt {
		case p.Block_Stmt:
			return a_block_stmt(s)
		case p.Return_Stmt:
			return a_return_stmt(s)
		case p.Expr_Stmt:
			expr := a_expr(s.expr) or_return
			return cast(Expr_Stmt)expr, true
	}
	assert(false, "invalid AST stmt")
	return nil, false
}

a_block_stmt :: proc(stmt: p.Block_Stmt) -> (ret: Block_Stmt, ok: bool) {
	push_state()
	for s in stmt.statements {
		s := a_stmt(s) or_return
		append(&ret.statements, s)
	}
	pop_state()
	return ret, true
}

a_return_stmt :: proc(stmt: p.Return_Stmt) -> (ret: Return_Stmt, ok: bool) {
	ret.expr = nil
	if expr, ok := stmt.expr.?; ok {
		ret.expr = a_expr(expr) or_return
	}
	return ret, true
}

// ============== expressions ==============

a_expr :: proc(expr: p.Expr) -> (ret: Expr, ok: bool) {
	switch e in expr {
		case p.Assign_Expr:
			return a_assign_expr(e)
		case p.Binary_Expr:
			return a_binary_expr(e)
		case p.Call_Expr:
			return a_call_expr(e)
		case p.Literal_Expr:
			return a_literal_expr(e)
		case p.Identifier:
			check_symbol_exists(e.text, e.pos)
			return cast(identifier)e.text, true
	}
	assert(false, "invalid AST expr")
	return nil, false
}

a_assign_expr :: proc(expr: p.Assign_Expr) -> (ret: Assign_Expr, ok: bool) {
	dest := a_expr(expr.dest^) or_return
	value := a_expr(expr.expr^) or_return

	free(expr.dest)
	free(expr.expr)

	return Assign_Expr{new_clone(dest), new_clone(value)}, true
}

a_binary_expr :: proc(expr: p.Binary_Expr) -> (ret: Binary_Expr, ok: bool) {
	#partial switch expr.op {
		case .Eq:
			ret.op = .Eq
		case .Add:
			ret.op = .Add
		case .Sub:
			ret.op = .Sub
		case .Mul:
			ret.op = .Mul
		case .Div:
			ret.op = .Div
		case .And:
			ret.op = .And
		case .Or:
			ret.op = .Or
		case .Xor:
			ret.op = .Xor
		case .Shl:
			ret.op = .Shl
		case .Shr:
			ret.op = .Shr
		case .Cmp_And:
			ret.op = .Cmp_And
		case .Cmp_Or:
			ret.op = .Cmp_Or
		case .Cmp_Eq:
			ret.op = .Cmp_Eq
		case .Not_Eq:
			ret.op = .Not_Eq
		case .Lt:
			ret.op = .Lt
		case .Gt:
			ret.op = .Gt
		case .Lt_Eq:
			ret.op = .Lt_Eq
		case .Gt_Eq:
			ret.op = .Gt_Eq

		case:
			assert(false, "invalid AST binary operator")
			return {}, false
	}

	lhs := a_expr(expr.lhs^) or_return
	rhs := a_expr(expr.rhs^) or_return
	ret.lhs = new_clone(lhs)
	ret.rhs = new_clone(rhs)

	free(expr.lhs)
	free(expr.rhs)

	return ret, true
}

a_call_expr :: proc(expr: p.Call_Expr) -> (ret: Call_Expr, ok: bool) {
	check_symbol_exists(expr.callee.text, expr.callee.pos)
	ret.callee = expr.callee.text

	for arg in expr.args {
		a := a_expr(arg) or_return
		append(&ret.args, a)
	}

	return ret, true
}

a_literal_expr :: proc(expr: p.Literal_Expr) -> (ret: Literal_Expr, ok: bool) {
	#partial switch expr.kind {
		case .Char:
			char := cast(u8)expr.text[0]
			assert(0 <= char && char <= 0xff, "invalid AST char literal")
			return cast(Lit_Integer)char, true

		case .Integer:
			// TODO: determine the integer's type first
			i, ok := strconv.parse_int(expr.text)
			assert(ok, "invalid AST integer literal")
			return cast(Lit_Integer)i, true

		case .Float:
			// TODO: determine the float's type first
			f, ok := strconv.parse_f32(expr.text)
			assert(ok, "invalid AST float literal")
			return cast(Lit_Float)f, true
	}
	assert(false, "invalid AST literal expr")
	return nil, false
}

// ============== types ==============

a_function_type :: proc(
	params: [dynamic]p.Param,
	returns: Maybe(p.Type),
	end_pos: p.Pos,
) -> (
	ret: FuncType,
	ok: bool,
) {
	for param in params {
		type := a_type(param.type) or_return
		append(&ret.params, type)
	}

	if returns, ok := returns.?; ok {
		type := a_type(returns) or_return
		ret.returns = type
	} else {
		if "void" not_in types {
			rep := r.error(
				r.span_of_pos(end_pos, 0),
				"use of undefined type 'void'",
			)
			r.add_note(rep, nil, "return type is implicit")
		}
		ret.returns = cast(identifier)"void"
	}

	return ret, true
}

a_type :: proc(type: p.Type) -> (ret: Type, ok: bool) {
	switch t in type {
		case p.Identifier:
			check_type_exists(t.text, t.pos)
			return cast(identifier)t.text, true
	}

	assert(false, "invalid AST type")
	return nil, false
}

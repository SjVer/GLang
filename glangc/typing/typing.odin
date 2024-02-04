package glangc_typing

import p "../parse"
import "../report"

type_ast :: proc(ast: p.AST) -> TAST {
	decls: [dynamic]Decl

	// gather top-level symbols
	for d in ast.decls {
		name: string = ---
		span: p.Span = ---

		switch d in d {
			case p.Builtin_Type:
				// TODO: this
				type := cast(identifier)d.name.text
				add_typedef(type, type, d.span)

			case p.Global:
				name := d.symbol.name.text
				type := parse_type(d.type)
				add_symbol(name, type, d.symbol.span)

			case p.Function:
				name := d.symbol.name.text
				type := parse_function_type(d.params, d.returns)
				add_function(name, type, d.symbol.span)
		}
	}

	// ananlyze them
	for d in ast.decls {
		decl, span := type_decl(d)
		if decl != nil do append(&decls, Decl{span = span, decl = decl})
	}

	return TAST{decls = decls}
}

type_decl :: proc(decl: p.Decl) -> (_Decl, report.Span) {
	switch decl in decl {
		case p.Builtin_Type:
			// we won't need this anymore
			return nil, decl.span

		case p.Global:
			return type_global_decl(decl), decl.span

		case p.Function:
			return type_function_decl(decl), decl.span
	}

	panic("invalid AST decl")
}

type_global_decl :: proc(glob: p.Global) -> _Decl {
	symbol := Symbol(Type) {
		name = glob.symbol.name.text,
		type = parse_type(glob.type),
	}

	switch glob.kind {
		case .Builtin:
			assert(glob.value == nil, "builtin global with value")
			return cast(Builtin)symbol

		case .Uniform:
			assert(glob.value == nil, "builtin uniform global with value")
			return Global{symbol = symbol, kind = .Uniform, value = nil}

		case .Normal:
			if v, ok := glob.value.?; ok {
				value, value_type := infer_expr(v)
				unify(symbol.type, value_type, p.get_expr_span(v))
				return Global{symbol = symbol, kind = .Normal, value = value}
			}
			return Global{symbol = symbol, kind = .Normal, value = nil}
	}
	panic("invalid AST global kind")
}

type_function_decl :: proc(func: p.Function) -> _Decl {
	functype := parse_function_type(func.params, func.returns)
	symbol := Symbol(FuncType) {
		name = func.symbol.name.text,
		type = functype,
	}

	if block, ok := func.block.?; ok {
		// normal function

		// we analyze the block in a new scope
		// so we gather the params as well
		push_scope(functype.returns)

		params: [dynamic]Symbol(^Type)
		for i in 0 ..< len(func.params) {
			type := &functype.params[i]
			name := "<anonymous>"
			if ident, ok := func.params[i].name.?; ok {
				name = ident.text
			}

			append(&params, Symbol(^Type){type, name})
			add_symbol(name, type^, func.params[i].span)
		}

		block := type_block_stmt(block)
		pop_scope()

		return Function{symbol, params, block}
	} else {
		// builtin function
		return cast(Builtin)symbol
	}
}

// ============== statements ==============

type_stmt :: proc(stmt: p.Stmt) -> Stmt {
	switch stmt in stmt {
		case p.Block_Stmt:
			return type_block_stmt(stmt)
		case p.Return_Stmt:
			return type_return_stmt(stmt)
		case p.Expr_Stmt:
			return type_expr_stmt(stmt)
	}
	panic("invalid AST statement")
}

type_block_stmt :: proc(block: p.Block_Stmt) -> Block_Stmt {
	stmts: [dynamic]Stmt

	push_scope()
	for stmt in block.statements {
		append(&stmts, type_stmt(stmt))
	}
	pop_scope()

	return Block_Stmt{statements = stmts}
}

type_return_stmt :: proc(stmt: p.Return_Stmt) -> Return_Stmt {
	if expr, ok := stmt.expr.?; ok {
		e, type := infer_expr(expr)

		if ret_type := get_return_type(); ret_type != nil {
			unify(ret_type, type, p.get_expr_span(expr))
		}

		return Return_Stmt{expr = e}
	} else {
		return Return_Stmt{expr = nil}
	}
}

type_expr_stmt :: proc(stmt: p.Expr_Stmt) -> Expr_Stmt {
	expr, _ := infer_expr(stmt.expr)
	return Expr_Stmt{expr = expr}
}

// ============== types ==============

parse_function_type :: proc(
	params: [dynamic]p.Param,
	returns: Maybe(p.Type),
) -> FuncType {
	type: FuncType

	for param in params {
		append(&type.params, parse_type(param.type))
	}

	if returns, ok := returns.?; ok {
		type.returns = parse_type(returns)
	} else {
		type.returns = Primitive_Type.Void
	}

	return type
}

parse_type :: proc(type: p.Type) -> Type {
	switch type in type {
		case p.Identifier:
			return cast(identifier)type.text
	}
	panic("invalid AST type")
}

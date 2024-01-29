package glangc_parser

import "core:log"

put_in_span :: proc(pos: Pos, item: $T) -> InSpan(T) {
	return InSpan(T){start = pos, end = pos, item = item}
}

parse_file :: proc(file_path: string) -> Module {
	init_parser(file_path)

	mod := Module{}

	skip_newlines()
	for !is_at_end() {
		decl, err := parse_decl()
		if err != nil do return mod

		append(&mod.decls, decl)

		if !skip_newlines() do consume(.Semicolon)
	}

	return mod
}

parse_decl :: proc() -> (ret: Decl, err: Error) {
	if match(.Builtin) do return parse_builtin()
	if match(.Func) do return parse_func()

	error_at_curr(
		"expected a declaration, got %s",
		token_to_string(p.curr_token),
	)
	return nil, .Error
}

parse_builtin :: proc() -> (ret: Decl, err: Error) {
	start := p.prev_token.pos

	if match(.Func) {
		sig := parse_func_sig(true) or_return
        sig.start = start
        sig.block = nil
        sig.end = p.prev_token.pos

        return sig, nil
	}

	error_at_curr("expected a signature, got %s", token_to_string(p.curr_token))
	return nil, .Error
}

parse_func_sig :: proc(builtin := false) -> (sig: Function, err: Error) {
	// name
	consume(.Ident) or_return
	name := put_in_span(p.prev_token.pos, p.prev_token.text)

	// params
	consume(.Open_Paren) or_return

    params : [dynamic]Param
	for !check(.Close_Paren) {
		type := parse_type() or_return

		name: Maybe(InSpan(string)) = nil
		if builtin && match(.Ident) {
			name = put_in_span(p.prev_token.pos, p.prev_token.text)
		} else if !builtin {
			consume(.Ident) or_return
			name = put_in_span(p.prev_token.pos, p.prev_token.text)
		}

		append(&params, Param{type, name})
	}
	consume(.Close_Paren) or_return

	// return type
	returns: Maybe(Type) = nil
	if match(.Arrow) do returns = parse_type() or_return

	return Function {
        name = name,
        params = params,
        returns = returns
    }, nil
}

parse_func :: proc() -> (ret: Function, err: Error) {
	start := p.prev_token.pos

	function := parse_func_sig() or_return
    function.start = start
	function.block = parse_block_stmt() or_return
    function.end = p.prev_token.pos
    
    return function, nil
}

parse_stmt :: proc(in_block := false) -> (ret: Stmt, err: Error) {
	#partial switch p.curr_token.kind {
		case .Open_Brace:
			return parse_block_stmt()
		case .Return:
			return parse_return_stmt()
	}

	if in_block && is_at_end() do error_at_curr("expected a statement or '}'")
	else do error_at_curr("expected a statement")
	return nil, .Error
}

parse_block_stmt :: proc() -> (ret: Block_Stmt, err: Error) {
	start := (consume(.Open_Brace) or_return).pos

	statements := [dynamic]Stmt{}
	for !check(.Close_Brace) {
		stmt := parse_stmt(true) or_return
		append(&statements, stmt)
	}

	end := (consume(.Close_Brace) or_return).pos
	return Block_Stmt{start = start, end = end, statements = statements}, nil
}

parse_return_stmt :: proc() -> (ret: Return_Stmt, err: Error) {
	start := advance().pos

	expr: Maybe(Expr) = nil
	if !check(.Semicolon) {
		expr = parse_expr() or_return
	}

	consume_semicolon() or_return
	return Return_Stmt{start = start, end = p.prev_token.pos, expr = expr}, nil
}

parse_expr :: proc() -> (ret: Expr, err: Error) {
	#partial switch p.curr_token.kind {
		case .Integer, .Float:
			advance()
			return Literal_Expr {
					pos = p.prev_token.pos,
					kind = p.prev_token.kind,
				},
				nil
	}

	error_at_curr(
		"expected an expression, got %s",
		token_to_string(p.curr_token),
	)
	return nil, .Error
}

parse_type :: proc() -> (ret: Type, err: Error) {
	consume(.Ident) or_return
	type := put_in_span(p.prev_token.pos, p.prev_token.text)
	return type, nil
}

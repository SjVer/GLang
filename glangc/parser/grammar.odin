package glangc_parser

import "../common"
import "core:log"
import "core:strings"

put_in_span :: proc(pos: Pos, item: $T) -> InSpan(T) {
	return InSpan(T){start = pos, end = pos, item = item}
}

consume_newlines :: proc() {
	if !skip_newlines() && !is_at_end() {
		consume(.Semicolon)
		for !match(.Semicolon) && !is_at_end() do advance()
	}
}

parse_file :: proc(file_path: string) -> Module {
	init_parser(file_path)
	mod := Module{}
	mod.target = .Default

	skip_newlines()

	// try parsing target
	if match(.Target) {
		consume(.String)

		text := p.prev_token.text[1:len(p.prev_token.text) - 1]
		target, ok := common.parse_target(text)
		if !ok {
			error_at_pos(p.prev_token.pos, "invalid target '%s'", text)
		} else {
			mod.target = target
			log.info("target:", common.TARGET_STRINGS[target])
		}
	}

	skip_newlines()

	// parse declarations
	for !is_at_end() {
		decl, err := parse_decl()
		if err != nil do return mod

		append(&mod.decls, decl)

		consume_newlines()
	}

	return mod
}

parse_decl :: proc() -> (ret: Decl, err: Error) {
	if match(.Builtin) do return parse_builtin()
	else if match(.Func) do return parse_func()
	else if match(.Uniform) do return parse_global(.Uniform)
	else if check(.Ident) do return parse_global(.Normal)

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
	} else do return parse_global(.Builtin)

	error_at_curr(
		"expected a signature, got %s",
		token_to_string(p.curr_token),
	)
	return nil, .Error
}

parse_global :: proc(kind: Global_Kind) -> (ret: Global, err: Error) {
	ret.start = kind != .Normal ? p.prev_token.pos : p.curr_token.pos
	ret.kind = kind

	// type
	ret.type = parse_type() or_return

	// name
	consume(.Ident) or_return
	ret.name = put_in_span(p.prev_token.pos, p.prev_token.text)

	// value
	if kind != .Normal do ret.value = nil
	else do ret.value = parse_expr() or_return

	return ret, nil
}

parse_func_sig :: proc(builtin := false) -> (ret: Function, err: Error) {
	// name
	consume(.Ident) or_return
	ret.name = put_in_span(p.prev_token.pos, p.prev_token.text)

	// params
	consume(.Open_Paren) or_return

	for !check(.Close_Paren) {
		type := parse_type() or_return

		name: Maybe(InSpan(string)) = nil
		if builtin && match(.Ident) {
			name = put_in_span(p.prev_token.pos, p.prev_token.text)
		} else if !builtin {
			consume(.Ident) or_return
			name = put_in_span(p.prev_token.pos, p.prev_token.text)
		}

		append(&ret.params, Param{type, name})
	}
	consume(.Close_Paren) or_return

	// return type
	ret.returns = nil
	if match(.Arrow) do ret.returns = parse_type() or_return

	return ret, nil
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

	// g := token_to_string(p.curr_token)
	// if in_block && is_at_end() {
	//     error_at_curr("expected a statement or '}', got %s", g)
	// }
	// else do error_at_curr("expected a statement, got %s", g)
	// return nil, .Error

	expr := parse_expr(true) or_return
	return Expr_Stmt{expr = expr}, nil
}

parse_block_stmt :: proc() -> (ret: Block_Stmt, err: Error) {
	start := (consume(.Open_Brace) or_return).pos

	skip_newlines()

	statements := [dynamic]Stmt{}
	for !check(.Close_Brace) && !is_at_end() {
		stmt := parse_stmt(true) or_return
		append(&statements, stmt)

		consume_newlines()
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

parse_expr :: proc(or_stmt := false) -> (ret: Expr, err: Error) {
	return parse_binary_expr(or_stmt)
}

MAX_PRECEDENCE :: 7
get_precedence :: proc(token_kind: Token_Kind) -> int {
	#partial switch token_kind {
		case .Eq:
			return 7
		case .Question:
			return 6
		case .Cmp_Or:
			return 5
		case .Cmp_And:
			return 4
		case .Cmp_Eq, .Not_Eq, .Lt, .Gt, .Lt_Eq, .Gt_Eq:
			return 3
		case .Add, .Sub, .Or, .Xor:
			return 2
		case .Mul, .Quo, .Mod, .And, .Shl, .Shr:
			return 1
	}
	return -1
}
is_right_assoc :: proc(token_kind: Token_Kind) -> bool {
	return token_kind == .Eq || token_kind == .Question
}

parse_binary_expr :: proc(
	or_stmt := false,
	prec := MAX_PRECEDENCE,
) -> (
	expr: Expr,
	err: Error,
) {
	if prec <= 0 do return parse_unary_expr(or_stmt)

	lhs := parse_binary_expr(or_stmt, prec - 1) or_return

	for get_precedence(p.curr_token.kind) == prec {
		op := advance()

		next_prec := is_right_assoc(op.kind) ? prec : prec - 1
		rhs := parse_binary_expr(false, next_prec) or_return

		if op.kind == .Eq {
			expr := Assign_Expr{}
			expr.dest = new_clone(lhs)
			expr.expr = new_clone(rhs)
			lhs = expr
		} else {
			expr := Binary_Expr{}
			expr.op = op.kind
			expr.lhs = new_clone(lhs)
			expr.rhs = new_clone(rhs)
			lhs = expr
		}
	}

	return lhs, nil
}

parse_unary_expr :: proc(or_stmt := false) -> (ret: Expr, err: Error) {
	return parse_atom_expr(or_stmt)
}

parse_atom_expr :: proc(or_stmt := false) -> (ret: Expr, err: Error) {
	#partial switch p.curr_token.kind {
		case .Ident:
			advance()
			if check(.Open_Paren) do return parse_call()
			// else
			return Literal_Expr {
					pos = p.prev_token.pos,
					kind = p.prev_token.kind,
				},
				nil
		case .Integer, .Float:
			advance()
			return Literal_Expr {
					pos = p.prev_token.pos,
					kind = p.prev_token.kind,
				},
				nil
	}

	error_at_curr(
		"expected %s, got %s",
		or_stmt ? "a statement" : "an expression",
		token_to_string(p.curr_token),
	)
	return nil, .Error
}

parse_call :: proc() -> (ret: Call_Expr, err: Error) {
    ret.callee = put_in_span(p.prev_token.pos, p.prev_token.text)
    ret.start = p.prev_token.pos
    assert(advance().kind == .Open_Paren) // '('
    
    for !is_at_end() {
        arg := parse_expr() or_return
        append(&ret.args, arg)

        if check(.Close_Paren) do break
        else do consume(.Comma)
    }
    consume(.Close_Paren)

    ret.end = p.prev_token.pos
    return ret, nil
}

parse_type :: proc() -> (ret: Type, err: Error) {
	consume(.Ident) or_return
	type := put_in_span(p.prev_token.pos, p.prev_token.text)
	return type, nil
}

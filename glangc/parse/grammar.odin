package glangc_parser

import "core:log"
import "core:strings"

import "../common"
import "../report"

error_at_tok :: proc(tok: Token, msg: string, args: ..any) {
	span := report.span_of_pos(tok.pos, len(tok.text))
	report.error(span, msg, ..args)
}

span_to_prev_from :: proc(start: Pos) -> Span {
	end_pos := p.prev_token.pos
	end_pos.offset += len(p.prev_token.text)
	end_pos.column += len(p.prev_token.text)
	return Span{start, end_pos}
}

put_in_span :: proc(span: Span, item: $T) -> InSpan(T) {
	return InSpan(T){span, item}
}

prev_identifier :: proc() -> Identifier {
	return Identifier{p.prev_token.pos, p.prev_token.text}
}

// ============== toplevel ==============

parse_file :: proc(file_path: string) -> AST {
	init_parser(file_path)
	mod := AST{}
	mod.target = .Default

	skip_newlines()

	// try parsing target
	if match(.Target) {
		consume(.String)

		text := p.prev_token.text[1:len(p.prev_token.text) - 1]
		target, ok := common.parse_target(text)
		if !ok {
			error_at_tok(p.prev_token, "invalid target '%s'", text)
		} else {
			mod.target = target
			log.info("target:", common.TARGET_STRINGS[target])
		}
	}

	skip_newlines()

	// parse declarations
	for !is_at_end() {
		decl, ok := parse_decl()
		if !ok do return mod
		
		append(&mod.decls, decl)

		skip_newlines()
	}

	return mod
}

parse_decl :: proc() -> (ret: Decl, ok: bool) {
	if match(.Builtin) do return parse_builtin()
	else if match(.Func) do return parse_func()
	else if match(.Uniform) do return parse_global(.Uniform)
	else if check(.Ident) do return parse_global(.Normal)

	error_at_curr(
		"expected a declaration, got %s",
		token_to_string(p.curr_token),
	)
	return nil, false
}

parse_builtin :: proc() -> (ret: Decl, ok: bool) {
	start := p.prev_token.pos

	if match(.Type) {
		// builtin type
		consume(.Ident) or_return
		ident := prev_identifier()
		symbol := SymbolDecl{span_to_prev_from(start), ident}
		return cast(Builtin_Type)symbol, true
	} else if match(.Func) {
		// builtin function
		sig := parse_func_sig(true) or_return
		sig.block = nil
		sig.span = span_to_prev_from(start)

		return sig, true
	} else {
		// builtin global
		return parse_global(.Builtin)
	}

	error_at_curr(
		"expected 'type' or a signature, got %s",
		token_to_string(p.curr_token),
	)
	return nil, false
}

parse_global :: proc(kind: Global_Kind) -> (ret: Global, ok: bool) {
	start := kind != .Normal ? p.prev_token.pos : p.curr_token.pos
	ret.start = start
	ret.kind = kind

	// type
	ret.type = parse_type() or_return

	// name
	consume(.Ident) or_return
	ret.symbol.name = prev_identifier()
	ret.symbol.span = span_to_prev_from(start)

	// value
	if kind != .Normal do ret.value = nil
	else do ret.value = parse_expr() or_return

	return ret, true
}

parse_func_sig :: proc(builtin := false) -> (ret: Function, ok: bool) {
	start := builtin ? p.prev_token.pos : p.curr_token.pos

	// name
	consume(.Ident) or_return
	ret.symbol.name = prev_identifier()

	// params
	consume(.Open_Paren) or_return

	for !check(.Close_Paren) {
		start := p.curr_token.pos
		type := parse_type() or_return

		name: Maybe(Identifier) = nil
		if builtin && match(.Ident) {
			name = prev_identifier()
		} else if !builtin {
			consume(.Ident) or_return
			name = prev_identifier()
		}

		span := span_to_prev_from(start)
		append(&ret.params, Param{span, type, name})
	}
	consume(.Close_Paren) or_return

	// return type
	ret.returns = nil
	if match(.Arrow) do ret.returns = parse_type() or_return

	ret.symbol.span = span_to_prev_from(start)
	return ret, true
}

parse_func :: proc() -> (ret: Function, ok: bool) {
	start := p.prev_token.pos

	function := parse_func_sig() or_return
	function.block = parse_block_stmt() or_return
	function.span = span_to_prev_from(start)

	return function, true
}

// ============== statements ==============

parse_stmt :: proc(in_block := false) -> (ret: Stmt, ok: bool) {
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
	// return nil, false

	expr := parse_expr(true) or_return
	return Expr_Stmt{expr = expr}, true
}

parse_block_stmt :: proc() -> (ret: Block_Stmt, ok: bool) {
	start := (consume(.Open_Brace) or_return).pos

	skip_newlines()

	for !check(.Close_Brace) && !is_at_end() {
		stmt := parse_stmt(true) or_return
		append(&ret.statements, stmt)

		skip_newlines()
	}

	consume(.Close_Brace) or_return
	ret.span = span_to_prev_from(start)
	return ret, true
}

parse_return_stmt :: proc() -> (ret: Return_Stmt, ok: bool) {
	start := advance().pos

	ret.expr = nil
	if !check(.Semicolon) {
		ret.expr = parse_expr() or_return
	}
	ret.span = span_to_prev_from(start)
	
	consume_semicolon() or_return
	return ret, true
}

// ============== expressions ==============

parse_expr :: proc(or_stmt := false) -> (ret: Expr, ok: bool) {
	return parse_binary_expr(or_stmt)
}

MAX_PRECEDENCE :: 7
get_precedence :: proc(token_kind: Token_Kind) -> int {
	#partial switch token_kind {
		case .Eq:
			return 7
		// case .Question:
		// 	return 6
		case .Cmp_Or:
			return 5
		case .Cmp_And:
			return 4
		case .Cmp_Eq, .Not_Eq, .Lt, .Gt, .Lt_Eq, .Gt_Eq:
			return 3
		case .Add, .Sub, .Or, .Xor:
			return 2
		case .Mul, .Div, .And, .Shl, .Shr:
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
	ok: bool,
) {
	if prec <= 0 do return parse_unary_expr(or_stmt)

	start := p.curr_token.pos
	lhs := parse_binary_expr(or_stmt, prec - 1) or_return

	for get_precedence(p.curr_token.kind) == prec {
		op := advance()

		next_prec := is_right_assoc(op.kind) ? prec : prec - 1
		rhs := parse_binary_expr(false, next_prec) or_return

		if op.kind == .Eq {
			expr := Assign_Expr{}
			expr.dest = new_clone(lhs)
			expr.expr = new_clone(rhs)
			expr.span = span_to_prev_from(start)
			lhs = expr
		} else {
			expr := Binary_Expr{}
			expr.op = op.kind
			expr.lhs = new_clone(lhs)
			expr.rhs = new_clone(rhs)
			expr.span = span_to_prev_from(start)
			lhs = expr
		}
	}

	return lhs, true
}

parse_unary_expr :: proc(or_stmt := false) -> (ret: Expr, ok: bool) {
	return parse_atom_expr(or_stmt)
}

parse_atom_expr :: proc(or_stmt := false) -> (ret: Expr, ok: bool) {
	#partial switch p.curr_token.kind {
		case .Ident:
			advance()
			if check(.Open_Paren) do return parse_call()
			// else
			return prev_identifier(), true
		case .Char, .Integer, .Float:
			advance()
			return Literal_Expr{p.prev_token}, true
	}

	error_at_curr(
		"expected %s, got %s",
		or_stmt ? "a statement" : "an expression",
		token_to_string(p.curr_token),
	)
	return nil, false
}

parse_call :: proc() -> (ret: Call_Expr, ok: bool) {
	start := p.prev_token.pos
	ret.callee = prev_identifier()

	assert(advance().kind == .Open_Paren) // '('

	for !is_at_end() {
		arg := parse_expr() or_return
		append(&ret.args, arg)

		if check(.Close_Paren) do break
		else do consume(.Comma)
	}
	consume(.Close_Paren)

	ret.span = span_to_prev_from(start)
	return ret, true
}

// ============== types ==============

parse_type :: proc() -> (ret: Type, ok: bool) {
	consume(.Ident) or_return
	type := prev_identifier()
	return type, true
}

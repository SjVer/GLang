package glangc_parser

import "core:log"
import "core:os"

import "../report"

Parser :: struct {
	tokenizer : Tokenizer,
	prev_token: Token,
	curr_token: Token,
}

@(private)
p: Parser

init_parser :: proc(file_path: string) {
	p.prev_token = {}
	p.curr_token = {}

	// read the file
	data, success := os.read_entire_file_from_filename(file_path)
	if !success {
		log.fatalf("could not open file %s", file_path)
		os.exit(1)
	}
	source := string(data)

	init_tokenizer(&p.tokenizer, source, file_path)
	advance()
}

error_at_curr :: proc(fmt_str: string, args: ..any) {
	dispatch_error_at_tok(p.curr_token, fmt_str, ..args)
}

is_at_end :: proc() -> bool {
	return p.curr_token.kind == .EOF
}

advance :: proc() -> Token {
	if !is_at_end() {
		p.prev_token = p.curr_token
		p.curr_token = scan(&p.tokenizer)

		// TODO: for now we just skip comments
		for ; p.curr_token.kind == .Comment ; {
			p.curr_token = scan(&p.tokenizer)
		}
	}

	return p.prev_token
}

check :: proc(kind: Token_Kind) -> bool {
	return p.curr_token.kind == kind
}

match :: proc(kind: Token_Kind) -> bool {
	if check(kind) {
		advance()
		return true
	}
	return false
}

consume :: proc(kind: Token_Kind) -> (token: Token, ok: bool) {
	if !check(kind) {
		e := to_string(kind)
		g := token_to_string(p.curr_token)
		error_at_curr("expected %s, got %s", e, g)
		return {}, false
	}
	return advance(), true
}

consume_semicolon :: proc() -> (ret: Token, ok: bool) {
	if !match(.Semicolon) {
		g := token_to_string(p.curr_token)
		error_at_curr("expected newline or ';', got %s", g)
		return {}, false
	}
	return p.prev_token, true
}

// returns true if at least one newline was skipped
skip_newlines :: proc() -> bool {
	ret := false
	for is_newline(p.curr_token) {
		ret = true
		advance()
	}

	return ret
}

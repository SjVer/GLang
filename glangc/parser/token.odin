package glangc_parser

// adapted from https://github.com/odin-lang/Odin/blob/master/core/odin/tokenizer/token.odin

import "core:fmt"
import "core:strings"

import "../report"

Token :: struct {
	kind: Token_Kind,
	text: string,
	pos:  Pos,
}

Pos :: report.Pos

pos_compare :: proc(lhs, rhs: Pos) -> int {
	if lhs.offset != rhs.offset {
		return -1 if (lhs.offset < rhs.offset) else +1
	}
	if lhs.line != rhs.line {
		return -1 if (lhs.line < rhs.line) else +1
	}
	if lhs.column != rhs.column {
		return -1 if (lhs.column < rhs.column) else +1
	}
	return strings.compare(lhs.file, rhs.file)
}

Token_Kind :: enum u32 {
	Invalid,
	EOF,
	Comment,

	B_Literal_Begin,
		Ident, // main
		Integer, // 12345
		Float, // 123.45
		Char, // 'a'
		String, // "abc"
	B_Literal_End,

	B_Operator_Begin,
		Eq, // =
		Not, // !
		Question, // ?
		Add, // +
		Sub, // -
		Mul, // *
		Div, // /
		And, // &
		Or, // |
		Xor, // ~
		Shl, // <<
		Shr, // >>
		Cmp_And, // &&
		Cmp_Or, // ||
		Arrow, // ->

		B_Comparison_Begin,
			Cmp_Eq, // ==
			Not_Eq, // !=
			Lt, // <
			Gt, // >
			Lt_Eq, // <=
			Gt_Eq, // >=
		B_Comparison_End,
		
		Open_Paren, // (
		Close_Paren, // )
		Open_Bracket, // [
		Close_Bracket, // ]
		Open_Brace, // {
		Close_Brace, // }
		Colon, // :
		Semicolon, // ;
		Period, // .
		Comma, // ,
	B_Operator_End,

	B_Keyword_Begin,
		Target, // target
		Import, // import
		Uniform, // uniform
		Builtin, // builtin
		Type, // type
		If, // if
		Else, // else
		For, // for
		Break, // break
		Continue, // continue
		Return, // return
		Func, // func
		Struct, // struct
		Union, // union
		Enum, // enum
		// Cast,        // cast
		Asm, // asm
		Inline, // inline
		No_Inline, // no_inline
	B_Keyword_End,
	
	COUNT,
}

tokens := [Token_Kind.COUNT]string {
	"Invalid",
	"EOF",
	"Comment",
	"",
	"identifier",
	"integer",
	"float",
	"character",
	"string",
	"",
	"",
	"=",
	"!",
	"?",
	"+",
	"-",
	"*",
	"/",
	"&",
	"|",
	"~",
	"<<",
	">>",
	"&&",
	"||",
	"->",
	"",
	"==",
	"!=",
	"<",
	">",
	"<=",
	">=",
	"",
	"(",
	")",
	"[",
	"]",
	"{",
	"}",
	":",
	";",
	".",
	",",
	"",
	"",
	"target",
	"import",
	"uniform",
	"builtin",
	"type",
	"if",
	"else",
	"for",
	"break",
	"continue",
	"return",
	"func",
	"struct",
	"union",
	"enum",
	// "cast",
	"asm",
	"inline",
	"no_inline",
	"",
}

custom_keyword_tokens: []string

is_newline :: proc(tok: Token) -> bool {
	return tok.kind == .Semicolon && tok.text == "\n"
}

token_to_string :: proc(tok: Token) -> string {
	// if is_newline(tok) do return "newline or ';'"
	if tok.text == "\n" do return "newline"
	if tok.kind == .Ident {
		return fmt.aprintf("identifier '%s'", tok.text)
	}
	return to_string(tok.kind)
}

to_string :: proc(kind: Token_Kind) -> string {
	if kind == .Semicolon do return "newline or ';'"
	else if kind == .Invalid do return "invalid token"
	else if kind == .Comment do return "comment"
	else if kind == .EOF do return "end of file"
	else if .Invalid <= kind && kind < .B_Literal_End {
		return tokens[kind]
	} else if .Invalid <= kind && kind < .COUNT {
		return fmt.aprintf("'%s'", tokens[kind])
	}

	return "Invalid"
}

is_literal :: proc(kind: Token_Kind) -> bool {
	return .B_Literal_Begin < kind && kind < .B_Literal_End
}
is_operator :: proc(kind: Token_Kind) -> bool {
	#partial switch kind {
		case .B_Operator_Begin ..= .B_Operator_End:
			return true
		case .If:
			return true
	}
	return false
}
is_keyword :: proc(kind: Token_Kind) -> bool {
	return .B_Keyword_Begin < kind && kind < .B_Keyword_End
}

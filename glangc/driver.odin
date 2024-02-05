package glangc

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "shared:clodin"

import "codegen"
import "common"
import "parse"
import "report"
import "sema"
import "typing"

input_file := ""
verbose := false
output_file: Maybe(string) = nil
target: Maybe(common.Target) = nil
target_opts: [dynamic]string = {}

parse_cli :: proc() {
	clodin.program_name = os.args[0]
	clodin.program_description = "The official GLang compiler"
	clodin.program_version = "0.0.1"
	clodin.program_information = fmt.aprintf(
		"Written by Sjoerd Vermeulen.\n" +
		"Built for %s on %s%s.\n" +
		"See https://github.com/SjVer/GLang for more information.",
		ODIN_OS,
		ODIN_ARCH,
		" (debug)" when ODIN_DEBUG else "",
	)

	clodin.start_os_args()

	input_file = clodin.pos_string("FILE", "The input file")

	verbose = clodin.flag("verbose", "Produce verbose output")
	output_file = clodin.opt_string("out", "Sets the output file name")
	target = clodin.opt_arg(
		common.parse_target,
		"target",
		fmt.aprintf(
			"The compilation target\n" + "(derived from source by default)",
		),
	)
	target_opts = clodin.multiple_strings(
		"opt",
		"Sets a target-specific option",
	)

	// finish() exits on failure, so if it doesn't there's no failure
	if !clodin.finish() do os.exit(0)
}

parse_cli_target_opts :: proc(target: common.Target) -> map[string]string {
	opts: map[string]string = {}

	is_valid :: proc(target: common.Target, name: string) -> bool {
		for opt in target.options {
			if opt == name do return true
		}
		return false
	}

	for arg in target_opts {
		parts, _ := strings.split_n(arg, ":", 2)
		name := parts[0]

		if !is_valid(target, name) {
			report.error(nil, "invalid target option '%s'", name)
		} else if name in opts {
			report.error(nil, "duplicate target option '%s'", name)
		} else {
			if len(parts) == 1 do opts[name] = ""
			else do opts[name] = parts[1]
		}
	}

	return opts
}

check_for_errors :: proc() {
	when !ODIN_DEBUG do report.sort_reports()
	for r in report.reports do report.render(r)

	if report.has_error() {
		report.fatal(
			"could not compile '%s' due to previous error",
			input_file,
		)
	}

	clear(&report.reports)
}

main :: proc() {
	// context.logger = log.create_console_logger()
	parse_cli()

	context.logger = report.create_logger(verbose)
	when ODIN_DEBUG do log.info("running debug build")

	// frontend
	ast := parse.parse_file(input_file)
	sema.analyze(ast)
	tast := typing.type_ast(ast)

	check_for_errors()

	// check target
	the_target: common.Target = ---
	if target == nil do target = ast.target
	if target, ok := target.?; ok {
		the_target = target
	} else {
		report.fatal("no target specified")
	}

	// codegen
	opts := parse_cli_target_opts(the_target)
	code := codegen.gen_code(tast, the_target, opts)

	check_for_errors()

	log.debugf("output:\n%s", code)

	// write it
	default_filename := fmt.aprintf("out.%s", the_target.extension)
	filename := output_file.? or_else default_filename
	log.infof("writing output to '%s'", filename)
	os.write_entire_file(filename, transmute([]byte)code)
}

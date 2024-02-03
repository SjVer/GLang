package glangc

import "core:fmt"
import "core:log"
import "core:os"
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
target := common.Target.Default

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
		common.Target.Default,
		"target",
		fmt.aprintf(
			"The compilation target\n" + "(derived from source by default)",
		),
	)

	// finish() exits on failure, so if it doesn't there's no failure
	if !clodin.finish() do os.exit(0)
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

	// parse input file
	log.info("parsing", input_file)
	ast := parse.parse_file(input_file)
	log.info("parsed", input_file)

	// check target
	if target == .Default do target = ast.target
	if target == .Default {
		report.fatal("no target specified")
	}

	// do semantic analysis
	log.info("analyzing", input_file)
	sema.analyze(ast)
	log.info("analyzed", input_file)

	// do typechecking
	tast := typing.type_ast(ast)

	for d in tast.decls {
		log.debugf("\n%#v", d)
	}

	// we finally report our errors
	check_for_errors()

	// codegen
	log.info("generating code")
	code := codegen.gen_code(tast, target)
	log.info("code generated")

	log.debugf("output:\n%s", code)

	// write it
	filename := output_file.? or_else "out.txt"
	os.write_entire_file(filename, transmute([]byte)code)

	log.info("done")
}

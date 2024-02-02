package glangc

import "core:fmt"
import "core:log"
import "core:os"
import "shared:clodin"

import "common"
import "report"
import "parse"
import "sema"

input_file := ""
verbose := false
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
	if report.has_error() {
		report.sort_reports()
		for r in report.reports do report.render(r)
		report.fatal(
			"could not compile '%s' due to previous error",
			input_file,
		)
	}
}

main :: proc() {
	// context.logger = log.create_console_logger()
	parse_cli()

	context.logger = report.create_logger(verbose)
	when ODIN_DEBUG do log.info("running debug build")

	// log.info("options:")
	// log.info("\tinput file:", input_file)
	// log.info("\tverbose:", verbose)
	// log.info("\ttarget:", target)

	// parse input file
	log.info("parsing", input_file)
	ast := parse.parse_file(input_file)
	// NOTE: we do not check for errors yet
	// since we can do sema on malformed ASTs
	log.info("parsed", input_file)
	
	// check target
	if target == .Default do target = ast.target
	if target == .Default {
		report.fatal("no target specified")
	}
	
	// do semantic analysis
	log.info("analyzing", input_file)
	mod := sema.analyze(ast)
	// NOTE: we do not check for errors yet since
	// we can do typecheckign on malformed programs
	log.info("analyzed", input_file)
	
	for s in mod {
		log.debugf("\n%#v", s)
	}

	// we finally report our errors
	check_for_errors()

	log.info("done")
}

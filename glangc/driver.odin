package glangc

import "core:fmt"
import "core:log"
import "core:os"
import "shared:clodin"

import "parser"
import "report"

input_file := ""
verbose := false
target := DEFAULT_TARGET

parse_cli :: proc() {
	clodin.program_name = os.args[0]
	clodin.program_description = "The official GLang compiler"
	clodin.program_version = "0.0.1"
	clodin.program_information = fmt.aprintf(
		"Written by Sjoerd Vermeulen.\n" + 
		"Built for %s on %s%s.\n" + 
		"See <TODO> for more information.",
		ODIN_OS, ODIN_ARCH, " (debug)" when ODIN_DEBUG else "")

	clodin.start_os_args()
	
	input_file = clodin.pos_string("FILE")

	verbose = clodin.flag("verbose", "Produce verbose output")
	target = clodin.opt_arg(
		parse_target,
		DEFAULT_TARGET,
		"target",
		fmt.aprintf(
			"The compilation target (%s by default)",
			TARGET_STRINGS[DEFAULT_TARGET],
		),
	)

	// finish() exits on failure, so if it doesn't there's no failure
	if !clodin.finish() do os.exit(0)
}

main :: proc() {
	parse_cli()

	context.logger = report.create_logger(verbose)
	when ODIN_DEBUG do log.info("running debug build")

	log.info("options:")
	log.info("\tinput file:", input_file)
	log.info("\tverbose:", verbose)
	log.info("\ttarget:", target)

	log.info("parsing", input_file)
	mod := parser.parse_file(input_file)
	log.info("parsed", input_file)
	
	for p in mod.decls {
		log.debugf("\n%#v", p)
	}

	log.info("done")
}

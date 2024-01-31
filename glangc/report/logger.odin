package glangc_report

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

@(private = "file")
Level_Headers := [?]string {
	0 ..< 10 =  "DEBUG",
	10 ..< 20 = "note",
	20 ..< 30 = "warning",
	30 ..< 40 = "error",
	40 ..< 50 = "fatal error",
}

@(private = "file")
do_level_header :: proc(
	opts: log.Options,
	level: log.Level,
	str: ^strings.Builder,
) {


	col := RESET
	switch level {
		case .Debug:
			col = BOLD_GREY
		case .Info:
			col = BOLD_CYAN
		case .Warning:
			col = BOLD_YELLOW
		case .Error, .Fatal:
			col = BOLD_RED
	}

	if .Level in opts {
		if .Terminal_Color in opts {
			fmt.sbprint(str, col)
		}
		fmt.sbprint(str, Level_Headers[level])
		if .Terminal_Color in opts {
			fmt.sbprint(str, RESET)
		}
	}
}

@(private = "file")
logger_proc :: proc(
	logger_data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location := #caller_location,
) {
	// see `core:log.file_console_logger_proc` source

	handle := os.stdout if level <= .Info else os.stderr

	backing: [1024]byte
	buf := strings.builder_from_bytes(backing[:])

	when ODIN_DEBUG {
		fmt.sbprint(&buf, BOLD_GREY)
		log.do_location_header(options, &buf, location)
		fmt.sbprint(&buf, RESET)
		fmt.sbprint(&buf, strings.repeat(" ", max(0, 50 - strings.builder_len(buf))))
	}
	do_level_header(options, level, &buf)
	fmt.fprintf(handle, "%s: %s\n", strings.to_string(buf), text)

	has_reported = true
}

create_logger :: proc(verbose: bool) -> log.Logger {
	opts := log.Options{.Level, .Terminal_Color}
	when ODIN_DEBUG {
		opts = opts | log.Location_Header_Opts
		return log.Logger{logger_proc, nil, .Debug, opts}
	} else {
		level := log.Level.Info if verbose else .Warning
		return log.Logger{logger_proc, nil, level, opts}
	}
}

package glangc_common

Target :: struct {
	name:      string,
	extension: string,
}

C_TARGET :: Target {
	name      = "C",
	extension = "c",
}
GLSL_300_ES_TARGET :: Target {
	name      = "GLSL 300 es",
	extension = "glsl",
}
GLSL_410_TARGET :: Target {
	name      = "GLSL 410",
	extension = "glsl",
}

TARGETS :: [?]Target{C_TARGET, GLSL_300_ES_TARGET, GLSL_410_TARGET}

parse_target :: proc(name: string) -> (res: Target, ok: bool) {
	for target in TARGETS {
		if name == target.name do return target, true
	}
	return {}, false
}

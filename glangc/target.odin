package glangc

Target :: enum {
	GLSL_410,
}

TARGET_STRINGS: map[Target]string = {
    .GLSL_410 = "GLSL-410"
}

DEFAULT_TARGET :: Target.GLSL_410

parse_target :: proc(input: string) -> (res: Target, ok: bool) {
    for target, str in TARGET_STRINGS {
        if input == str do return target, true
    }
    return nil, false
}
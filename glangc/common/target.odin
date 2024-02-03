package glangc_common

Target :: enum {
    Default,
    C,
	GLSL_410,
}

TARGET_STRINGS: map[Target]string = {
    .Default = "default",
    .C = "C",
    .GLSL_410 = "GLSL-410",
}

parse_target :: proc(input: string) -> (res: Target, ok: bool) {
    for target, str in TARGET_STRINGS {
        if input == str do return target, true
    }
    return nil, false
}
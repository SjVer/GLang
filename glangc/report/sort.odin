//+private
package glangc_report

import "core:sort"
import "core:strings"

// we reference `reports` through `it.collection`
// but as long as we have only one collection of
// reports this isn't really necessary

it_len :: proc(it: sort.Interface) -> int {
    reps := (^[dynamic]Report)(it.collection)
    return len(reps^)
}

it_less :: proc(it: sort.Interface, a, b: int) -> bool {
    reps := (^[dynamic]Report)(it.collection)
    span_a, a_has_span := reps[a].span.?
    span_b, b_has_span := reps[b].span.?
    
    // maybe one or both dont have spans
    if !b_has_span do return a_has_span // no span > span
    else if !a_has_span do return false
    assert(a_has_span && b_has_span)
    
    // compare files
    cmp := strings.compare(span_a.start.file, span_b.start.file)
    if cmp == -1 do return true // a comes first
    if cmp == 1 do return false // b comes first
    assert(cmp == 0)
    
    // compare lines
    if span_a.start.line == span_b.start.line {
        return span_a.start.column < span_b.start.column
    } else {
        return span_a.start.line < span_b.start.line
    }
}

it_swap :: proc(it: sort.Interface, a, b: int) {
    reps := (^[dynamic]Report)(it.collection)
    reps[b], reps[a] = reps[a], reps[b]
}

SORT_INTERFACE := sort.Interface {
    len = it_len,
    less = it_less,
    swap = it_swap,
    collection = rawptr(&reports)
}

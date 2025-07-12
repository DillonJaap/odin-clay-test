package main

import clay "clay-odin"
import "core:fmt"
import "vendor:raylib"


main :: proc() {
	error_handler :: proc "c" (errorData: clay.ErrorData) {
		// Do something with the error data.
	}

	measure_text :: proc "c" (
		text: clay.StringSlice,
		config: ^clay.TextElementConfig,
		userData: rawptr,
	) -> clay.Dimensions {
		// clay.TextElementConfig contains members such as fontId, fontSize, letterSpacing, etc..
		// Note: clay.String->chars is not guaranteed to be null terminated
		return {width = f32(text.length * i32(config.fontSize)), height = f32(config.fontSize)}
	}

	// Tell clay how to measure text
	clay.SetMeasureTextFunction(measure_text, nil)

	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(arena, {1080, 720}, {handler = error_handler})
}

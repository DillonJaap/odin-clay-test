package main

import clay "clay-odin"
import "core:fmt"
import "core:mem"
import "vendor:raylib"

text_box :: proc(text: string) {
	if clay.UI()(
	{
		id = clay.ID("TextBox"),
		backgroundColor = COLOR_LIGHT,
		layout = {sizing = {width = clay.SizingGrow(), height = clay.SizingFixed(60)}},
	},
	) {
		clay.TextDynamic(text, clay.TextConfig({textColor = COLOR_BLACK, fontSize = 32}))
	}
}

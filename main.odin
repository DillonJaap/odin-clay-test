package main

import clay "clay-odin"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"
import "vendor:raylib"

windowWidth: i32 = 600
windowHeight: i32 = 900

// Define some colors.
COLOR_LIGHT :: clay.Color{224, 215, 210, 255}
COLOR_RED :: clay.Color{168, 66, 28, 255}
COLOR_ORANGE :: clay.Color{225, 138, 50, 255}
COLOR_BLACK :: clay.Color{0, 0, 0, 255}

// font IDs
FONT_ID_BODY_16 :: 0
FONT_ID_TITLE_56 :: 9
FONT_ID_TITLE_52 :: 1
FONT_ID_TITLE_48 :: 2
FONT_ID_TITLE_36 :: 3
FONT_ID_TITLE_32 :: 4
FONT_ID_BODY_36 :: 5
FONT_ID_BODY_30 :: 6
FONT_ID_BODY_28 :: 7
FONT_ID_BODY_24 :: 8

model :: struct {
	text_box:           [dynamic]rune,
	debug_mode_enabled: bool,
}


profile_picture: raylib.Texture2D = {}

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

	// Initialize clay
	{
		// initialize clay memory arena
		min_memory_size := clay.MinMemorySize()
		memory := make([^]u8, min_memory_size)
		arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)

		clay.Initialize(arena, {f32(windowWidth), f32(windowHeight)}, {handler = error_handler})
		clay.SetMeasureTextFunction(measure_text, nil)
	}

	// Intitalize raylib window
	raylib.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT, .WINDOW_UNDECORATED})
	raylib.InitWindow(windowWidth, windowHeight, "Clay Practice")
	raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(0))

	// Raylib Assets
	profile_picture = raylib.LoadTexture("resources/bingus.jpg")

	loadFont(FONT_ID_TITLE_56, 56, "resources/Calistoga-Regular.ttf")
	loadFont(FONT_ID_TITLE_52, 52, "resources/Calistoga-Regular.ttf")
	loadFont(FONT_ID_TITLE_48, 48, "resources/Calistoga-Regular.ttf")
	loadFont(FONT_ID_TITLE_36, 36, "resources/Calistoga-Regular.ttf")
	loadFont(FONT_ID_TITLE_32, 32, "resources/Calistoga-Regular.ttf")
	loadFont(FONT_ID_BODY_36, 36, "resources/Quicksand-Semibold.ttf")
	loadFont(FONT_ID_BODY_30, 30, "resources/Quicksand-Semibold.ttf")
	loadFont(FONT_ID_BODY_28, 28, "resources/Quicksand-Semibold.ttf")
	loadFont(FONT_ID_BODY_24, 24, "resources/Quicksand-Semibold.ttf")
	loadFont(FONT_ID_BODY_16, 16, "resources/Quicksand-Semibold.ttf")

	model := model{}

	// Render Loop
	for !raylib.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		// handle input 
		{
			if ((raylib.IsKeyDown(.LEFT_CONTROL) || raylib.IsKeyDown(.RIGHT_CONTROL)) &&
				   raylib.IsKeyPressed(.D)) {
				model.debug_mode_enabled = !model.debug_mode_enabled
				clay.SetDebugModeEnabled(model.debug_mode_enabled)
			} else if raylib.IsKeyPressed(.BACKSPACE) && len(model.text_box) > 0 {
				pop(&model.text_box)
			} else {
				switch ch := raylib.GetCharPressed(); ch {
				case 0:
				case:
					append(&model.text_box, ch)
				}
			}

		}

		// update clay stuff
		{
			clay.SetPointerState(
				transmute(clay.Vector2)raylib.GetMousePosition(),
				raylib.IsMouseButtonDown(raylib.MouseButton.LEFT),
			)
			clay.UpdateScrollContainers(
				false,
				transmute(clay.Vector2)raylib.GetMouseWheelMoveV(),
				raylib.GetFrameTime(),
			)
			clay.SetLayoutDimensions(
				{cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()},
			)
		}

		// raylib rendering
		{
			renderCommands: clay.ClayArray(clay.RenderCommand) = create_layout(&model)

			raylib.BeginDrawing()
			clay_raylib_render(&renderCommands)
			raylib.EndDrawing()
		}
	}
}

// Layout config is just a struct that can be declared statically, or inline
item_layout := clay.LayoutConfig {
	sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(50)},
}

// Re-useable components are just normal procs.
item_component :: proc(index: u32, input_text: string) {
	if clay.UI()(
	{id = clay.ID("SidebarBlob", index), layout = item_layout, backgroundColor = COLOR_ORANGE},
	) {
		clay.TextDynamic(input_text, clay.TextConfig({textColor = COLOR_BLACK, fontSize = 16}))
	}
}

// An example function to create your layout tree
create_layout :: proc(model: ^model) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("OuterContainer"),
		layout = {
			layoutDirection = .TopToBottom,
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			padding = {16, 16, 16, 16},
			childGap = 2,
		},
		backgroundColor = COLOR_LIGHT,
	},
	) {
		if clay.UI()(
		{
			id = clay.ID("ProfilePictureOuter"),
			layout = {
				sizing = {width = clay.SizingGrow({})},
				padding = {16, 16, 16, 16},
				childGap = 16,
				childAlignment = {y = .Center},
			},
			backgroundColor = COLOR_RED,
			cornerRadius = {6, 6, 6, 6},
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("ProfilePicture"),
				layout = {sizing = {width = clay.SizingFixed(60), height = clay.SizingFixed(60)}},
				image = {
					// How you define `profile_picture` depends on your renderer.
					imageData = &profile_picture,
				},
			},
			) {

			}

			text_input := utf8.runes_to_string(model.text_box[:], context.temp_allocator)
			text_box(text_input)
		}

		// Standard Odin code like loops, etc. work inside components.
		// Here we render 5 sidebar items.
		for i in u32(0) ..< 5 {
			item_component(i, fmt.tprintf("Hello World %v", i))
		}


		if clay.UI()(
		{
			id = clay.ID("MainContent"),
			layout = {sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})}},
			backgroundColor = COLOR_LIGHT,
		},
		) {}
	}

	return clay.EndLayout()
}

package main

import clay "clay-odin"
import "core:fmt"
import "core:mem"
import "vendor:raylib"

windowWidth: i32 = 1024
windowHeight: i32 = 768

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


	// initialize clay memory arena
	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)

	// Initialize clay
	clay.Initialize(arena, {f32(windowWidth), f32(windowHeight)}, {handler = error_handler})
	clay.SetMeasureTextFunction(measure_text, nil)


	// Intitalize raylib window
	raylib.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT})
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

	// debug mode 
	debugModeEnabled: bool = false

	// Render Loop
	for !raylib.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		windowWidth = raylib.GetScreenWidth()
		windowHeight = raylib.GetScreenHeight()

		if (raylib.IsKeyPressed(.D)) {
			debugModeEnabled = !debugModeEnabled
			clay.SetDebugModeEnabled(debugModeEnabled)
		}
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
		renderCommands: clay.ClayArray(clay.RenderCommand) = create_layout()
		raylib.BeginDrawing()
		clay_raylib_render(&renderCommands)
		raylib.EndDrawing()
	}
}

// Layout config is just a struct that can be declared statically, or inline
sidebar_item_layout := clay.LayoutConfig {
	sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(50)},
}

// Re-useable components are just normal procs.
sidebar_item_component :: proc(index: u32) {
	if clay.UI()(
	{
		id = clay.ID("SidebarBlob", index),
		layout = sidebar_item_layout,
		backgroundColor = COLOR_ORANGE,
	},
	) {
		// Do nothing rn
	}
}

// An example function to create your layout tree
create_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("OuterContainer"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			padding = {16, 16, 16, 16},
			childGap = 6,
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
					imageData = &profile_picture,
					// TODO I guess this isn't a thing, or raylib package is out of date?
					//sourceDimensions = {width = 60, height = 60}, 
				},
			},
			) {}

			clay.Text(
				"Clay - UI Library",
				clay.TextConfig({textColor = COLOR_BLACK, fontSize = 16}),
			)
		}
	}

	return clay.EndLayout()
}

loadFont :: proc(fontId: u16, fontSize: u16, path: cstring) {
	assign_at(
		&raylib_fonts,
		fontId,
		Raylib_Font {
			font = raylib.LoadFontEx(path, cast(i32)fontSize * 2, nil, 0),
			fontId = cast(u16)fontId,
		},
	)
	raylib.SetTextureFilter(raylib_fonts[fontId].font.texture, raylib.TextureFilter.TRILINEAR)
}

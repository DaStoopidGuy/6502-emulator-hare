use fmt;
use types::c;

export type Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

@symbol("InitWindow") fn InitWindow(width: int, height: int, title: const *c::char) void;
export fn init_window(width: int, height: int, title: str) void = {
	InitWindow(width, height, c::fromstr(title));
};

export @symbol("CloseWindow") fn close_window() void;
export @symbol("BeginDrawing") fn begin_drawing() void;
export @symbol("EndDrawing") fn end_drawing() void;
export @symbol("WindowShouldClose") fn window_should_close() bool;
export @symbol("GetColor") fn get_color(color: u32) Color;
export @symbol("ClearBackground") fn clear_background(color: Color) void;

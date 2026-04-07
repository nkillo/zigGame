//TODO
//  input
//      -keypresses
//      -mouse position

//  debug text
//      -import font atlas array

//  sprites
// aabb collision resolution

const std = @import("std");
const win32 = @import("win32");
const ui = win32.ui.windows_and_messaging;
const winput = win32.ui.input.keyboard_and_mouse;
const foundation = win32.foundation;
const gdi = win32.graphics.gdi;
const lib = win32.system.library_loader;
// const Random = std.Random;

const WIDTH = 800;
const HEIGHT = 600;

var up: bool = false;
var down: bool = false;
var left: bool = false;
var right: bool = false;

const vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,
};

const entity = struct {
    pos: vec2 = vec2{},
    w: i32 = 0,
    h: i32 = 0,
    min: vec2 = vec2{},
    max: vec2 = vec2{},

    dynamic: bool = true,

    color: u32 = 0,
};

var sq1: entity = entity{};
var sq2: entity = entity{};

var g_running = true;
var g_hdc_mem: gdi.HDC = undefined;
var g_bitmap: gdi.HBITMAP = undefined;

const InputType = enum(u8) {
    w,
    a,
    s,
    d,
    up,
    left,
    down,
    right,

    // We can get the count automatically
    pub const count = @typeInfo(InputType).@"enum".fields.len;
};

const Input = struct {
    // Array sizes must be known at compile time
    held: [InputType.count]u8 = [_]u8{0} ** InputType.count,
    pressed: [InputType.count]u8 = [_]u8{0} ** InputType.count,
    released: [InputType.count]u8 = [_]u8{0} ** InputType.count,

    mousex: i16 = 0,
    mousey: i16 = 0,
    mousedx: i16 = 0,
    mousedy: i16 = 0,
    wheel: i16 = 0,

    // You can add helper methods right inside the struct!
    pub fn isHeld(self: Input, key: InputType) bool {
        return self.held[@intFromEnum(key)] != 0;
    }
};
fn render(hwnd: foundation.HWND) void {
    const hdc = gdi.GetDC(hwnd);
    defer _ = gdi.ReleaseDC(hwnd, hdc);

    _ = gdi.BitBlt(hdc, 0, 0, WIDTH, HEIGHT, g_hdc_mem, 0, 0, gdi.SRCCOPY);
}

fn wndProc(hwnd: foundation.HWND, msg: u32, wp: foundation.WPARAM, lp: foundation.LPARAM) callconv(.winapi) foundation.LRESULT {
    switch (msg) {
        ui.WM_DESTROY => {
            g_running = false;
            ui.PostQuitMessage(0);
            return 0;
        },
        else => return ui.DefWindowProcA(hwnd, msg, wp, lp),
    }
}

pub fn main() !void {
    const instance = lib.GetModuleHandleA(null) orelse return error.NoInstance;
    const class_name = "GameWindow";

    const wc = ui.WNDCLASSA{
        .style = .{},
        .lpfnWndProc = wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = instance,
        .hIcon = null,
        .hCursor = ui.LoadCursorW(null, ui.IDC_ARROW),
        .hbrBackground = @ptrFromInt(6),
        .lpszMenuName = null,
        .lpszClassName = class_name,
    };
    _ = ui.RegisterClassA(&wc);

    const style = ui.WINDOW_STYLE{
        .SYSMENU = 1,
        .THICKFRAME = 1,
        .VISIBLE = 1,
    };

    var rect = foundation.RECT{ .left = 0, .top = 0, .right = WIDTH, .bottom = HEIGHT };
    _ = ui.AdjustWindowRect(&rect, style, 0);

    const hwnd = ui.CreateWindowExA(
        .{},
        class_name,
        "My Game",
        style,
        100,
        100,
        rect.right - rect.left,
        rect.bottom - rect.top,
        null,
        null,
        instance,
        null,
    ) orelse return error.CreateWindowFailed;

    // --- setup DIB ---
    const hdc = gdi.GetDC(hwnd);
    g_hdc_mem = gdi.CreateCompatibleDC(hdc);

    var bmi = gdi.BITMAPINFO{
        .bmiHeader = .{
            .biSize = @sizeOf(gdi.BITMAPINFOHEADER),
            .biWidth = WIDTH,
            .biHeight = -HEIGHT, // negative = top-down
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = gdi.BI_COMPRESSION.RGB,
            .biSizeImage = 0,
            .biXPelsPerMeter = 0,
            .biYPelsPerMeter = 0,
            .biClrUsed = 0,
            .biClrImportant = 0,
        },
        .bmiColors = undefined,
    };

    var pixels_ptr: ?*anyopaque = null;
    g_bitmap = gdi.CreateDIBSection(hdc, &bmi, gdi.DIB_RGB_COLORS, &pixels_ptr, null, 0) orelse return error.NoBitmap;
    _ = gdi.SelectObject(g_hdc_mem, g_bitmap);
    _ = gdi.ReleaseDC(hwnd, hdc);

    // point our slice at the DIB memory
    const pixel_buf: [*]u32 = @ptrCast(@alignCast(pixels_ptr.?));

    _ = ui.ShowWindow(hwnd, ui.SW_SHOW);
    // _ = ui.UpdateWindow(hwnd);

    // square position
    sq1.pos.x = 100;
    sq1.pos.y = 100;
    sq1.w = 50;
    sq1.h = 50;
    sq1.min.x = -(@divTrunc(sq1.pos.x, 2));
    sq1.min.y = -(@divTrunc(sq1.pos.y, 2));
    sq1.max.x = @divTrunc(sq1.pos.x, 2);
    sq1.max.y = @divTrunc(sq1.pos.y, 2);
    sq1.color = 0xFFFF4400;

    sq2.pos.x = 300;
    sq2.pos.y = 300;
    sq2.w = 50;
    sq2.h = 50;
    sq2.min.x = -(@divTrunc(sq2.pos.x, 2));
    sq2.min.y = -(@divTrunc(sq2.pos.y, 2));
    sq2.max.x = @divTrunc(sq2.pos.x, 2);
    sq2.max.y = @divTrunc(sq2.pos.y, 2);
    sq2.color = 0xFF44FF00;

    var msg: ui.MSG = undefined;

    // var input = Input{};

    while (g_running) {
        up = false;
        down = false;
        left = false;
        right = false;
        while (ui.PeekMessageA(&msg, null, 0, 0, ui.PM_REMOVE) != 0) {
            const VkCode = msg.wParam;
            // var wasDown = ((msg.lParam & (1 << 30)) != 0);
            // const isDown = ((msg.lParam & (1 << 31)) == 0);
            if (msg.message == ui.WM_QUIT) {
                g_running = false;
                break;
            }
            if (msg.message == ui.WM_KEYDOWN) {
                switch (VkCode) {
                    @intFromEnum(winput.VK_ESCAPE) => {
                        std.debug.print("ESCAPE PRESSED\n", .{});
                        g_running = false;
                    },
                    @intFromEnum(winput.VK_SPACE) => {
                        std.debug.print("SPACE PRESSED\n", .{});
                    },
                    @intFromEnum(winput.VK_UP) => {
                        up = true;
                    },
                    @intFromEnum(winput.VK_DOWN) => {
                        down = true;
                    },
                    @intFromEnum(winput.VK_LEFT) => {
                        left = true;
                    },
                    @intFromEnum(winput.VK_RIGHT) => {
                        right = true;
                    },
                    // You MUST have an else if you aren't switching on an enum
                    // that covers every single number
                    else => {},
                }
                std.debug.print("KEYDOWN\n", .{});
            }

            _ = ui.TranslateMessage(&msg);
            _ = ui.DispatchMessageA(&msg);
        }

        //PROCESS INPUT
        if (up) {
            sq1.pos.y -= 10;
        }
        if (down) {
            sq1.pos.y += 10;
        }
        if (left) {
            sq1.pos.x -= 10;
        }
        if (right) {
            sq1.pos.x += 10;
        }

        // --- update ---
        // sq1.pos.x += 1;
        if (sq1.pos.x > WIDTH) sq1.pos.x = 0;
        if (sq1.pos.x < 0) sq1.pos.x = WIDTH - 1;
        if (sq1.pos.y > HEIGHT) sq1.pos.y = 0;
        if (sq1.pos.y < 0) sq1.pos.y = HEIGHT - 1;

        //PHYSICS

        // --- draw ---
        // clear to dark grey
        @memset(pixel_buf[0 .. WIDTH * HEIGHT], 0xFF222222);

        // draw square — 0xAARRGGBB

        drawSquare(pixel_buf, WIDTH, HEIGHT, sq1.pos.x, sq1.pos.y, 50, 50, sq1.color);

        //draw square 2
        drawSquare(pixel_buf, WIDTH, HEIGHT, sq2.pos.x, sq2.pos.y, 50, 50, sq2.color);
        // drawSquare(pixel_buf, WIDTH, HEIGHT, sq1.pos.x - 10, sq1.pos.y + 10, 60, 50, color);
        // var j: i32 = sq1.pos.y;
        // while (j < sq1.pos.y + 50) : (j += 1) {
        //     var i: i32 = sq1.pos.x;
        //     while (i < sq1.pos.x + 50) : (i += 1) {
        //         if (i >= 0 and i < WIDTH and j >= 0 and j < HEIGHT) {
        //             pixel_buf[@intCast(j * WIDTH + i)] = color;
        //         }
        //     }
        // }

        render(hwnd);
    }
}

fn drawSquare(pixels: [*]u32, pbw: i32, pbh: i32, posx: i32, posy: i32, w: i32, h: i32, color: u32) void {
    // draw square — 0xAARRGGBB
    var y: i32 = posy;
    while (y < posy + h) : (y += 1) {
        var x: i32 = posx;
        while (x < posx + w) : (x += 1) {
            if (x >= 0 and x < pbw and y >= 0 and y < pbh) {
                pixels[@intCast(y * pbw + x)] = color;
            }
        }
    }
}

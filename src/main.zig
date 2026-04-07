const std = @import("std");
const win32 = @import("win32");
const ui = win32.ui.windows_and_messaging;
const foundation = win32.foundation;
const gdi = win32.graphics.gdi;
const lib = win32.system.library_loader;
// const Random = std.Random;

const WIDTH = 800;
const HEIGHT = 600;

var g_running = true;
var g_pixels: [WIDTH * HEIGHT]u32 = undefined; // ARGB pixels
var g_hdc_mem: gdi.HDC = undefined;
var g_bitmap: gdi.HBITMAP = undefined;

fn clearScreen(color: u32) void {
    @memset(&g_pixels, color);
}

fn drawRect(x: i32, y: i32, w: i32, h: i32, color: u32) void {
    var j: i32 = y;
    while (j < y + h) : (j += 1) {
        var i: i32 = x;
        while (i < x + w) : (i += 1) {
            if (i >= 0 and i < WIDTH and j >= 0 and j < HEIGHT) {
                g_pixels[@intCast(j * WIDTH + i)] = color;
            }
        }
    }
}

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
    var sq_x: i32 = 100;
    var sq_y: i32 = 100;
    _ = &sq_x;
    _ = &sq_y;
    var msg: ui.MSG = undefined;
    while (g_running) {
        while (ui.PeekMessageA(&msg, null, 0, 0, ui.PM_REMOVE) != 0) {
            if (msg.message == ui.WM_QUIT) {
                g_running = false;
                break;
            }
            _ = ui.TranslateMessage(&msg);
            _ = ui.DispatchMessageA(&msg);
        }

        // --- update ---
        sq_x += 1;
        if (sq_x > WIDTH) sq_x = 0;

        // --- draw ---
        // clear to dark grey
        @memset(pixel_buf[0 .. WIDTH * HEIGHT], 0xFF222222);

        // draw square — 0xAARRGGBB
        const color: u32 = 0xFFFF4400;
        var j: i32 = sq_y;
        while (j < sq_y + 50) : (j += 1) {
            var i: i32 = sq_x;
            while (i < sq_x + 50) : (i += 1) {
                if (i >= 0 and i < WIDTH and j >= 0 and j < HEIGHT) {
                    pixel_buf[@intCast(j * WIDTH + i)] = color;
                }
            }
        }

        render(hwnd);
    }
}

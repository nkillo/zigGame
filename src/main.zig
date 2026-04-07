const std = @import("std");
const win32 = @import("win32");
const ui = win32.ui.windows_and_messaging;
const foundation = win32.foundation;
const gdi = win32.graphics.gdi;
const lib = win32.system.library_loader;
// const Random = std.Random;

var g_running = true;

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
    var prng = std.Random.DefaultPrng.init(12345);
    const rand = prng.random();

    const n = rand.int(u32);
    std.debug.print("random number: {d}\n", .{n});

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
        .hbrBackground = @ptrFromInt(6), // BLACK_BRUSH
        .lpszMenuName = null,
        .lpszClassName = class_name,
    };

    _ = ui.RegisterClassA(&wc);

    const style = ui.WINDOW_STYLE{
        .SYSMENU = 1,
        .THICKFRAME = 1,
        .VISIBLE = 1,
    };

    var rect = foundation.RECT{ .left = 0, .top = 0, .right = 800, .bottom = 600 };
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

    _ = ui.ShowWindow(hwnd, ui.SW_SHOW);
    // _ = ui.UpdateWindow(hwnd);

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

        // game loop goes here
    }
}

// zig fetch --save https://github.com/marlersoft/zigwin32/archive/refs/heads/main.tar.gz

use std::io::{self, Write};

use fireterm::fireplace::Fireplace;
use fireterm::terminal::Terminal;

fn clock_now() -> u64 {
    let mut ts = libc::timespec {
        tv_sec: 0,
        tv_nsec: 0,
    };
    unsafe { libc::clock_gettime(libc::CLOCK_MONOTONIC, &mut ts) };
    ts.tv_sec as u64 * 1_000_000_000 + ts.tv_nsec as u64
}

fn main() {
    let terminal = Terminal::new();
    terminal.clear_screen();

    let (_, cols) = Terminal::size();
    let fire_width = 60.min(cols.saturating_sub(4));
    let fire_height = 20;

    let mut fireplace = Fireplace::new(fire_width, fire_height);
    let mut output_buffer: Vec<u8> = Vec::with_capacity(fire_width * fire_height * 20);

    let frame_ns: u64 = 33_000_000; // ~30 FPS

    loop {
        if terminal.key_pressed() {
            break;
        }

        let start = clock_now();

        fireplace.update();

        output_buffer.clear();
        fireplace.render(&mut output_buffer, None);

        let stdout = io::stdout();
        let mut handle = stdout.lock();
        let _ = handle.write_all(&output_buffer);
        let _ = handle.flush();

        let elapsed = clock_now().wrapping_sub(start);
        if elapsed < frame_ns {
            unsafe {
                libc::usleep(((frame_ns - elapsed) / 1000) as libc::c_uint);
            }
        }
    }

    terminal.clear_screen();
    terminal.move_to(1, 1);
}

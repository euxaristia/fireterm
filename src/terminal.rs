use std::io::{self, Write};
use std::mem::MaybeUninit;

pub struct Terminal {
    original_termios: libc::termios,
}

impl Terminal {
    pub fn new() -> Self {
        let mut original = unsafe { MaybeUninit::<libc::termios>::zeroed().assume_init() };
        unsafe { libc::tcgetattr(libc::STDIN_FILENO, &mut original) };

        let mut term = Self {
            original_termios: original,
        };
        term.enable_raw_mode();
        term.hide_cursor();
        term
    }

    fn enable_raw_mode(&mut self) {
        let mut raw = self.original_termios;
        raw.c_lflag &= !(libc::ECHO | libc::ICANON);
        raw.c_cc[libc::VMIN] = 0;
        raw.c_cc[libc::VTIME] = 0;
        unsafe { libc::tcsetattr(libc::STDIN_FILENO, libc::TCSAFLUSH, &raw) };
    }

    pub fn hide_cursor(&self) {
        print!("\x1B[?25l");
        let _ = io::stdout().flush();
    }

    pub fn show_cursor(&self) {
        print!("\x1B[?25h");
        let _ = io::stdout().flush();
    }

    pub fn move_to(&self, row: usize, col: usize) {
        print!("\x1B[{row};{col}H");
        let _ = io::stdout().flush();
    }

    pub fn clear_screen(&self) {
        print!("\x1B[2J");
        let _ = io::stdout().flush();
    }

    pub fn key_pressed(&self) -> bool {
        let mut c: u8 = 0;
        unsafe {
            libc::read(
                libc::STDIN_FILENO,
                &mut c as *mut u8 as *mut libc::c_void,
                1,
            ) == 1
        }
    }

    pub fn size() -> (usize, usize) {
        let mut w = unsafe { MaybeUninit::<libc::winsize>::zeroed().assume_init() };
        unsafe { libc::ioctl(libc::STDOUT_FILENO, libc::TIOCGWINSZ, &mut w) };
        (w.ws_row as usize, w.ws_col as usize)
    }
}

impl Default for Terminal {
    fn default() -> Self {
        Self::new()
    }
}

impl Drop for Terminal {
    fn drop(&mut self) {
        self.show_cursor();
        unsafe {
            libc::tcsetattr(libc::STDIN_FILENO, libc::TCSAFLUSH, &self.original_termios);
        }
    }
}

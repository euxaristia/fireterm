use rand::Rng;
use std::fmt::Write;

use crate::terminal::Terminal;

/// Fire palette color stop.
struct ColorStop {
    pos: f64,
    r: u8,
    g: u8,
    b: u8,
}

const STOPS: &[ColorStop] = &[
    ColorStop {
        pos: 0.0,
        r: 0,
        g: 0,
        b: 0,
    },
    ColorStop {
        pos: 0.15,
        r: 30,
        g: 0,
        b: 0,
    },
    ColorStop {
        pos: 0.3,
        r: 140,
        g: 20,
        b: 0,
    },
    ColorStop {
        pos: 0.45,
        r: 200,
        g: 60,
        b: 0,
    },
    ColorStop {
        pos: 0.6,
        r: 240,
        g: 130,
        b: 20,
    },
    ColorStop {
        pos: 0.75,
        r: 255,
        g: 200,
        b: 60,
    },
    ColorStop {
        pos: 0.88,
        r: 255,
        g: 240,
        b: 150,
    },
    ColorStop {
        pos: 1.0,
        r: 255,
        g: 255,
        b: 220,
    },
];

const PALETTE_SIZE: usize = 64;
const FLAME_CHARS: &[u8] = b" .:*sS#%&@";

fn build_palette() -> Vec<(u8, u8, u8)> {
    let mut colors = Vec::with_capacity(PALETTE_SIZE);
    for i in 0..PALETTE_SIZE {
        let t = i as f64 / (PALETTE_SIZE - 1) as f64;
        let mut seg = 0;
        for (s, stop) in STOPS.iter().enumerate().take(STOPS.len() - 1) {
            if t >= stop.pos {
                seg = s;
            }
        }
        let s0 = &STOPS[seg];
        let s1 = &STOPS[seg + 1];
        let local_t = (t - s0.pos) / (s1.pos - s0.pos);
        let r = (s0.r as f64 + local_t * (s1.r as f64 - s0.r as f64)).clamp(0.0, 255.0) as u8;
        let g = (s0.g as f64 + local_t * (s1.g as f64 - s0.g as f64)).clamp(0.0, 255.0) as u8;
        let b = (s0.b as f64 + local_t * (s1.b as f64 - s0.b as f64)).clamp(0.0, 255.0) as u8;
        colors.push((r, g, b));
    }
    colors
}

pub struct Fireplace {
    pub width: usize,
    pub height: usize,
    heat: Vec<Vec<f64>>,
    palette: Vec<(u8, u8, u8)>,
}

impl Fireplace {
    pub fn new(width: usize, height: usize) -> Self {
        let heat = vec![vec![0.0; width]; height + 2];
        Self {
            width,
            height,
            heat,
            palette: build_palette(),
        }
    }

    pub fn update(&mut self) {
        let mut rng = rand::rng();

        // Seed bottom two rows with random heat (fuel source)
        for y in self.height..(self.height + 2) {
            for x in 0..self.width {
                let center_dist =
                    (x as f64 - self.width as f64 / 2.0).abs() / (self.width as f64 / 2.0).max(1.0);
                let edge_falloff = (1.0 - center_dist * center_dist).max(0.0);
                let base = 0.6 + 0.4 * edge_falloff;
                self.heat[y][x] = base * rng.random_range(0.7..=1.0);
            }
        }

        // Propagate heat upward with cooling, spread, and turbulence
        let mut new_heat = self.heat.clone();
        for (y, new_row) in new_heat.iter_mut().enumerate().take(self.height) {
            let below = y + 1;
            let below2 = (y + 2).min(self.height + 1);

            for (x, cell) in new_row.iter_mut().enumerate().take(self.width) {
                let mut sum = self.heat[below][x] * 3.0;
                sum += self.heat[below2][x] * 2.0;
                if x > 0 {
                    sum += self.heat[below][x - 1];
                }
                if x < self.width - 1 {
                    sum += self.heat[below][x + 1];
                }
                if x > 0 {
                    sum += self.heat[below2][x - 1] * 0.5;
                }
                if x < self.width - 1 {
                    sum += self.heat[below2][x + 1] * 0.5;
                }
                sum /= 8.0;

                // Cooling factor -- more cooling at the top
                let height_ratio = 1.0 - y as f64 / self.height.max(1) as f64;
                let cooling = 0.92 - (1.0 - height_ratio) * 0.06;
                sum *= cooling;

                // Turbulence
                sum += rng.random_range(-0.03..=0.03);

                *cell = sum.clamp(0.0, 1.0);
            }
        }
        self.heat = new_heat;
    }

    pub fn render(&self, buffer: &mut Vec<u8>, terminal_size: Option<(usize, usize)>) {
        let (term_rows, term_cols) = terminal_size.unwrap_or_else(Terminal::size);
        if term_cols == 0 || term_rows == 0 {
            return;
        }

        let visible_width = self.width.min(term_cols.saturating_sub(2));
        if visible_width == 0 {
            return;
        }

        let start_col = ((term_cols - visible_width) / 2 + 1).max(1);
        let total_height = self.height + 7;
        let start_row = ((term_rows.saturating_sub(total_height)) / 2 + 1).max(1);

        // We use a String as scratch buffer to build escape sequences, then push to buffer
        let mut scratch = String::new();

        // Clear screen
        buffer.extend_from_slice(b"\x1B[2J");

        let mut row = start_row;

        // Title
        let title = "  F I R E T E R M  ";
        let title_col = ((term_cols.saturating_sub(title.len())) / 2 + 1).max(1);
        write!(scratch, "\x1B[{row};{title_col}H").unwrap();
        buffer.extend_from_slice(scratch.as_bytes());
        scratch.clear();
        buffer.extend_from_slice(b"\x1B[38;2;255;160;40m");
        buffer.extend_from_slice(title.as_bytes());
        buffer.extend_from_slice(b"\x1B[0m");
        row += 2;

        // Fire
        let mut prev_r: i16 = -1;
        let mut prev_g: i16 = -1;
        let mut prev_b: i16 = -1;

        for y in 0..self.height {
            write!(scratch, "\x1B[{row};{start_col}H").unwrap();
            buffer.extend_from_slice(scratch.as_bytes());
            scratch.clear();

            for x in 0..visible_width {
                let h = self.heat[y][x];
                let idx = (h * (self.palette.len() - 1) as f64) as usize;
                let idx = idx.min(self.palette.len() - 1);
                let (r, g, b) = self.palette[idx];

                if r as i16 != prev_r || g as i16 != prev_g || b as i16 != prev_b {
                    write!(scratch, "\x1B[38;2;{r};{g};{b}m").unwrap();
                    buffer.extend_from_slice(scratch.as_bytes());
                    scratch.clear();
                    prev_r = r as i16;
                    prev_g = g as i16;
                    prev_b = b as i16;
                }

                let char_idx =
                    ((h * (FLAME_CHARS.len() - 1) as f64) as usize).min(FLAME_CHARS.len() - 1);
                buffer.push(FLAME_CHARS[char_idx]);
            }
            buffer.extend_from_slice(b"\x1B[0m");
            prev_r = -1;
            prev_g = -1;
            prev_b = -1;
            row += 1;
        }

        // Draw logs
        let logs = [
            "     ___============___     ",
            "   |  \\\\~~~~~~~~~~~~//  |   ",
            "   |___\\\\__________//___|   ",
        ];
        buffer.extend_from_slice(b"\x1B[38;2;139;69;19m");
        for log in &logs {
            let log_col = ((term_cols.saturating_sub(log.len())) / 2 + 1).max(1);
            write!(scratch, "\x1B[{row};{log_col}H").unwrap();
            buffer.extend_from_slice(scratch.as_bytes());
            scratch.clear();
            buffer.extend_from_slice(log.as_bytes());
            row += 1;
        }

        // Brick hearth
        buffer.extend_from_slice(b"\x1B[38;2;120;50;30m");
        let brick_count = (visible_width + 4).min(term_cols.saturating_sub(2));
        let brick_col = ((term_cols.saturating_sub(brick_count)) / 2 + 1).max(1);
        write!(scratch, "\x1B[{row};{brick_col}H").unwrap();
        buffer.extend_from_slice(scratch.as_bytes());
        scratch.clear();
        for _ in 0..brick_count {
            buffer.extend_from_slice("▄".as_bytes());
        }
        row += 2;

        // Footer
        buffer.extend_from_slice(b"\x1B[0m");
        let footer = "Press any key to exit";
        let footer_col = ((term_cols.saturating_sub(footer.len())) / 2 + 1).max(1);
        write!(scratch, "\x1B[{row};{footer_col}H").unwrap();
        buffer.extend_from_slice(scratch.as_bytes());
        scratch.clear();
        buffer.extend_from_slice(b"\x1B[38;2;100;100;100m");
        buffer.extend_from_slice(footer.as_bytes());
        buffer.extend_from_slice(b"\x1B[0m");
    }
}

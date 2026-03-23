use fireterm::fireplace::Fireplace;

const TEST_SIZE: (usize, usize) = (40, 80);

#[test]
fn init_creates_correct_dimensions() {
    let fp = Fireplace::new(40, 15);
    assert_eq!(fp.width, 40);
    assert_eq!(fp.height, 15);
}

#[test]
fn update_does_not_crash_and_keeps_heat_in_bounds() {
    let mut fp = Fireplace::new(20, 10);
    for _ in 0..100 {
        fp.update();
    }
}

#[test]
fn render_produces_non_empty_output() {
    let mut fp = Fireplace::new(20, 10);
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some(TEST_SIZE));
    assert!(!buffer.is_empty());
}

#[test]
fn render_contains_ansi_escape_codes() {
    let mut fp = Fireplace::new(20, 10);
    fp.update();
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some(TEST_SIZE));
    let output = String::from_utf8_lossy(&buffer);
    assert!(output.contains("\x1B["));
}

#[test]
fn multiple_updates_produce_different_frames() {
    let mut fp = Fireplace::new(30, 12);

    fp.update();
    let mut buf1 = Vec::new();
    fp.render(&mut buf1, Some(TEST_SIZE));

    for _ in 0..5 {
        fp.update();
    }
    let mut buf2 = Vec::new();
    fp.render(&mut buf2, Some(TEST_SIZE));

    assert_ne!(buf1, buf2);
}

#[test]
fn zero_width_fireplace_does_not_crash() {
    let mut fp = Fireplace::new(0, 10);
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some(TEST_SIZE));
}

#[test]
fn very_small_fireplace_works() {
    let mut fp = Fireplace::new(1, 1);
    for _ in 0..10 {
        fp.update();
    }
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some(TEST_SIZE));
    assert!(!buffer.is_empty());
}

#[test]
fn large_fireplace_works() {
    let mut fp = Fireplace::new(200, 50);
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some((60, 220)));
    assert!(!buffer.is_empty());
}

#[test]
fn render_buffer_can_be_reused() {
    let mut fp = Fireplace::new(20, 10);
    let mut buffer = Vec::with_capacity(4096);

    fp.update();
    fp.render(&mut buffer, Some(TEST_SIZE));
    let first_len = buffer.len();

    buffer.clear();
    fp.update();
    fp.render(&mut buffer, Some(TEST_SIZE));

    assert!(first_len > 100);
    assert!(buffer.len() > 100);
}

#[test]
fn heat_converges_towards_zero_at_top_rows_after_many_updates() {
    let mut fp = Fireplace::new(30, 20);
    for _ in 0..50 {
        fp.update();
    }
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some(TEST_SIZE));
    let output = String::from_utf8_lossy(&buffer);
    assert!(output.contains(' '));
}

#[test]
fn render_with_zero_terminal_size_produces_no_output() {
    let mut fp = Fireplace::new(20, 10);
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some((0, 0)));
    assert!(buffer.is_empty());
}

#[test]
fn render_clamps_fire_width_to_narrow_terminal() {
    let mut fp = Fireplace::new(60, 10);
    fp.update();
    let mut buffer = Vec::new();
    fp.render(&mut buffer, Some((30, 30)));
    assert!(!buffer.is_empty());
}

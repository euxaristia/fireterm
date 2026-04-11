use "collections"
use "time"

actor Main
  let _env: Env
  let _palette: Palette val
  var _fireplace: Fireplace ref
  let _rand: Rand
  var _running: Bool = true
  var _prev_rows: USize = 0
  var _prev_cols: USize = 0

  new create(env: Env) =>
    _env = env

    @term_enable_raw()
    @term_hide_cursor()
    _env.out.write("\x1B[2J")

    var rows: I32 = 24
    var cols: I32 = 80
    @term_get_size(addressof rows, addressof cols)
    let term_rows = rows.usize()
    let term_cols = cols.usize()

    _palette = Palette
    let overhead: USize = 8
    let fw: USize = if term_cols > 4 then (term_cols - 4) else 1 end
    let fh: USize = if term_rows > (overhead + 2) then (term_rows - overhead) else 4 end
    _fireplace = Fireplace(fw, fh, _palette)
    _rand = Rand(Time.nanos())
    _prev_rows = term_rows
    _prev_cols = term_cols

    _animate(term_rows, term_cols)

  fun ref _create_fireplace(term_rows: USize, term_cols: USize): Fireplace ref =>
    // overhead: 2 (title+blank) + 3 (logs) + 2 (hearth+blank) + 1 (footer) = 8
    let overhead: USize = 8
    let fire_width: USize = if term_cols > 4 then (term_cols - 4) else 1 end
    let fire_height: USize = if term_rows > (overhead + 2) then (term_rows - overhead) else 4 end
    Fireplace(fire_width, fire_height, _palette)

  be _animate(term_rows: USize, term_cols: USize) =>
    if not _running then
      _shutdown()
      return
    end

    if @term_key_pressed() != 0 then
      _running = false
      _shutdown()
      return
    end

    // Re-read terminal size each frame to handle resizes
    var rows: I32 = term_rows.i32()
    var cols: I32 = term_cols.i32()
    @term_get_size(addressof rows, addressof cols)
    let cur_rows = rows.usize()
    let cur_cols = cols.usize()

    // Recreate fireplace if terminal size changed
    if (cur_rows != _prev_rows) or (cur_cols != _prev_cols) then
      _fireplace = _create_fireplace(cur_rows, cur_cols)
      _prev_rows = cur_rows
      _prev_cols = cur_cols
      // Clear screen on resize to remove stale content
      _env.out.write("\x1B[2J")
    end

    let start = Clock.now()

    _fireplace.update(_rand)

    let output = _fireplace.render(cur_rows, cur_cols)
    @write[I32](I32(1), output.cpointer(), output.size().i32())

    let elapsed = Clock.now() - start
    let frame_ns: U64 = 33_000_000 // ~30 FPS

    if elapsed < frame_ns then
      let sleep_us = ((frame_ns - elapsed) / 1000).u32()
      @usleep(sleep_us)
    end

    _animate(cur_rows, cur_cols)

  be _shutdown() =>
    _env.out.write("\x1B[2J\x1B[1;1H")
    @term_show_cursor()
    @term_disable_raw()
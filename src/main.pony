use "collections"
use "time"

actor Main
  let _env: Env
  let _palette: Palette val
  let _fireplace: Fireplace ref
  let _rand: Rand
  var _running: Bool = true

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

    let fire_width: USize = USize(60).min(if term_cols > 4 then (term_cols - 4) else 1 end)
    let fire_height: USize = 20

    _palette = Palette
    _fireplace = Fireplace(fire_width, fire_height, _palette)
    _rand = Rand(Time.nanos())

    _animate(term_rows, term_cols)

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

    let start = Clock.now()

    _fireplace.update(_rand)

    let output = _fireplace.render(rows.usize(), cols.usize())
    @write[I32](I32(1), output.cpointer(), output.size().i32())

    let elapsed = Clock.now() - start
    let frame_ns: U64 = 33_000_000 // ~30 FPS

    if elapsed < frame_ns then
      let sleep_us = ((frame_ns - elapsed) / 1000).u32()
      @usleep(sleep_us)
    end

    _animate(term_rows, term_cols)

  be _shutdown() =>
    _env.out.write("\x1B[2J\x1B[1;1H")
    @term_show_cursor()
    @term_disable_raw()
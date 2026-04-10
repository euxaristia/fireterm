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

    // Clear screen
    _env.out.write("\x1B[2J")

    // Default terminal size (in production, read from terminal via ioctls)
    let term_rows: USize = 24
    let term_cols: USize = 80

    let fire_width: USize = 60
    let fire_height: USize = 20

    _palette = Palette
    _fireplace = Fireplace(fire_width, fire_height, _palette)
    _rand = Rand(Time.nanos())

    _animate(term_rows, term_cols)

  be _animate(term_rows: USize, term_cols: USize) =>
    if not _running then
      _env.out.write("\x1B[2J")
      _env.out.write("\x1B[1;1H")
      return
    end

    let start = Clock.now()

    _fireplace.update(_rand)

    let output = _fireplace.render(term_rows, term_cols)
    @write[I32](I32(1), output.cpointer(), output.size().i32())

    let elapsed = Clock.now() - start
    let frame_ns: U64 = 33_000_000 // ~30 FPS

    if elapsed < frame_ns then
      let sleep_us = ((frame_ns - elapsed) / 1000).u32()
      @usleep(sleep_us)
    end

    _animate(term_rows, term_cols)
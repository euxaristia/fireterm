use "collections"

class val ColorStop
  """A color stop in the fire gradient palette."""
  let pos: F64
  let r: U8
  let g: U8
  let b: U8

  new val create(pos': F64, r': U8, g': U8, b': U8) =>
    pos = pos'
    r = r'
    g = g'
    b = b'


class val Palette
  """Builds and stores a 64-color palette interpolated from color stops."""
  let _colors: Array[(U8, U8, U8)] val

  new val create() =>
    let stops = recover val [
      ColorStop(0.0, 0, 0, 0)
      ColorStop(0.15, 30, 0, 0)
      ColorStop(0.3, 140, 20, 0)
      ColorStop(0.45, 200, 60, 0)
      ColorStop(0.6, 240, 130, 20)
      ColorStop(0.75, 255, 200, 60)
      ColorStop(0.88, 255, 240, 150)
      ColorStop(1.0, 255, 255, 220)
    ] end

    let palette_size: USize = 64
    let colors = recover Array[(U8, U8, U8)].init((0, 0, 0), palette_size) end

    for i in Range(0, palette_size) do
      let t = i.f64() / (palette_size - 1).f64()

      var seg: USize = 0
      let stop_count = stops.size()
      for s in Range(0, stop_count - 1) do
        let stop = try stops(s)? else ColorStop(0.0, 0, 0, 0) end
        if t >= stop.pos then
          seg = s
        end
      end

      let s0 = try stops(seg)? else ColorStop(0.0, 0, 0, 0) end
      let s1 = try stops(seg + 1)? else ColorStop(1.0, 255, 255, 220) end
      let range = s1.pos - s0.pos
      let local_t = if range != 0 then (t - s0.pos) / range else 0 end

      let r = U8Clamp(s0.r.f64() + (local_t * (s1.r.f64() - s0.r.f64())))
      let g = U8Clamp(s0.g.f64() + (local_t * (s1.g.f64() - s0.g.f64())))
      let b = U8Clamp(s0.b.f64() + (local_t * (s1.b.f64() - s0.b.f64())))

      try
        colors(i)? = (r, g, b)
      end
    end

    _colors = consume colors

  fun apply(idx: USize): (U8, U8, U8) =>
    try
      _colors(idx)?
    else
      (0, 0, 0)
    end

  fun size(): USize =>
    _colors.size()


class Fireplace
  """Simulates and renders a fireplace animation using heat propagation."""
  let width: USize
  let height: USize
  var _heat: Array[Array[F64] val] ref
  let _palette: Palette val
  let _flame_chars: Array[U8] val

  new create(width': USize, height': USize, palette: Palette val) =>
    width = width'
    height = height'
    _palette = palette

    _flame_chars = recover val [
      U8(32)  // ' '
      U8(46)  // '.'
      U8(58)  // ':'
      U8(42)  // '*'
      U8(115) // 's'
      U8(83)  // 'S'
      U8(35)  // '#'
      U8(37)  // '%'
      U8(38)  // '&'
      U8(64)  // '@'
    ] end

    let heat = recover Array[Array[F64] val] end
    for y in Range(0, height' + 2) do
      let row = recover Array[F64].init(0.0, width') end
      heat.push(consume row)
    end
    _heat = consume heat

  fun ref update(rng: {ref apply(): F64} ref) =>
    // Seed bottom two rows with random heat (fuel source)
    for y in Range(height, height + 2) do
      try
        let heat_row = _heat(y)?
        var new_row = recover Array[F64].init(0.0, heat_row.size()) end
        for x in Range(0, width) do
          let half_w = width.f64() / 2.0
          let center_dist = (x.f64() - half_w).abs() / half_w.max(1.0)
          let edge_falloff = (1.0 - (center_dist * center_dist)).max(0.0)
          let base = 0.6 + (0.4 * edge_falloff)
          let heat_val = base * (0.7 + (rng() * 0.3))
          try
            new_row(x)? = heat_val
          end
        end
        _heat(y)? = consume new_row
      end
    end

    // Propagate heat upward with cooling, spread, and turbulence
    let new_heat = recover Array[Array[F64] val] end
    for y in Range(0, height) do
      let row = recover Array[F64].init(0.0, width) end
      for x in Range(0, width) do
        try
          let below = y + 1
          let below2 = if (y + 2) < (height + 2) then (y + 2) else (height + 1) end

          var sum = (_heat(below)?(x)?) * 3.0
          sum = sum + ((_heat(below2)?(x)?) * 2.0)

          if x > 0 then
            sum = sum + _heat(below)?(x - 1)?
          end
          if x < (width - 1) then
            sum = sum + _heat(below)?(x + 1)?
          end
          if x > 0 then
            sum = sum + ((_heat(below2)?(x - 1)?) * 0.5)
          end
          if x < (width - 1) then
            sum = sum + ((_heat(below2)?(x + 1)?) * 0.5)
          end
          sum = sum / 8.0

          // Cooling factor -- more cooling at the top
          let height_ratio = 1.0 - (y.f64() / height.max(1).f64())
          let cooling = 0.92 - ((1.0 - height_ratio) * 0.06)
          sum = sum * cooling

          // Turbulence
          sum = sum + (-0.03 + (rng() * 0.06))

          try
            row(x)? = sum.max(0.0).min(1.0)
          end
        end
      end
      new_heat.push(consume row)
    end

    // Preserve the two fuel rows at the bottom
    for y in Range(height, height + 2) do
      try
        new_heat.push(_heat(y)?)
      else
        new_heat.push(recover Array[F64].init(0.0, width) end)
      end
    end

    _heat = consume new_heat

  fun ref render(term_rows: USize, term_cols: USize): String ref =>
    _render_inner(term_rows, term_cols)

  fun ref _render_inner(term_rows: USize, term_cols: USize): String ref =>
    let buf = String

    if (term_cols == 0) or (term_rows == 0) then
      return consume buf
    end

    let visible_width = width.min(if term_cols > 2 then (term_cols - 2) else 0 end)
    if visible_width == 0 then
      return consume buf
    end

    let start_col = (((term_cols - visible_width) / 2) + 1).max(1)
    let total_height = height + 7
    let start_row = (((if term_rows > total_height then (term_rows - total_height) else 0 end) / 2) + 1).max(1)

    // Clear screen
    buf.append("\x1B[2J")

    var row = start_row

    // Title
    let title = "  F I R E T E R M  "
    let title_len: USize = 19
    let title_col = (((if term_cols > title_len then (term_cols - title_len) else 0 end) / 2) + 1).max(1)
    _cursor_to(buf, row, title_col)
    buf.append("\x1B[38;2;255;160;40m")
    buf.append(title)
    buf.append("\x1B[0m")
    row = row + 2

    // Fire
    var prev_r: I16 = -1
    var prev_g: I16 = -1
    var prev_b: I16 = -1

    for y in Range(0, height) do
      try
        _cursor_to(buf, row, start_col)

        for x in Range(0, visible_width) do
          let h = _heat(y)?(x)?
          let idx = (h * (_palette.size() - 1).f64()).usize()
          let rgb = _palette(idx.min(_palette.size() - 1))
          let r = rgb._1
          let g = rgb._2
          let b = rgb._3

          if (r.i16() != prev_r) or (g.i16() != prev_g) or (b.i16() != prev_b) then
            buf.append("\x1B[38;2;")
            buf.append(r.string())
            buf.push(';')
            buf.append(g.string())
            buf.push(';')
            buf.append(b.string())
            buf.push('m')
            prev_r = r.i16()
            prev_g = g.i16()
            prev_b = b.i16()
          end

          let char_idx = (h * (_flame_chars.size() - 1).f64()).usize()
          try
            buf.push(_flame_chars(char_idx.min(_flame_chars.size() - 1))?)
          end
        end
      end
      buf.append("\x1B[0m")
      prev_r = -1
      prev_g = -1
      prev_b = -1
      row = row + 1
    end

    // Draw logs
    buf.append("\x1B[38;2;139;69;19m")
    let log_lines = recover val [
      "     ___============___     "
      "   |  \\\\~~~~~~~~~~~~//  |   "
      "   |___\\\\__________//___|   "
    ] end

    for log_line in log_lines.values() do
      let log_len = log_line.size()
      let log_col = (((if term_cols > log_len then (term_cols - log_len) else 0 end) / 2) + 1).max(1)
      _cursor_to(buf, row, log_col)
      buf.append(log_line)
      row = row + 1
    end

    // Brick hearth
    buf.append("\x1B[38;2;120;50;30m")
    let brick_count = (visible_width + 4).min(if term_cols > 2 then (term_cols - 2) else 0 end)
    let brick_col = (((if term_cols > brick_count then (term_cols - brick_count) else 0 end) / 2) + 1).max(1)
    _cursor_to(buf, row, brick_col)
    for _ in Range(0, brick_count) do
      buf.append("\u2584")
    end
    row = row + 2

    // Footer
    buf.append("\x1B[0m")
    let footer = "Press any key to exit"
    let footer_len = footer.size()
    let footer_col = (((if term_cols > footer_len then (term_cols - footer_len) else 0 end) / 2) + 1).max(1)
    _cursor_to(buf, row, footer_col)
    buf.append("\x1B[38;2;100;100;100m")
    buf.append(footer)
    buf.append("\x1B[0m")

    consume buf

  fun ref _cursor_to(buf: String ref, row: USize, col: USize) =>
    buf.append("\x1B[")
    buf.append(row.string())
    buf.push(';')
    buf.append(col.string())
    buf.push('H')
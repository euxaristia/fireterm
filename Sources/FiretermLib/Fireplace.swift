public struct Fireplace: Sendable {
    // Fire dimensions
    public let width: Int
    public let height: Int

    // Heat buffer: two rows of extra space at bottom for fuel
    private var heat: [[Double]]
    private var tick: UInt64 = 0

    // Flame characters by intensity (low -> high)
    private let flameChars: [Character] = [" ", ".", ":", "*", "s", "S", "#", "%", "&", "@"]

    // ANSI true-color fire palette (black -> red -> orange -> yellow -> white)
    private let palette: [(r: Int, g: Int, b: Int)] = {
        let stops: [(pos: Double, r: Int, g: Int, b: Int)] = [
            (0.0,   0,   0,   0),    // black
            (0.15, 30,   0,   0),    // dark ember
            (0.3, 140,  20,   0),    // deep red
            (0.45, 200,  60,   0),   // red-orange
            (0.6, 240, 130,  20),    // orange
            (0.75, 255, 200,  60),   // yellow-orange
            (0.88, 255, 240, 150),   // pale yellow
            (1.0, 255, 255, 220),    // near white
        ]
        let count = 64
        var colors: [(Int, Int, Int)] = []
        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            var segIdx = 0
            for s in 0..<(stops.count - 1) {
                if t >= stops[s].pos { segIdx = s }
            }
            let s0 = stops[segIdx]
            let s1 = stops[segIdx + 1]
            let localT = (t - s0.pos) / (s1.pos - s0.pos)
            let r = Int(Double(s0.r) + localT * Double(s1.r - s0.r))
            let g = Int(Double(s0.g) + localT * Double(s1.g - s0.g))
            let b = Int(Double(s0.b) + localT * Double(s1.b - s0.b))
            colors.append((min(255, max(0, r)), min(255, max(0, g)), min(255, max(0, b))))
        }
        return colors
    }()

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        heat = Array(repeating: Array(repeating: 0.0, count: width), count: height + 2)
    }

    public mutating func update() {
        tick &+= 1

        // Seed the bottom two rows with random heat (the fuel source)
        for y in height..<(height + 2) {
            for x in 0..<width {
                // Hotter in the center, cooler at edges
                let centerDist = abs(Double(x) - Double(width) / 2.0) / (Double(width) / 2.0)
                let edgeFalloff = max(0, 1.0 - centerDist * centerDist)
                let base = 0.6 + 0.4 * edgeFalloff
                heat[y][x] = base * Double.random(in: 0.7...1.0)
            }
        }

        // Propagate heat upward with cooling, spread, and turbulence
        var newHeat = heat
        for y in 0..<height {
            for x in 0..<width {
                let below = y + 1
                let below2 = min(y + 2, height + 1)

                var sum = heat[below][x] * 3.0
                sum += heat[below2][x] * 2.0
                if x > 0 { sum += heat[below][x - 1] * 1.0 }
                if x < width - 1 { sum += heat[below][x + 1] * 1.0 }
                if x > 0 { sum += heat[below2][x - 1] * 0.5 }
                if x < width - 1 { sum += heat[below2][x + 1] * 0.5 }
                sum /= 8.0

                // Cooling factor -- more cooling at the top
                let heightRatio = 1.0 - Double(y) / Double(height)
                let cooling = 0.92 - (1.0 - heightRatio) * 0.06
                sum *= cooling

                // Turbulence
                sum += Double.random(in: -0.03...0.03)

                newHeat[y][x] = max(0, min(1, sum))
            }
        }
        heat = newHeat
    }

    public func render(into buffer: inout [UInt8], terminalSize: (rows: Int, cols: Int)? = nil) {
        let (termRows, termCols) = terminalSize ?? Terminal.size
        guard termCols > 0 && termRows > 0 else { return }

        // Clamp visible width to terminal
        let visibleWidth = min(width, termCols - 2)
        guard visibleWidth > 0 else { return }

        let startCol = max(1, (termCols - visibleWidth) / 2 + 1)
        let totalHeight = height + 7  // fire + title + logs + hearth + footer
        let startRow = max(1, (termRows - totalHeight) / 2 + 1)

        // Clear screen and reset
        append("\u{1B}[2J", to: &buffer)

        var row = startRow

        // Title
        let title = "  F I R E T E R M  "
        let titleCol = max(1, (termCols - title.count) / 2 + 1)
        moveTo(row: row, col: titleCol, buffer: &buffer)
        append("\u{1B}[38;2;255;160;40m", to: &buffer)
        append(title, to: &buffer)
        append("\u{1B}[0m", to: &buffer)
        row += 2

        // Fire
        var prevR = -1, prevG = -1, prevB = -1

        for y in 0..<height {
            moveTo(row: row, col: startCol, buffer: &buffer)
            for x in 0..<visibleWidth {
                let h = heat[y][x]
                let idx = min(palette.count - 1, Int(h * Double(palette.count - 1)))
                let (r, g, b) = palette[idx]

                if r != prevR || g != prevG || b != prevB {
                    append("\u{1B}[38;2;\(r);\(g);\(b)m", to: &buffer)
                    prevR = r; prevG = g; prevB = b
                }

                let charIdx = min(flameChars.count - 1, Int(h * Double(flameChars.count - 1)))
                buffer.append(contentsOf: String(flameChars[charIdx]).utf8)
            }
            append("\u{1B}[0m", to: &buffer)
            prevR = -1; prevG = -1; prevB = -1
            row += 1
        }

        // Draw logs
        let logLine1 = "     ___============___     "
        let logLine2 = "   |  \\\\~~~~~~~~~~~~//  |   "
        let logLine3 = "   |___\\\\__________//___|   "

        append("\u{1B}[38;2;139;69;19m", to: &buffer)
        for log in [logLine1, logLine2, logLine3] {
            let logCol = max(1, (termCols - log.count) / 2 + 1)
            moveTo(row: row, col: logCol, buffer: &buffer)
            append(log, to: &buffer)
            row += 1
        }

        // Brick hearth
        append("\u{1B}[38;2;120;50;30m", to: &buffer)
        let brickCount = min(visibleWidth + 4, termCols - 2)
        let brickRow = String(repeating: "▄", count: brickCount)
        let brickCol = max(1, (termCols - brickCount) / 2 + 1)
        moveTo(row: row, col: brickCol, buffer: &buffer)
        append(brickRow, to: &buffer)
        row += 2

        // Footer
        append("\u{1B}[0m", to: &buffer)
        let footer = "Press any key to exit"
        let footerCol = max(1, (termCols - footer.count) / 2 + 1)
        moveTo(row: row, col: footerCol, buffer: &buffer)
        append("\u{1B}[38;2;100;100;100m", to: &buffer)
        append(footer, to: &buffer)
        append("\u{1B}[0m", to: &buffer)
    }

    private func moveTo(row: Int, col: Int, buffer: inout [UInt8]) {
        append("\u{1B}[\(row);\(col)H", to: &buffer)
    }

    private func append(_ s: String, to buffer: inout [UInt8]) {
        buffer.append(contentsOf: s.utf8)
    }
}

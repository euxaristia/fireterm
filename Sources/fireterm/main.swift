#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

import FiretermLib

let terminal = Terminal()
terminal.clearScreen()

let (_, cols) = Terminal.size
let fireWidth = min(60, cols - 4)
let fireHeight = 20

var fireplace = Fireplace(width: fireWidth, height: fireHeight)
var outputBuffer = [UInt8]()
outputBuffer.reserveCapacity(fireWidth * fireHeight * 20)

let frameNs: UInt64 = 33_000_000  // ~30 FPS

while true {
    if terminal.keyPressed() { break }

    let start = clockNow()

    fireplace.update()

    outputBuffer.removeAll(keepingCapacity: true)
    fireplace.render(into: &outputBuffer)

    outputBuffer.withUnsafeBufferPointer { buf in
        if let base = buf.baseAddress {
            _ = write(STDOUT_FILENO, base, buf.count)
        }
    }

    let elapsed = clockNow() &- start
    if elapsed < frameNs {
        usleep(UInt32((frameNs &- elapsed) / 1000))
    }
}

terminal.clearScreen()
terminal.moveTo(row: 1, col: 1)

func clockNow() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) &* 1_000_000_000 &+ UInt64(ts.tv_nsec)
}

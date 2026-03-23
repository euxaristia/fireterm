#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

public struct Terminal: ~Copyable {
    private var originalTermios: termios

    public init() {
        originalTermios = termios()
        tcgetattr(STDIN_FILENO, &originalTermios)
        enableRawMode()
        hideCursor()
    }

    deinit {
        showCursor()
        var saved = originalTermios
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved)
    }

    private func enableRawMode() {
        var raw = originalTermios
        raw.c_lflag &= ~(UInt32(ECHO | ICANON))
        raw.c_cc.6 = 0  // VMIN
        raw.c_cc.5 = 0  // VTIME
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }

    public func hideCursor() {
        print("\u{1B}[?25l", terminator: "")
    }

    public func showCursor() {
        print("\u{1B}[?25h", terminator: "")
    }

    public func moveTo(row: Int, col: Int) {
        print("\u{1B}[\(row);\(col)H", terminator: "")
    }

    public func clearScreen() {
        print("\u{1B}[2J", terminator: "")
    }

    public func keyPressed() -> Bool {
        var c: UInt8 = 0
        return read(STDIN_FILENO, &c, 1) == 1
    }

    public static var size: (rows: Int, cols: Int) {
        var w = winsize()
        _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
        return (Int(w.ws_row), Int(w.ws_col))
    }
}

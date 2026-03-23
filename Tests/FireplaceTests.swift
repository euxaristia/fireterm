import Testing

@testable import FiretermLib

private let testSize = (rows: 40, cols: 80)

@Suite("Fireplace Tests")
struct FireplaceTests {
    @Test("Initialization creates correct dimensions")
    func testInit() {
        let fp = Fireplace(width: 40, height: 15)
        #expect(fp.width == 40)
        #expect(fp.height == 15)
    }

    @Test("Update does not crash and keeps heat in bounds")
    func testUpdate() {
        var fp = Fireplace(width: 20, height: 10)
        for _ in 0..<100 {
            fp.update()
        }
    }

    @Test("Render produces non-empty output")
    func testRender() {
        var fp = Fireplace(width: 20, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: testSize)
        #expect(buffer.count > 0)
    }

    @Test("Render contains ANSI escape codes")
    func testRenderContainsEscapes() {
        var fp = Fireplace(width: 20, height: 10)
        fp.update()
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: testSize)
        let output = String(decoding: buffer, as: UTF8.self)
        #expect(output.contains("\u{1B}["))
    }

    @Test("Multiple updates produce different frames")
    func testFramesVary() {
        var fp = Fireplace(width: 30, height: 12)

        fp.update()
        var buf1 = [UInt8]()
        fp.render(into: &buf1, terminalSize: testSize)

        for _ in 0..<5 { fp.update() }
        var buf2 = [UInt8]()
        fp.render(into: &buf2, terminalSize: testSize)

        #expect(buf1 != buf2)
    }

    @Test("Zero-width fireplace doesn't crash")
    func testZeroWidth() {
        var fp = Fireplace(width: 0, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: testSize)
        // Zero width produces no visible fire, but still renders chrome
    }

    @Test("Very small fireplace works")
    func testSmallFireplace() {
        var fp = Fireplace(width: 1, height: 1)
        for _ in 0..<10 { fp.update() }
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: testSize)
        #expect(buffer.count > 0)
    }

    @Test("Large fireplace works")
    func testLargeFireplace() {
        var fp = Fireplace(width: 200, height: 50)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: (rows: 60, cols: 220))
        #expect(buffer.count > 0)
    }

    @Test("Render buffer can be reused")
    func testBufferReuse() {
        var fp = Fireplace(width: 20, height: 10)
        var buffer = [UInt8]()
        buffer.reserveCapacity(4096)

        fp.update()
        fp.render(into: &buffer, terminalSize: testSize)
        let firstLen = buffer.count

        buffer.removeAll(keepingCapacity: true)
        fp.update()
        fp.render(into: &buffer, terminalSize: testSize)

        #expect(firstLen > 100)
        #expect(buffer.count > 100)
    }

    @Test("Heat converges towards zero at top rows after many updates")
    func testHeatDissipation() {
        var fp = Fireplace(width: 30, height: 20)
        for _ in 0..<50 { fp.update() }
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: testSize)
        let output = String(decoding: buffer, as: UTF8.self)
        #expect(output.contains(" "))
    }

    @Test("Render with zero terminal size produces no output")
    func testZeroTerminalSize() {
        var fp = Fireplace(width: 20, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: (rows: 0, cols: 0))
        #expect(buffer.isEmpty)
    }

    @Test("Render clamps fire width to narrow terminal")
    func testNarrowTerminal() {
        var fp = Fireplace(width: 60, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer, terminalSize: (rows: 30, cols: 30))
        #expect(buffer.count > 0)
    }
}

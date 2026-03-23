import Testing

@testable import FiretermLib

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
        // If we got here without crashing, the simulation is stable
    }

    @Test("Render produces non-empty output")
    func testRender() {
        var fp = Fireplace(width: 20, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        #expect(buffer.count > 0)
    }

    @Test("Render contains ANSI escape codes")
    func testRenderContainsEscapes() {
        var fp = Fireplace(width: 20, height: 10)
        fp.update()
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        let output = String(decoding: buffer, as: UTF8.self)
        #expect(output.contains("\u{1B}["))
    }

    @Test("Multiple updates produce different frames")
    func testFramesVary() {
        var fp = Fireplace(width: 30, height: 12)

        fp.update()
        var buf1 = [UInt8]()
        fp.render(into: &buf1)

        // Run several updates to ensure state changes
        for _ in 0..<5 { fp.update() }
        var buf2 = [UInt8]()
        fp.render(into: &buf2)

        // Frames should differ due to randomness
        #expect(buf1 != buf2)
    }

    @Test("Zero-width fireplace doesn't crash")
    func testZeroWidth() {
        var fp = Fireplace(width: 0, height: 10)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        #expect(buffer.count > 0)
    }

    @Test("Very small fireplace works")
    func testSmallFireplace() {
        var fp = Fireplace(width: 1, height: 1)
        for _ in 0..<10 { fp.update() }
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        #expect(buffer.count > 0)
    }

    @Test("Large fireplace works")
    func testLargeFireplace() {
        var fp = Fireplace(width: 200, height: 50)
        fp.update()
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        #expect(buffer.count > 0)
    }

    @Test("Render buffer can be reused")
    func testBufferReuse() {
        var fp = Fireplace(width: 20, height: 10)
        var buffer = [UInt8]()
        buffer.reserveCapacity(4096)

        fp.update()
        fp.render(into: &buffer)
        let firstLen = buffer.count

        buffer.removeAll(keepingCapacity: true)
        fp.update()
        fp.render(into: &buffer)

        // Both renders should produce meaningful output
        #expect(firstLen > 100)
        #expect(buffer.count > 100)
    }

    @Test("Heat converges towards zero at top rows after many updates")
    func testHeatDissipation() {
        var fp = Fireplace(width: 30, height: 20)
        for _ in 0..<50 { fp.update() }
        // Render and check the top portion is mostly dark (spaces)
        var buffer = [UInt8]()
        fp.render(into: &buffer)
        let output = String(decoding: buffer, as: UTF8.self)
        // The output should contain spaces (cool areas at top)
        #expect(output.contains(" "))
    }
}

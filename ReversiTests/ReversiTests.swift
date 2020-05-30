import XCTest
import Combine
@testable import Reversi

class ReversiTests: XCTestCase {
    func testNewGame() {
        let gameManager = GameManager(boardView: BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374)))
        gameManager.newGame()

        do {
            let savePath = tempPath()
            try gameManager.saveGame(path: savePath)

            XCTAssertEqual(
                try String(contentsOf: savePath),
                """
                x00
                --------
                --------
                --------
                ---ox---
                ---xo---
                --------
                --------
                --------

                """
            )

        } catch {
            XCTFail("\(error)")
        }
    }

    func testLoadGame() {
        let gameManager = GameManager(boardView: BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374)))

        do {
            let expected =
                """
                x00
                --------
                x-------
                -o------
                --ooo---
                ---ox---
                -----oox
                ---ooo--
                --o-x---

                """
            let loadPath = tempPath()
            try expected
                .data(using: .utf8)?
                .write(to: loadPath)

            try gameManager.loadGame(path: loadPath)

            let savePath = tempPath()
            try gameManager.saveGame(path: savePath)

            XCTAssertEqual(try String(contentsOf: savePath), expected)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMakeMove1() {
        let savePath = tempPath()

        let boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374))
        let gameManager = GameManager(boardView: boardView)
        gameManager.newGame()

        let exp = expectation(description: "")

        let cancellable = gameManager.onMakeMove
            .receive(on: DispatchQueue.main)
            .sink {
                for coordinate in $0.coordinates {
                    boardView.setDisk($0.disk, atX: coordinate.0, y: coordinate.1, animated: false)
                }
                do {
                    try gameManager.saveGame(path: savePath)
                    exp.fulfill()
                } catch {
                    XCTFail("\(error)")
                }
            }
        XCTAssertNotNil(cancellable)

        do {
            try gameManager.placeDisk(atX: 5, y: 4)
            wait(for: [exp], timeout: 1)

            XCTAssertEqual(
                try String(contentsOf: savePath),
                """
                o00
                --------
                --------
                --------
                ---ox---
                ---xxx--
                --------
                --------
                --------

                """
            )
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMakeMove2() {
        let savePath = tempPath()

        let boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374))
        let gameManager = GameManager(boardView: boardView)
        gameManager.newGame()

        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 2

        let cancellable = gameManager.onMakeMove
            .receive(on: DispatchQueue.main)
            .sink {
                for coordinate in $0.coordinates {
                    boardView.setDisk($0.disk, atX: coordinate.0, y: coordinate.1, animated: false)
                }
                do {
                    try gameManager.saveGame(path: savePath)
                    exp.fulfill()
                } catch {
                    XCTFail("\(error)")
                }
            }
        XCTAssertNotNil(cancellable)

        do {
            try gameManager.placeDisk(atX: 5, y: 4)
            try gameManager.placeDisk(atX: 3, y: 5)
            wait(for: [exp], timeout: 1)

            XCTAssertEqual(
                try String(contentsOf: savePath),
                """
                x00
                --------
                --------
                --------
                ---ox---
                ---oxx--
                ---o----
                --------
                --------

                """
            )
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOnStateChangedCalled() {
        let savePath = tempPath()

        let boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374))
        let gameManager = GameManager(boardView: boardView)
        gameManager.newGame()

        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 2

        var cancellables: Set<AnyCancellable> = []
        gameManager.onStateChanged
            .receive(on: DispatchQueue.main)
            .sink {
                exp.fulfill()
            }
            .store(in: &cancellables)

        gameManager.onMakeMove
            .receive(on: DispatchQueue.main)
            .sink {
                for coordinate in $0.coordinates {
                    boardView.setDisk($0.disk, atX: coordinate.0, y: coordinate.1, animated: false)
                }
                do {
                    try gameManager.saveGame(path: savePath)
                } catch {
                    XCTFail("\(error)")
                }
            }
            .store(in: &cancellables)

        do {
            try gameManager.placeDisk(atX: 5, y: 4)
            try gameManager.placeDisk(atX: 3, y: 5)
            wait(for: [exp], timeout: 1)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testChangePlayerMode() {
        let savePath = tempPath()

        let boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 374, height: 374))
        let gameManager = GameManager(boardView: boardView)
        gameManager.newGame()

        let exp = expectation(description: "")

        let cancellable = gameManager.onMakeMove
            .receive(on: DispatchQueue.main)
            .sink {
                for coordinate in $0.coordinates {
                    boardView.setDisk($0.disk, atX: coordinate.0, y: coordinate.1, animated: false)
                }
                do {
                    try gameManager.saveGame(path: savePath)
                    exp.fulfill()
                } catch {
                    XCTFail("\(error)")
                }
            }
        XCTAssertNotNil(cancellable)

        gameManager.changePlayerMode(for: .dark, mode: GameManager.Player.computer.rawValue)
        
        do {
            try gameManager.saveGame(path: savePath)
            wait(for: [exp], timeout: 4)

            XCTAssertTrue(
                [
                    """
                    o10
                    --------
                    --------
                    --------
                    ---ox---
                    ---xxx--
                    --------
                    --------
                    --------

                    """,
                    """
                    o10
                    --------
                    --------
                    --------
                    ---ox---
                    ---xx---
                    ----x---
                    --------
                    --------

                    """,
                    """
                    o10
                    --------
                    --------
                    --------
                    --xxx---
                    ---xo---
                    --------
                    --------
                    --------

                    """,
                    """
                    o10
                    --------
                    --------
                    ---x----
                    ---xx---
                    ---xo---
                    --------
                    --------
                    --------

                    """,
                ]
                .contains(
                    try String(contentsOf: savePath)
                )
            )
        } catch {
            XCTFail("\(error)")
        }
    }

    func tempPath() -> URL { URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString) }
}

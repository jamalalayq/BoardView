//
//  Created by Jamal Alaayq on 2022-11-25.
//

import Foundation
import SwiftUI

public struct BoardView: View {
    private var atRealTime: Bool = false
    private var leadingView: () -> any View
    private var trailingView: () -> any View
    
    @Binding private var board: Board
    
    @State private var penColor: Color = .primary
    @State private var linesThickness: CGFloat = 1.0
    @State private var lines: Array<Line> = []
    @State private var size: Size = .zero
    @State private var isEraser: Bool = false
    @State private var location: CGPoint = .zero
    @State private var guidesType: BoardGuidesType = .blank
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        board: Binding<Board>,
        atRealTime: Bool = false,
        @ViewBuilder leadingView: @escaping () -> some View = { EmptyView() },
        @ViewBuilder trailingView: @escaping () -> some View =  { EmptyView() }
    ) {
        self._board = board
        self.atRealTime = atRealTime
        self.leadingView = leadingView
        self.trailingView = trailingView
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: .zero) {
                // MARK: Toolbar
                BoardToolbar(
                    selectedColor: $penColor,
                    linesThickness: $linesThickness,
                    isEraser: $isEraser
                ) {
                    leadingView()
                } trailingView: {
                    trailingView()
                } clearAction: {
                    isEraser = false
                    lines = []
                    board = makeBoard(with: lines)
                } guidesDrawingAction: { type in
                    withAnimation { guidesType = type }
                }
                .padding(.bottom, 4)
                .background(.ultraThinMaterial)
                
                ZStack {
                    GeometryReader { reader in                        
                        // MARK: Canvas
                        Canvas { context, size in
                            // MARK: Draw images
                            for image in board.images where image.image != nil {
                                context.draw(
                                    image.image!,
                                    at: image.point.toCGPoint(),
                                    anchor: .center
                                )
                            }
                            
                            // MARK: Draw texts
                            for text in board.texts where !text.string.isEmpty && text.text != nil {
                                context.draw(
                                    text.text!,
                                    in: .init(
                                        origin: text.point.toCGPoint(),
                                        size: text.size.toCGSize()
                                    )
                                )
                            }
                            
                            // MARK: Drawing lines
                            for line in lines {
                                var path = Path()
                                path.addLines(line.points.compactMap { $0.toCGPoint() })
                                
                                context.stroke(
                                    path,
                                    with: .color(line.color),
                                    style: StrokeStyle(
                                        lineWidth: line.width,
                                        lineCap: .round,
                                        lineJoin: .round,
                                        miterLimit: .zero
                                    )
                                )
                            }
                        }                        
                        // MARK: Drawing Gesture
                        .gesture(
                            DragGesture(
                                minimumDistance: .zero,
                                coordinateSpace: .local
                            )
                            .onChanged({ value in
                                let point = value.location
                                location = point
                                
                                if value.translation == .zero {
                                    lines.append(
                                        .init(
                                            points: [point.toPoint()],
                                            color: isEraser ? (colorScheme == .dark ? .black : .white) : penColor,
                                            width: isEraser ? 15.0 : linesThickness,
                                            type: isEraser ? .eraser : .pen
                                        )
                                    )
                                } else {
                                    guard let index = lines.indices.last else { return }
                                    lines[index].points.append(point.toPoint())
                                }
                            })
                            .onEnded({ _ in
                                if !atRealTime {
                                    board = makeNewBoard(from: board, with: lines)
                                }
                            })
                        )
                        .onAppear { size = reader.size.toSize() }
                        .background(.clear)
                    }
                    // MARK: Draw guides
                    .overlay {
                        switch guidesType {
                            case .blank:
                                EmptyView().background(.clear)
                                
                            case .grid(let linesCount):
                                Path { path in
                                    // Draw horizontal lines
                                    configureHorizontalPath(&path, linesCount: linesCount)
                                    
                                    // Draw vertical lines
                                    configureVerticalPath(&path, linesCount: linesCount)
                                    
                                    path.closeSubpath()
                                }
                                .guidesLinesStyle()
                                                                
                            case .ruled(let linesCount):
                                // Draw horizontal lines
                                Path { path in
                                    configureHorizontalPath(&path, linesCount: linesCount)
                                    
                                    path.closeSubpath()
                                }
                                .guidesLinesStyle()
                        }
                    }
                    
                    // MARK: Draw eraser circle
                    if isEraser {
                        Circle()
                            .stroke(lineWidth: 1.5)
                            .background(Circle().fill(colorScheme == .dark ? .black : .white))
                            .frame(width: 30, height: 30)
                            .position(x: location.x, y: location.y)
                    }
                }                
            }
        }
        .onChange(of: lines) { newValue in
            if atRealTime {
                board = makeNewBoard(from: board, with: newValue)
            }
        }
        .onAppear {
            penColor = colorScheme == .dark ? .white : .black
        }
        .onChange(of: colorScheme) { newValue in
            switch newValue {
                case .dark where penColor == .black:
                    penColor = .white
                case .light where penColor == .white:
                    penColor = .black
                default: break
            }
            
            lines = lines.map {
                var line = $0
                if case .eraser = $0.type {
                    line.color =  newValue == .light ? .white : .black
                }
                return line
            }
        }
    }
    
    // MARK: - Private functions
    private func makeBoard(with values: Array<Line>) -> Board {
        .init(
            drawingSpaceSize: size,
            backgroundColor: colorScheme == .dark ? .black : .white,
            lines: values
        )
    }
    
    private func makeNewBoard(from board: Board, with lines: Array<Line>) -> Board {
        .init(
            drawingSpaceSize: size,
            backgroundColor: colorScheme == .dark ? .black : .white,
            lines: lines,
            images: board.images,
            texts: board.texts
        )
    }
    
    private func getLinesSpacing(basedOn linesCount: UInt) -> CGFloat {
        size.height / (CGFloat(linesCount) + 0.5)
    }
    
    private func configureHorizontalPath(_ path: inout Path, linesCount: UInt) {
        let linesSpacing = getLinesSpacing(basedOn: linesCount)
        
        for index in 1...linesCount {
            let start = CGPoint(x: .zero, y: (CGFloat(index) * linesSpacing))
            let end = CGPoint(x: size.width, y: (CGFloat(index) * linesSpacing))
            path.move(to: start)
            path.addLine(to: end)
        }
    }
    
    private func configureVerticalPath(_ path: inout Path, linesCount: UInt) {
        let linesSpacing = getLinesSpacing(basedOn: linesCount)
        let numberOfVerticalLines = Int(size.width / CGFloat(linesSpacing))
        let margin = (size.width - CGFloat(numberOfVerticalLines - 1) * CGFloat(linesSpacing)) * 0.50
        
        for index in .zero...numberOfVerticalLines {
            let start = CGPoint(x: (CGFloat(index) * linesSpacing) + margin, y: .zero)
            let end = CGPoint(x: (CGFloat(index) * linesSpacing) + margin, y: size.height)
            path.move(to: start)
            path.addLine(to: end)
        }
    }
}

extension Path {
    func guidesLinesStyle() -> some View {
        stroke(
            style: StrokeStyle(
                lineWidth: 0.5,
                lineCap: .round,
                dash: [3, 5],
                dashPhase: 3
            )
        )
        .foregroundColor(Color(white: 0.80))
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        BoardView(board: .constant(.empty))
    }
}

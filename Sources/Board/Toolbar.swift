//
//  Created by Jamal Alaayq on 2022-12-10.
//

import SwiftUI

public enum BoardGuidesType {
    case blank
    case grid(linesCount: UInt)
    case ruled(linesCount: UInt)
}

struct BoardToolbar: View {
    @Binding var selectedColor: Color
    @Binding var linesThickness: CGFloat
    @Binding var isEraser: Bool
    
    @State private var isPresentedLines: Bool = false
    @State private var isPresentedGuides: Bool = false
    @State private var isPresentedVLinesCount: Bool = false
    @State private var isPresentedVHLinesCount: Bool = false
    
    @ViewBuilder var leadingView: () -> any View
    @ViewBuilder var trailingView: () -> any View
    
    var clearAction: () -> Void
    var guidesDrawingAction: (BoardGuidesType) -> Void
    
    var body: some View {
        HStack(spacing: .zero) {
            AnyView(leadingView())
            
            Spacer()
            
            // MARK: Drawing tools
            HStack(spacing: 10.0) {
                Button {
                    isPresentedLines = true
                    isEraser = false
                } label: {
                    let image = Image(systemName: "pencil.tip").tint(selectedColor)
                    switch linesThickness {
                        case 1:
                            image.font(.title.weight(.light))
                        case 2:
                            image.font(.title.weight(.regular))
                        case 3:
                            image.font(.title.weight(.medium))
                        case 4:
                            image.font(.title.weight(.bold))
                        case 5:
                            image.font(.title.weight(.black))
                        default:
                            image
                    }
                }
                .fixedSize()
                // MARK: Lines Thickness
                .popover(isPresented: $isPresentedLines) {
                    Stepper(value: $linesThickness, in: 1...5, step: 1) {
                        Text("\(Int(linesThickness))")
                            .font(.callout)
                    }
                    .padding()
                    .tint(.primary)
                    .fixedSize()
                }
                
                ColorPicker("", selection: $selectedColor, supportsOpacity: true)
                    .labelsHidden()
                
                /*Button {
                    #warning("Select image from photo picker")
                } label: {
                    Image(systemName: "photo.fill")
                }*/
                
                /*Button {
                    #warning("Write a text")
                } label: {
                    Image(systemName: "a")
                        .font(.title.bold())
                }*/
                
                Button {
                    isPresentedGuides = true
                } label: {
                    Image(systemName: "square.grid.4x3.fill")
                }
                // MARK: Guides
                .popover(isPresented: $isPresentedGuides) {
                    VStack(spacing: 16.0) {
                        HStack {
                            Button {
                                isPresentedGuides = false
                                isPresentedVHLinesCount = false
                                isPresentedVLinesCount = false
                                guidesDrawingAction(.blank)
                            } label: {
                                Image(systemName: "rectangle")
                            }
                            
                            Button {
                                isPresentedVLinesCount = false
                                isPresentedVHLinesCount = true
                            } label: {
                                Image(systemName: "square.grid.4x3.fill")
                            }
                            
                            Button {
                                isPresentedVHLinesCount = false
                                isPresentedVLinesCount = true
                            } label: {
                                Image(systemName: "line.3.horizontal")
                            }
                        }
                        
                        if isPresentedVLinesCount {
                            HStack {
                                Button {
                                    guidesDrawingAction(.ruled(linesCount: 10))
                                } label: {
                                    Text("10")
                                }
                                Button {
                                    guidesDrawingAction(.ruled(linesCount: 12))
                                } label: {
                                    Text("12")
                                }
                                Button {
                                    guidesDrawingAction(.ruled(linesCount: 14))
                                } label: {
                                    Text("14")
                                }
                                Button {
                                    guidesDrawingAction(.ruled(linesCount: 16))
                                } label: {
                                    Text("16")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if isPresentedVHLinesCount {
                            HStack {
                                Button {
                                    guidesDrawingAction(.grid(linesCount: 10))
                                } label: {
                                    Text("10x10")
                                }
                                Button {
                                    guidesDrawingAction(.grid(linesCount: 12))
                                } label: {
                                    Text("12x12")
                                }
                                Button {
                                    guidesDrawingAction(.grid(linesCount: 14))
                                } label: {
                                    Text("14x14")
                                }
                                Button {
                                    guidesDrawingAction(.grid(linesCount: 16))
                                } label: {
                                    Text("16x16")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .tint(.primary)
                    .onDisappear {
                        isPresentedVHLinesCount = false
                        isPresentedVLinesCount = false
                    }
                }
                
                Toggle(isOn: $isEraser) {
                    Image(systemName: "eraser.fill")
                }
                .labelsHidden()
                .toggleStyle(.button)
                
                Button {
                    clearAction()
                } label: {
                    Image(systemName: "clear.fill")
                }                
            }
            .tint(.primary)
            .font(.title)
            
            Spacer()
            
            AnyView(trailingView())
        }
        .frame(maxWidth: .infinity)
    }
}

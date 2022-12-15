
import Foundation
import SwiftUI

public struct Point: Codable, Equatable {
    let x, y: CGFloat
    
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    public func toCGPoint() -> CGPoint { .init(x: x, y: y) }
    
    public static var zero: Self { CGPoint.zero.toPoint() }
}

extension CGPoint {
    public func toPoint() -> Point { .init(x: x, y: y) }
}

public struct Size: Codable, Equatable {
    let width, height: CGFloat
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    public static var zero: Self { CGSize.zero.toSize() }
    
    public func toCGSize() -> CGSize { .init(width: width, height: height) }
}

extension CGSize {
    public func toSize() -> Size { .init(width: width, height: height) }
}

extension Color: Codable {
    public func encode(to encoder: Encoder) throws {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        var container = encoder.singleValueContainer()
        let uiColor = UIColor(self)
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        try container.encode(
            ColorValues(
                red: r,
                green: g,
                blue: b,
                opacity: a
            )
        )
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let values = try container.decode(ColorValues.self)
        self = Self(
            red: values.red,
            green: values.green,
            blue: values.blue,
            opacity: values.opacity
        )
    }
    
    public struct ColorValues: Codable {
        let red, green, blue, opacity: CGFloat
    }
}

public struct Line: Identifiable, Codable, Equatable {
    public private(set) var id = UUID()
    public internal(set) var points: Array<Point> = []
    public internal(set) var color: Color
    public internal(set) var width: CGFloat
    public internal(set) var type: LineType
}

public enum LineType: String, Codable {
    case pen, eraser
}

public struct BoardText: Codable, Equatable {
    public var string: String
    public var point: Point
    public var size: Size
    
    internal var text: Text?
    
    public init(string: String, point: Point, size: Size, text: Text) {
        self.string = string
        self.point = point
        self.size = size
        self.text = text
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        string = try container.decode(String.self, forKey: .string)
        point = try container.decode(Point.self, forKey: .point)
        size = try container.decode(Size.self, forKey: .size)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(string, forKey: .string)
        try container.encode(point, forKey: .point)
        try container.encode(size, forKey: .size)
    }
    
    private enum CodingKeys: String, CodingKey {
        case string, point, size
    }
}

public struct BoardImage: Codable, Equatable {
    public var imageData: Data?
    public var imageURL: URL?
    public var imageLink: String?
    public var point: Point
    public var size: Size
    
    internal var image: Image?
    
    public init(
        imageData: Data? = .none,
        imageURL: URL? = .none,
        imageLink: String? = .none,
        point: Point,
        size: Size,
        image: Image
    ) {
        self.imageData = imageData
        self.imageURL = imageURL
        self.imageLink = imageLink
        self.point = point
        self.size = size
        self.image = image
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        imageLink = try container.decodeIfPresent(String.self, forKey: .imageLink)
        point = try container.decode(Point.self, forKey: .point)
        size = try container.decode(Size.self, forKey: .size)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encodeIfPresent(imageLink, forKey: .imageLink)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(point, forKey: .point)
        try container.encode(size, forKey: .size)
    }
    
    private enum CodingKeys: String, CodingKey {
        case imageData, imageURL, imageLink, point, size
    }
}


public struct Board: Codable, Equatable {
    public internal(set) var drawingSpaceSize: Size
    public internal(set) var backgroundColor: Color
    public internal(set) var lines: Array<Line>
    public var images: Array<BoardImage> = []
    public var texts: Array<BoardText> = []
    
    public static var empty: Self {
        .init(
            drawingSpaceSize: .zero,
            backgroundColor: .clear,
            lines: [],
            images: [],
            texts: []
        )
    }
    
    public var isEmpty: Bool {
        lines.isEmpty && images.isEmpty && texts.isEmpty
    }
    
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    public static func toBoard(from data: Data) throws -> Board {
        let decoder = JSONDecoder()
        return try decoder.decode(Board.self, from: data)
    }
    
    @discardableResult
    public mutating func append(_ image: BoardImage) -> Self {
        images.append(image)
        return self
    }
    
    @discardableResult
    public mutating func append(_ text: BoardText) -> Self {
        texts.append(text)
        return self
    }
}

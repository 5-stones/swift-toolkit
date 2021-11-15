//
//  Copyright 2021 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import R2Shared

public typealias PresentationFit = R2Shared.Presentation.Fit
public typealias PresentationOrientation = R2Shared.Presentation.Orientation
public typealias PresentationOverflow = R2Shared.Presentation.Overflow

public struct PresentationKey: Hashable {
    public let id: String
    
    public static let continuous = PresentationKey(id: "continuous")
    public static let fit = PresentationKey(id: "fit")
    public static let orientation = PresentationKey(id: "orientation")
    public static let overflow = PresentationKey(id: "overflow")
    public static let pageSpacing = PresentationKey(id: "pageSpacing")
    public static let readingProgression = PresentationKey(id: "readingProgression")
}

/// Holds a list of key-value pairs provided by the app to influence a Navigator's Presentation
/// Properties. The keys must be valid Presentation Keys.
public struct PresentationValues: Hashable {
    public private(set) var values: [PresentationKey: AnyHashable] = [:]
    
    public init(_ values: [PresentationKey: AnyHashable] = [:]) {
        self.values = values
    }
    
    public init(
        continuous: Bool? = nil,
        fit: PresentationFit? = nil,
        orientation: PresentationOrientation? = nil,
        overflow: PresentationOverflow? = nil,
        pageSpacing: Double? = nil,
        readingProgression: ReadingProgression? = nil
    ) {
        self.init()
        self.continuous = continuous
        self.fit = fit
        self.orientation = orientation
        self.overflow = overflow
        self.pageSpacing = pageSpacing
        self.readingProgression = readingProgression
    }
    
    public var continuous: Bool? {
        get { self[.continuous] }
        set { self[.continuous] = newValue }
    }
    
    public var fit: PresentationFit? {
        get { self[.fit] }
        set { self[.fit] = newValue }
    }
    
    public var orientation: PresentationOrientation? {
        get { self[.orientation] }
        set { self[.orientation] = newValue }
    }
    
    public var overflow: PresentationOverflow? {
        get { self[.overflow] }
        set { self[.overflow] = newValue }
    }
    
    public var pageSpacing: Double? {
        get { self[.pageSpacing] }
        set { self[.pageSpacing] = newValue }
    }
    
    public var readingProgression: ReadingProgression? {
        get { self[.readingProgression] }
        set { self[.readingProgression] = newValue }
    }
    
    /// Returns a copy of this object after overwriting any setting with the values from `other`.
    public func merging(_ other: PresentationValues) -> PresentationValues {
        PresentationValues(values.merging(other.values, uniquingKeysWith: { first, second in second }))
    }
    
    subscript<T>(_ key: PresentationKey) -> T? {
        get {
            values[key] as? T
        }
        set {
            if let newValue = newValue as? AnyHashable {
                values[key] = newValue
            } else {
                values.removeValue(forKey: key)
            }
        }
    }
    
    subscript<T: RawRepresentable>(key: PresentationKey) -> T? where T.RawValue == String {
        get {
            (values[key] as? String).flatMap(T.init(rawValue:))
        }
        set {
            if let newValue = newValue?.rawValue {
                values[key] = newValue
            } else {
                values.removeValue(forKey: key)
            }
        }
    }
}

/// Holds the current values for the Presentation Properties determining how a publication is
/// rendered by a Navigator. For example, "font size" or "playback rate".
public protocol Presentation {
    
    var values: PresentationValues { get }
    
    func constraints(for key: PresentationKey) -> PresentationValueConstraints?
    
    /// Returns a user-facing localized label for the given value, which can be used in the user
    /// interface.
    ///
    /// For example, with the "reading progression" property, the value ltr has for label "Left to
    /// right" in English.
    func label(for key: PresentationKey, value: AnyHashable) -> String?
    
    /// Determines whether a given property will be active when the given settings are applied to the
    /// Navigator.
    ///
    /// For example, with an EPUB Navigator using Readium CSS, the property "letter spacing" requires
    /// to switch off the "publisher defaults" setting to be active.
    ///
    /// This is useful to determine whether to grey out a view in the user settings interface.
    func isActive(_ key: PresentationKey, for values: PresentationValues) -> Bool
    
    /// Modifies the given settings to make sure the property will be activated when applying them to
    /// the Navigator.
    ///
    /// For example, with an EPUB Navigator using Readium CSS, activating the "letter spacing"
    /// property means ensuring the "publisher defaults" setting is disabled.
    ///
    /// If the property cannot be activated, returns a user-facing localized error.
    func activate(_ key: PresentationKey, in values: PresentationValues) throws -> PresentationValues
}

public extension Presentation {
    
    func isActive(_ key: PresentationKey) -> Bool {
        isActive(key, for: values)
    }
}

public protocol PresentationValueConstraints {
    func validate(value: AnyHashable) -> Bool
}

public struct TypedPresentationValueConstraints<Value>: PresentationValueConstraints {
    public func validate(value: AnyHashable) -> Bool {
        value is Value
    }
}

public struct StringPresentationValueConstraints: PresentationValueConstraints {
    public let supportedValues: [String]?
    
    public init(supportedValues: [String]? = nil) {
        self.supportedValues = supportedValues
    }
    
    public func validate(value: AnyHashable) -> Bool {
        guard let value = value as? String else {
            return false
        }
        if let supportedValues = supportedValues, !supportedValues.contains(value) {
            return false
        }
        return true
    }
}

public struct EnumPresentationValueConstraints<E: RawRepresentable & Equatable>: PresentationValueConstraints where E.RawValue == String {
    public let supportedValues: [E]?
    
    public init(supportedValues: [E]? = nil) {
        self.supportedValues = supportedValues
    }
    
    public func validate(value: AnyHashable) -> Bool {
        guard let value = value as? E else {
            return false
        }
        if let supportedValues = supportedValues, !supportedValues.contains(value) {
            return false
        }
        return true
    }
}

public struct RangePresentationValueConstraints: PresentationValueConstraints {
    public let stepCount: Int?
    
    public func validate(value: AnyHashable) -> Bool {
        guard let value = value as? Double else {
            return false
        }
        return 0.0...1.0 ~= value
    }
}
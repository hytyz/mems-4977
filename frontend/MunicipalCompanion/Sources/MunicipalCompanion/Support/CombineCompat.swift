import Foundation

#if !canImport(Combine)

public protocol ObservableObject: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(initialValue: Value) {
        self.wrappedValue = initialValue
    }
}

#endif

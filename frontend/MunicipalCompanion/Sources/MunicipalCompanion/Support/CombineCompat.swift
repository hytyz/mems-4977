import Foundation

// Minimal ObservableObject/@Published compatibility for platforms without
// Combine (Linux, used for host-side type-checking of the Foundation layer).
// On Apple platforms Combine always exists, so this file compiles to nothing.
// It is NOT a full Combine implementation — just enough surface for the
// ObservableObject-based view models to type-check.
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

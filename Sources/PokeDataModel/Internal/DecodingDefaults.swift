import Foundation

extension KeyedDecodingContainer {
    func decode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        default defaultValue: @autoclosure () -> T
    ) throws -> T {
        try decodeIfPresent(type, forKey: key) ?? defaultValue()
    }

    func decodeArray<T: Decodable>(
        _ type: [T].Type,
        forKey key: Key,
        default defaultValue: @autoclosure () -> [T]
    ) throws -> [T] {
        try decodeIfPresent(type, forKey: key) ?? defaultValue()
    }

    func decodeDictionary<DictionaryKey: Hashable & Decodable, Value: Decodable>(
        _ type: [DictionaryKey: Value].Type,
        forKey key: Key,
        default defaultValue: @autoclosure () -> [DictionaryKey: Value]
    ) throws -> [DictionaryKey: Value] {
        try decodeIfPresent(type, forKey: key) ?? defaultValue()
    }
}

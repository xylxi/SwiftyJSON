//  SwiftyJSON.swift
//
//  Copyright (c) 2014 Ruoyu Fu, Pinglin Tang
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

// MARK: - Error

///Error domain
public let ErrorDomain: String = "SwiftyJSONErrorDomain"

///Error code
public let ErrorUnsupportedType: Int = 999
public let ErrorIndexOutOfBounds: Int = 900
public let ErrorWrongType: Int = 901
public let ErrorNotExist: Int = 500
public let ErrorInvalidJSON: Int = 490

// MARK: - JSON Type

/**
JSON's type definitions.

See http://www.json.org
*/
public enum Type :Int{
    
    case Number
    case String
    case Bool
    case Array
    case Dictionary
    case Null
    case Unknown
}

// MARK: - JSON Base
// @我: 基础结构体JSON
// 这个基本机构体中提供了构建JSON对象,并且将真实的数据通过计算属性object的set和get方法
// 放置正确的数据中
public struct JSON {
    
    /**
     Creates a JSON using the data.
     @我: 根据data创建JSON结构体
     NSData->json数据(obj)->JSON结构体
     
     - parameter data:  The NSData used to convert to json.Top level object in data is an NSArray or NSDictionary
     - parameter opt:   The JSON serialization reading options. `.AllowFragments` by default.
     - parameter error: error The NSErrorPointer used to return the error. `nil` by default.
     
     - returns: The created JSON
     */
    public init(data:NSData, options opt: NSJSONReadingOptions = .AllowFragments, error: NSErrorPointer = nil) {
        do {
            let object: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: opt)
            self.init(object)
        } catch let aError as NSError {
            if error != nil {
                error.memory = aError
            }
            self.init(NSNull())
        }
    }
    
    /**
     Create a JSON from JSON string
     - parameter string: Normal json string like '{"a":"b"}'
     
     - returns: The created JSON
     */
    public static func parse(string:String) -> JSON {
        return string.dataUsingEncoding(NSUTF8StringEncoding)
            .flatMap({JSON(data: $0)}) ?? JSON(NSNull())
    }
    
    /**
     Creates a JSON using the object.
     @我: object可以是
     字符串、数字类型、数组、字典、空
     如果是字典：key必须是String
     如果是数字：不能是NaN或者infinity? ->不明白
     - parameter object:  The object must have the following properties: All objects are NSString/String, NSNumber/Int/Float/Double/Bool, NSArray/Array, NSDictionary/Dictionary, or NSNull; All dictionary keys are NSStrings/String; NSNumbers are not NaN or infinity.
     
     - returns: The created JSON
     */
    public init(_ object: AnyObject) {
        self.object = object
    }
    
    /**
     Creates a JSON from a [JSON]
     @我: 最终会走
     public init(_ object: AnyObject)方法
     流程:
     [JSON] -> [object]->JSON
     - parameter jsonArray: A Swift array of JSON objects
     
     - returns: The created JSON
     */
    public init(_ jsonArray:[JSON]) {
        self.init(jsonArray.map { $0.object })
    }
    
    /**
     Creates a JSON from a [String: JSON]
     @我: 最终会走
     public init(_ object: AnyObject)方法
     流程:
     [String: JSON] -> [String : AnyObject] ->JSON
     - parameter jsonDictionary: A Swift dictionary of JSON objects
     
     - returns: The created JSON
     */
    public init(_ jsonDictionary:[String: JSON]) {
        var dictionary = [String: AnyObject]()
        for (key, json) in jsonDictionary {
            dictionary[key] = json.object
        }
        self.init(dictionary)
    }
    
    /// Private object
    /// @我: 私有变量,这里存放真真实的数据
    private var rawArray: [AnyObject] = []
    private var rawDictionary: [String : AnyObject] = [:]
    private var rawString: String = ""
    private var rawNumber: NSNumber = 0
    private var rawNull: NSNull = NSNull()
    /// Private type
    private var _type: Type = .Null
    /// prviate error
    private var _error: NSError? = nil
    
    /// Object in JSON
    /*
    计算属性object，提供get和set方法
    去存储真实类型和获得真实类型
    get方法:
    根据self.type获得真实类型
    根据类型获得对应的属性
    */
    public var object: AnyObject {
        get {
            switch self.type {
            case .Array:
                return self.rawArray
            case .Dictionary:
                return self.rawDictionary
            case .String:
                return self.rawString
            case .Number:
                return self.rawNumber
            case .Bool:
                return self.rawNumber
            default:
                return self.rawNull
            }
        }
        set {
            _error = nil
            switch newValue {
            case let number as NSNumber:
                if number.isBool {
                    _type = .Bool
                } else {
                    _type = .Number
                }
                self.rawNumber = number
            case  let string as String:
                _type = .String
                self.rawString = string
            case  _ as NSNull:
                _type = .Null
            case let array as [AnyObject]:
                _type = .Array
                self.rawArray = array
            case let dictionary as [String : AnyObject]:
                _type = .Dictionary
                self.rawDictionary = dictionary
            default:
                _type = .Unknown
                _error = NSError(domain: ErrorDomain, code: ErrorUnsupportedType, userInfo: [NSLocalizedDescriptionKey: "It is a unsupported type"])
            }
        }
    }
    
    /// json type
    // @我: 记录着真实JSON结构体中object的真实类型
    //      只提供get方法，要赋值需要用_type,不能用self.type
    public var type: Type { get { return _type } }
    
    /// Error in JSON
    public var error: NSError? { get { return self._error } }
    
    /// The static null json
    @available(*, unavailable, renamed="null")
    public static var nullJSON: JSON { get { return null } }
    public static var null: JSON { get { return JSON(NSNull()) } }
}

// MARK: - CollectionType, SequenceType, Indexable
// @我 构建小标？JSONIndex
extension JSON : Swift.CollectionType, Swift.SequenceType, Swift.Indexable {
    
    public typealias Generator = JSONGenerator
    
    public typealias Index = JSONIndex
    
    public var startIndex: JSON.Index {
        print(self.type)
        switch self.type {
        case .Array:
            return JSONIndex(arrayIndex: self.rawArray.startIndex)
        case .Dictionary:
            return JSONIndex(dictionaryIndex: self.rawDictionary.startIndex)
        default:
            return JSONIndex()
        }
    }
    
    public var endIndex: JSON.Index {
        switch self.type {
        case .Array:
            return JSONIndex(arrayIndex: self.rawArray.endIndex)
        case .Dictionary:
            return JSONIndex(dictionaryIndex: self.rawDictionary.endIndex)
        default:
            return JSONIndex()
        }
    }
    
    public subscript (position: JSON.Index) -> JSON.Generator.Element {
        switch self.type {
        case .Array:
            return (String(position.arrayIndex), JSON(self.rawArray[position.arrayIndex!]))
        case .Dictionary:
            let (key, value) = self.rawDictionary[position.dictionaryIndex!]
            return (key, JSON(value))
        default:
            return ("", JSON.null)
        }
    }
    
    /// If `type` is `.Array` or `.Dictionary`, return `array.empty` or `dictonary.empty` otherwise return `true`.
    public var isEmpty: Bool {
        get {
            switch self.type {
            case .Array:
                return self.rawArray.isEmpty
            case .Dictionary:
                return self.rawDictionary.isEmpty
            default:
                return true
            }
        }
    }
    
    /// If `type` is `.Array` or `.Dictionary`, return `array.count` or `dictonary.count` otherwise return `0`.
    public var count: Int {
        switch self.type {
        case .Array:
            return self.rawArray.count
        case .Dictionary:
            return self.rawDictionary.count
        default:
            return 0
        }
    }
    
    public func underestimateCount() -> Int {
        switch self.type {
        case .Array:
            return self.rawArray.underestimateCount()
        case .Dictionary:
            return self.rawDictionary.underestimateCount()
        default:
            return 0
        }
    }
    
    /**
     If `type` is `.Array` or `.Dictionary`, return a generator over the elements like `Array` or `Dictionary`, otherwise return a generator over empty.
     
     - returns: Return a *generator* over the elements of JSON.
     */
    public func generate() -> JSON.Generator {
        return JSON.Generator(self)
    }
}
// MARK: 下标结构体
/**
*  Equatable协议类型的解读
*  必须实现
*  public func ==(lhs: Self, rhs: Self) -> Bool
*/
/**
*  Comparable是继承Equatable
*  必须实现
*  因为Comparable继承Equatable, 在<=中就提供了==
*  <    <=  >=  >
*  这四种操作符
*/
/**
*  _Incrementable协议
*  对象生成器？生成自己的一个副本
*  必须实现
*  public func successor() -> Self
*/
public struct JSONIndex: ForwardIndexType, _Incrementable, Equatable, Comparable {
    /// 数组下标
    let arrayIndex: Int?
    /// 字典下标 My?
    let dictionaryIndex: DictionaryIndex<String, AnyObject>?
    
    let type: Type
    
    init(){
        self.arrayIndex = nil
        self.dictionaryIndex = nil
        self.type = .Unknown
    }
    
    init(arrayIndex: Int) {
        self.arrayIndex = arrayIndex
        self.dictionaryIndex = nil
        self.type = .Array
    }
    
    init(dictionaryIndex: DictionaryIndex<String, AnyObject>) {
        self.arrayIndex = nil
        self.dictionaryIndex = dictionaryIndex
        self.type = .Dictionary
    }
    
    ///
    public func successor() -> JSONIndex {
        switch self.type {
        case .Array:
            return JSONIndex(arrayIndex: self.arrayIndex!.successor())
        case .Dictionary:
            return JSONIndex(dictionaryIndex: self.dictionaryIndex!.successor())
        default:
            return JSONIndex()
        }
    }
}

// MARK: Equatable
public func ==(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.Array, .Array):
        return lhs.arrayIndex == rhs.arrayIndex
    case (.Dictionary, .Dictionary):
        return lhs.dictionaryIndex == rhs.dictionaryIndex
    default:
        return false
    }
}

// MARK: Comparable
public func <(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.Array, .Array):
        return lhs.arrayIndex < rhs.arrayIndex
    case (.Dictionary, .Dictionary):
        return lhs.dictionaryIndex < rhs.dictionaryIndex
    default:
        return false
    }
}

public func <=(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.Array, .Array):
        return lhs.arrayIndex <= rhs.arrayIndex
    case (.Dictionary, .Dictionary):
        return lhs.dictionaryIndex <= rhs.dictionaryIndex
    default:
        return false
    }
}

public func >=(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.Array, .Array):
        return lhs.arrayIndex >= rhs.arrayIndex
    case (.Dictionary, .Dictionary):
        return lhs.dictionaryIndex >= rhs.dictionaryIndex
    default:
        return false
    }
}

public func >(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.Array, .Array):
        return lhs.arrayIndex > rhs.arrayIndex
    case (.Dictionary, .Dictionary):
        return lhs.dictionaryIndex > rhs.dictionaryIndex
    default:
        return false
    }
}

// MARK: 遵守生成器结构体
/**
*  遵守GeneratorType生成器协议
*  1.关联的类型
*  2.public mutating func next() -> Self.Element?
*/
public struct JSONGenerator : GeneratorType {
    
    public typealias Element = (String, JSON)
    
    private let type: Type
    private var dictionayGenerate: DictionaryGenerator<String, AnyObject>?
    private var arrayGenerate: IndexingGenerator<[AnyObject]>?
    private var arrayIndex: Int = 0
    
    init(_ json: JSON) {
        self.type = json.type
        if type == .Array {
            self.arrayGenerate = json.rawArray.generate()
        }else {
            self.dictionayGenerate = json.rawDictionary.generate()
        }
    }
    
    public mutating func next() -> JSONGenerator.Element? {
        switch self.type {
        case .Array:
            if let o = self.arrayGenerate?.next() {
                return (String(self.arrayIndex++), JSON(o))
            } else {
                return nil
            }
        case .Dictionary:
            if let (k, v): (String, AnyObject) = self.dictionayGenerate?.next() {
                return (k, JSON(v))
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

// MARK: - Subscript

/**
*  To mark both String and Int can be used in subscript.
*  @我: JSON的下标描述
*/
public enum JSONKey {
    case Index(Int)
    case Key(String)
}

public protocol JSONSubscriptType {
    var jsonKey:JSONKey { get }
}

extension Int: JSONSubscriptType {
    public var jsonKey:JSONKey {
        return JSONKey.Index(self)
    }
}

extension String: JSONSubscriptType {
    public var jsonKey:JSONKey {
        return JSONKey.Key(self)
    }
}

// MARK: 拓展JSON, 添加下标脚本方法
extension JSON {
    
    /// If `type` is `.Array`, return json which's object is `array[index]`, otherwise return null json with error.
    /// @我: 如果json.object真实类型Array,那么返回下标的json，反正为数据为null的json
    private subscript(index index: Int) -> JSON {
        get {
            if self.type != .Array {
                var r = JSON.null
                r._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] failure, It is not an array"])
                return r
            } else if index >= 0 && index < self.rawArray.count {
                return JSON(self.rawArray[index])
            } else {
                var r = JSON.null
                r._error = NSError(domain: ErrorDomain, code:ErrorIndexOutOfBounds , userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] is out of bounds"])
                return r
            }
        }
        set {
            if self.type == .Array {
                if self.rawArray.count > index && newValue.error == nil {
                    self.rawArray[index] = newValue.object
                }
            }
        }
    }
    
    /// If `type` is `.Dictionary`, return json which's object is `dictionary[key]` , otherwise return null json with error.
    private subscript(key key: String) -> JSON {
        get {
            var r = JSON.null
            if self.type == .Dictionary {
                if let o = self.rawDictionary[key] {
                    r = JSON(o)
                } else {
                    r._error = NSError(domain: ErrorDomain, code: ErrorNotExist, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] does not exist"])
                }
            } else {
                r._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] failure, It is not an dictionary"])
            }
            return r
        }
        set {
            if self.type == .Dictionary && newValue.error == nil {
                self.rawDictionary[key] = newValue.object
            }
        }
    }
    
    /// If `sub` is `Int`, return `subscript(index:)`; If `sub` is `String`,  return `subscript(key:)`.
    /// @如果sub真实类型是个Int结构体,那么,那么走
    //      private subscript(index index: Int) -> JSON 方法
    //      sub是String,走
    //      private subscript(key key: String) -> JSON方法
    private subscript(sub sub: JSONSubscriptType) -> JSON {
        get {
            switch sub.jsonKey {
            case .Index(let index): return self[index: index]
            case .Key(let key): return self[key: key]
            }
        }
        set {
            switch sub.jsonKey {
            case .Index(let index): self[index: index] = newValue
            case .Key(let key): self[key: key] = newValue
            }
        }
    }
    
    /**
     Find a json in the complex data structuresby using the Int/String's array.
     
     - parameter path: The target json's path. Example:
     
     let json = JSON[data]
     let path = [9,"list","person","name"]
     let name = json[path]
     
     The same as: let name = json[9]["list"]["person"]["name"]
     
     - returns: Return a json found by the path or a null json with error
     */
     //@我 这个没有看明白reduce方法
     // 根据路径查找
    public subscript(path: [JSONSubscriptType]) -> JSON {
        get {
            // reduce-> 把数组元素组合起来，得到一个聚合值
            // reduce方法的原型大概是
            /*
            extension Array {
            func reduce<U>(var initial: U, combin: (U, Element) ->U) ->U{
            for item in self {
            initial = combine(initial, item)
            }
            return initial
            }
            }
            这里的$0[sub: $1]
            走的是JSON的
            private subscript(sub sub: JSONSubscriptType) -> JSON方法
            */
            return path.reduce(self) { $0[sub: $1] }
        }
        set {
            // 这里的Swift有作用想递归
            // 当count为1赋值
            switch path.count {
            case 0:
                return
            case 1:
                self[sub:path[0]].object = newValue.object
            default:
                var aPath = path; aPath.removeAtIndex(0)
                var nextJSON = self[sub: path[0]]
                // 用重写走了一遍
                nextJSON[aPath] = newValue
                self[sub: path[0]] = nextJSON
            }
        }
    }
    
    /**
     Find a json in the complex data structuresby using the Int/String's array.
     
     - parameter path: The target json's path. Example:
     
     let name = json[9,"list","person","name"]
     
     The same as: let name = json[9]["list"]["person"]["name"]
     
     - returns: Return a json found by the path or a null json with error
     */
    public subscript(path: JSONSubscriptType...) -> JSON {
        get {
            return self[path]
        }
        set {
            self[path] = newValue
        }
    }
}

// MARK: - LiteralConvertible

extension JSON: Swift.StringLiteralConvertible {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.IntegerLiteralConvertible {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.BooleanLiteralConvertible {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.FloatLiteralConvertible {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.DictionaryLiteralConvertible {
    
    public init(dictionaryLiteral elements: (String, AnyObject)...) {
        self.init(elements.reduce([String : AnyObject]()){(dictionary: [String : AnyObject], element:(String, AnyObject)) -> [String : AnyObject] in
            var d = dictionary
            d[element.0] = element.1
            return d
            })
    }
}

extension JSON: Swift.ArrayLiteralConvertible {
    
    public init(arrayLiteral elements: AnyObject...) {
        self.init(elements)
    }
}

extension JSON: Swift.NilLiteralConvertible {
    
    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
}
// MARK: 2016-01-21 看到了这里
// MARK: - Raw

extension JSON: Swift.RawRepresentable {
    // 创建
    public init?(rawValue: AnyObject) {
        if JSON(rawValue).type == .Unknown {
            return nil
        } else {
            self.init(rawValue)
        }
    }
    ///  拿到原始值
    public var rawValue: AnyObject {
        return self.object
    }
    
    // MARK: JSON->原始数据
    
    public func rawData(options opt: NSJSONWritingOptions = NSJSONWritingOptions(rawValue: 0)) throws -> NSData {
        guard NSJSONSerialization.isValidJSONObject(self.object) else {
            throw NSError(domain: ErrorDomain, code: ErrorInvalidJSON, userInfo: [NSLocalizedDescriptionKey: "JSON is invalid"])
        }
        
        return try NSJSONSerialization.dataWithJSONObject(self.object, options: opt)
    }
    
    public func rawString(encoding: UInt = NSUTF8StringEncoding, options opt: NSJSONWritingOptions = .PrettyPrinted) -> String? {
        switch self.type {
        case .Array, .Dictionary:
            do {
                let data = try self.rawData(options: opt)
                return NSString(data: data, encoding: encoding) as? String
            } catch _ {
                return nil
            }
        case .String:
            return self.rawString
        case .Number:
            return self.rawNumber.stringValue
        case .Bool:
            return self.rawNumber.boolValue.description
        case .Null:
            return "null"
        default:
            return nil
        }
    }
}

// MARK: - Printable, DebugPrintable
// @我 获取描述字符串
extension JSON: Swift.Printable, Swift.DebugPrintable {
    
    public var description: String {
        
        if let string = self.rawString(options:.PrettyPrinted) {
            return string
        } else {
            return "unknown"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - Array

extension JSON {
    
    //Optional [JSON]
    /// 将json.object是一个数组变为json数组,每个元素json的object唯一个数据
    public var array: [JSON]? {
        get {
            if self.type == .Array {
                return self.rawArray.map{ JSON($0) }
            } else {
                return nil
            }
        }
    }
    
    //Non-optional [JSON]
    public var arrayValue: [JSON] {
        get {
            return self.array ?? []
        }
    }
    
    //Optional [AnyObject]
    /// 将json.object是一个数组变为object数组
    public var arrayObject: [AnyObject]? {
        get {
            switch self.type {
            case .Array:
                return self.rawArray
            default:
                return nil
            }
        }
        set {
            if let array = newValue {
                self.object = array
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: - Dictionary

extension JSON {
    
    //Optional [String : JSON]
    public var dictionary: [String : JSON]? {
        if self.type == .Dictionary {
            return self.rawDictionary.reduce([String : JSON]()) { (dictionary: [String : JSON], element: (String, AnyObject)) -> [String : JSON] in
                var d = dictionary
                d[element.0] = JSON(element.1)
                return d
            }
        } else {
            return nil
        }
    }
    
    //Non-optional [String : JSON]
    public var dictionaryValue: [String : JSON] {
        return self.dictionary ?? [:]
    }
    
    //Optional [String : AnyObject]
    public var dictionaryObject: [String : AnyObject]? {
        get {
            switch self.type {
            case .Dictionary:
                return self.rawDictionary
            default:
                return nil
            }
        }
        set {
            if let v = newValue {
                self.object = v
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: - Bool

extension JSON: Swift.BooleanType {
    
    //Optional bool
    public var bool: Bool? {
        get {
            switch self.type {
            case .Bool:
                return self.rawNumber.boolValue
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(bool: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    //Non-optional bool
    public var boolValue: Bool {
        get {
            switch self.type {
            case .Bool, .Number, .String:
                return self.object.boolValue
            default:
                return false
            }
        }
        set {
            self.object = NSNumber(bool: newValue)
        }
    }
}

// MARK: - String

extension JSON {
    
    //Optional string
    public var string: String? {
        get {
            switch self.type {
            case .String:
                return self.object as? String
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = NSString(string:newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    //Non-optional string
    public var stringValue: String {
        get {
            switch self.type {
            case .String:
                return self.object as? String ?? ""
            case .Number:
                return self.object.stringValue
            case .Bool:
                return (self.object as? Bool).map { String($0) } ?? ""
            default:
                return ""
            }
        }
        set {
            self.object = NSString(string:newValue)
        }
    }
}

// MARK: - Number
extension JSON {
    
    //Optional number
    public var number: NSNumber? {
        get {
            switch self.type {
            case .Number, .Bool:
                return self.rawNumber
            default:
                return nil
            }
        }
        set {
            self.object = newValue ?? NSNull()
        }
    }
    
    //Non-optional number
    public var numberValue: NSNumber {
        get {
            switch self.type {
            case .String:
                let decimal = NSDecimalNumber(string: self.object as? String)
                if decimal == NSDecimalNumber.notANumber() {  // indicates parse error
                    return NSDecimalNumber.zero()
                }
                return decimal
            case .Number, .Bool:
                return self.object as? NSNumber ?? NSNumber(int: 0)
            default:
                return NSNumber(double: 0.0)
            }
        }
        set {
            self.object = newValue
        }
    }
}

//MARK: - Null
extension JSON {
    
    public var null: NSNull? {
        get {
            switch self.type {
            case .Null:
                return self.rawNull
            default:
                return nil
            }
        }
        set {
            self.object = NSNull()
        }
    }
    public func isExists() -> Bool{
        if let errorValue = error where errorValue.code == ErrorNotExist{
            return false
        }
        return true
    }
}

//MARK: - URL
extension JSON {
    
    //Optional URL
    public var URL: NSURL? {
        get {
            switch self.type {
            case .String:
                if let encodedString_ = self.rawString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                    return NSURL(string: encodedString_)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
        set {
            self.object = newValue?.absoluteString ?? NSNull()
        }
    }
}

// MARK: - Int, Double, Float, Int8, Int16, Int32, Int64

extension JSON {
    
    public var double: Double? {
        get {
            return self.number?.doubleValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(double: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var doubleValue: Double {
        get {
            return self.numberValue.doubleValue
        }
        set {
            self.object = NSNumber(double: newValue)
        }
    }
    
    public var float: Float? {
        get {
            return self.number?.floatValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(float: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var floatValue: Float {
        get {
            return self.numberValue.floatValue
        }
        set {
            self.object = NSNumber(float: newValue)
        }
    }
    
    public var int: Int? {
        get {
            return self.number?.longValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(integer: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var intValue: Int {
        get {
            return self.numberValue.integerValue
        }
        set {
            self.object = NSNumber(integer: newValue)
        }
    }
    
    public var uInt: UInt? {
        get {
            return self.number?.unsignedLongValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(unsignedLong: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var uIntValue: UInt {
        get {
            return self.numberValue.unsignedLongValue
        }
        set {
            self.object = NSNumber(unsignedLong: newValue)
        }
    }
    
    public var int8: Int8? {
        get {
            return self.number?.charValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(char: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int8Value: Int8 {
        get {
            return self.numberValue.charValue
        }
        set {
            self.object = NSNumber(char: newValue)
        }
    }
    
    public var uInt8: UInt8? {
        get {
            return self.number?.unsignedCharValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(unsignedChar: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt8Value: UInt8 {
        get {
            return self.numberValue.unsignedCharValue
        }
        set {
            self.object = NSNumber(unsignedChar: newValue)
        }
    }
    
    public var int16: Int16? {
        get {
            return self.number?.shortValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(short: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int16Value: Int16 {
        get {
            return self.numberValue.shortValue
        }
        set {
            self.object = NSNumber(short: newValue)
        }
    }
    
    public var uInt16: UInt16? {
        get {
            return self.number?.unsignedShortValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(unsignedShort: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt16Value: UInt16 {
        get {
            return self.numberValue.unsignedShortValue
        }
        set {
            self.object = NSNumber(unsignedShort: newValue)
        }
    }
    
    public var int32: Int32? {
        get {
            return self.number?.intValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(int: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int32Value: Int32 {
        get {
            return self.numberValue.intValue
        }
        set {
            self.object = NSNumber(int: newValue)
        }
    }
    
    public var uInt32: UInt32? {
        get {
            return self.number?.unsignedIntValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(unsignedInt: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt32Value: UInt32 {
        get {
            return self.numberValue.unsignedIntValue
        }
        set {
            self.object = NSNumber(unsignedInt: newValue)
        }
    }
    
    public var int64: Int64? {
        get {
            return self.number?.longLongValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(longLong: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int64Value: Int64 {
        get {
            return self.numberValue.longLongValue
        }
        set {
            self.object = NSNumber(longLong: newValue)
        }
    }
    
    public var uInt64: UInt64? {
        get {
            return self.number?.unsignedLongLongValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(unsignedLongLong: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt64Value: UInt64 {
        get {
            return self.numberValue.unsignedLongLongValue
        }
        set {
            self.object = NSNumber(unsignedLongLong: newValue)
        }
    }
}

//MARK: - Comparable
extension JSON : Swift.Comparable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.Number, .Number):
        return lhs.rawNumber == rhs.rawNumber
    case (.String, .String):
        return lhs.rawString == rhs.rawString
    case (.Bool, .Bool):
        return lhs.rawNumber.boolValue == rhs.rawNumber.boolValue
    case (.Array, .Array):
        return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.Dictionary, .Dictionary):
        return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.Null, .Null):
        return true
    default:
        return false
    }
}

public func <=(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.Number, .Number):
        return lhs.rawNumber <= rhs.rawNumber
    case (.String, .String):
        return lhs.rawString <= rhs.rawString
    case (.Bool, .Bool):
        return lhs.rawNumber.boolValue == rhs.rawNumber.boolValue
    case (.Array, .Array):
        return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.Dictionary, .Dictionary):
        return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.Null, .Null):
        return true
    default:
        return false
    }
}

public func >=(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.Number, .Number):
        return lhs.rawNumber >= rhs.rawNumber
    case (.String, .String):
        return lhs.rawString >= rhs.rawString
    case (.Bool, .Bool):
        return lhs.rawNumber.boolValue == rhs.rawNumber.boolValue
    case (.Array, .Array):
        return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.Dictionary, .Dictionary):
        return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.Null, .Null):
        return true
    default:
        return false
    }
}

public func >(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.Number, .Number):
        return lhs.rawNumber > rhs.rawNumber
    case (.String, .String):
        return lhs.rawString > rhs.rawString
    default:
        return false
    }
}

public func <(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.Number, .Number):
        return lhs.rawNumber < rhs.rawNumber
    case (.String, .String):
        return lhs.rawString < rhs.rawString
    default:
        return false
    }
}

private let trueNumber = NSNumber(bool: true)
private let falseNumber = NSNumber(bool: false)
private let trueObjCType = String.fromCString(trueNumber.objCType)
private let falseObjCType = String.fromCString(falseNumber.objCType)

// MARK: - NSNumber: Comparable

extension NSNumber {
    var isBool:Bool {
        get {
            let objCType = String.fromCString(self.objCType)
            if (self.compare(trueNumber) == NSComparisonResult.OrderedSame && objCType == trueObjCType)
                || (self.compare(falseNumber) == NSComparisonResult.OrderedSame && objCType == falseObjCType){
                    return true
            } else {
                return false
            }
        }
    }
}

func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedSame
    }
}

func !=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs == rhs)
}

func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
    }
}

func >(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == NSComparisonResult.OrderedDescending
    }
}

func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != NSComparisonResult.OrderedDescending
    }
}

func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != NSComparisonResult.OrderedAscending
    }
}

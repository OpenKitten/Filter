import Foundation

enum Operator {
    case equals, notEquals, greater, less, greaterEquals, lessEquals
}

enum ParsingState {
    case start
    case none
    case key(from: Int)
    case keyParsed(ArraySlice<UInt8>)
    case function(from: Int, key: ArraySlice<UInt8>)
    case grouped(layer: Int)
    case operation(Operator, key: ArraySlice<UInt8>)
}

struct Query {
    
}

extension UInt8 {
    static let space: UInt8 = 0x20
    static let stringQuote: UInt8 = 0x22
    static let and: UInt8 = 0x26
    static let leftParenthesis: UInt8 = 0x28
    static let rightParenthesis: UInt8 = 0x29
    static let multiply: UInt8 = 0x2a
    static let plus: UInt8 = 0x2b
    static let comma: UInt8 = 0x2c
    static let minus: UInt8 = 0x2d
    static let dot: UInt8 = 0x2e
    static let divide: UInt8 = 0x2f
    static let colon: UInt8 = 0x3a
    static let less: UInt8 = 0x3c
    static let equal: UInt8 = 0x3d
    static let greater: UInt8 = 0x3e
    static let codeBlockOpen: UInt8 = 0x7b
    static let pipe: UInt8 = 0x7c
    static let codeBlockClose: UInt8 = 0x7d
    static let a: UInt8 = 0x61
    static let z: UInt8 = 0x71
    static let A: UInt8 = 0x41
    static let Z: UInt8 = 0x51
}

fileprivate var parsingState: ParsingState = .start
fileprivate var query = Query()

func isAlphabetical(byte: UInt8) -> Bool {
    return (byte >= .a && byte <= .z) || (byte >= .A && byte <= .Z)
}

func isNumerical(byte: UInt8) -> Bool {
    return byte >= 0x30 && byte <= 0x39
}

func parse(_ string: [UInt8]) {
    var position = 0
    
    func skipSpaces() {
        while position < string.count, string[position] == .space {
            position = position &+ 1
        }
    }
    
    while position < string.count {
        let byte = string[position]
        
        switch parsingState {
        case .start:
            if byte == .leftParenthesis {
                parsingState = .grouped(layer: 1)
            } else if isAlphabetical(byte: byte) {
                parsingState = .key(from: position)
            }
            
            position = position &+ 1
        case .none:
            if byte == .pipe || byte == .and {
                guard string[position + 1] == byte else {
                    fatalError()
                }
                
                if byte == .pipe {
                    print("OR")
                } else {
                    print("AND")
                }
                
                position = position &+ 2
                skipSpaces()
                parsingState = .start
            } else {
                fatalError()
            }
        case .key(let from):
            if byte == .space {
                parsingState = .keyParsed(string[from..<position])
                position = position &+ 1
                skipSpaces()
            } else if byte == .dot {
                parsingState = .function(from: position, key: string[from..<position])
                position = position &+ 1
                skipSpaces()
            } else {
                if isAlphabetical(byte: byte) {
                    position = position &+ 1
                } else {
                    parsingState = .keyParsed(string[from..<position])
                }
            }
        case .keyParsed(let key):
            guard position + 1 < string.count else {
                fatalError()
            }
            
            switch byte {
            case .less:
                if string[position + 1] == .equal {
                    position = position &+ 2
                    parsingState = .operation(.lessEquals, key: key)
                } else {
                    position = position &+ 1
                    parsingState = .operation(.less, key: key)
                }
                
                skipSpaces()
            case .greater:
                if string[position + 1] == .equal {
                    position = position &+ 2
                    parsingState = .operation(.greaterEquals, key: key)
                } else {
                    position = position &+ 1
                    parsingState = .operation(.greater, key: key)
                }
                
                skipSpaces()
            case .equal:
                guard string[position + 1] == .equal else {
                    fatalError()
                }
                
                position = position &+ 2
                skipSpaces()
                parsingState = .operation(.equals, key: key)
            default:
                fatalError()
            }
        case .grouped(let layer):
            fatalError()
        case .function(let from, let key):
            fatalError()
        case .operation(let op, let key):
            if isNumerical(byte: byte) {
                var bytes = [byte]
                position = position &+ 1
                
                loop: while position < string.count {
                    if string[position] == .space {
                        break loop
                    }
                    
                    guard isNumerical(byte: string[position]) else {
                        fatalError()
                    }
                    
                    bytes.append(string[position])
                    position = position &+ 1
                    
                }
                
                print(String(bytes: key, encoding: .utf8))
                print(op)
                print(String(bytes: bytes, encoding: .utf8))
                skipSpaces()
                parsingState = .none
            } else {
                // bool, string, double, ...
                fatalError()
            }
        }
    }
}

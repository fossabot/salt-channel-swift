//  ByteUtils.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

extension UInt32 {
    
    enum ByteOrder {
        case BigEndian
        case LittleEndian
    }
    
    func toBytes(_ order: ByteOrder = .LittleEndian) -> [UInt8] {
        var bytes: [UInt8] = [0, 0, 0, 0]
        var value: UInt32 = self.littleEndian
        if order == .BigEndian {
            value = self.bigEndian
        }
        bytes[0] = UInt8(value & 0x000000FF)
        bytes[1] = UInt8((value & 0x0000FF00) >> 8) //0x12345678 => 0x00005600 >> 8 => 0x00000056
        bytes[2] = UInt8((value & 0x00FF0000) >> 16)
        bytes[3] = UInt8((value & 0xFF000000) >> 24)
        return bytes
    }
    
    static func fromBytes(_ sizeBytes: [UInt8], order: ByteOrder = .LittleEndian) -> UInt32 {
        var value: UInt32 = 0
        value += UInt32(sizeBytes[0])
        value += UInt32(sizeBytes[1]) << 8
        value += UInt32(sizeBytes[2]) << 16
        value += UInt32(sizeBytes[3]) << 24
        if order == .BigEndian {
            return value.bigEndian
        }
        return value
    }
}

public func packBytes(_ value: UInt64, parts: Int) -> Data {
    precondition(parts > 0)
    
    let bytesw = stride(from: (8 * (parts - 1)), through: 0, by: -8).map { shift in
        return UInt8(truncatingIfNeeded: value >> UInt64(shift))
    }
    
    return Data(bytesw)
}
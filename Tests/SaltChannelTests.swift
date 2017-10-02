//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.
//  Copyright © 2017 Håkan Olsson. All rights reserved.

import XCTest
import Sodium
import CocoaLumberjack

@testable import SaltChannel

class SaltChannelHostMock : ByteChannel {
    var didReceiveMsg = false
    var readData: Data = Data()
    var writeData: [Data] = []
    
    let m1 = sodium.utils.hex2bin("534376320100000000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")!
    let m2 = sodium.utils.hex2bin("020000000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f")!
    
    let m3 = sodium.utils.hex2bin("0600669544da0d2ec8a03766f53e0580bc3cc6cddb69b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb329899ab741476448b5f34e6513e1d3cec7469fbf03112a098acd397ab933c61a2319eb6e0b4561ed9ce010d998f5bc10d6d17f88cebf961d1377faccc8a781c2c")!
    let m4: Data = sodium.utils.hex2bin("0600a342f9538471d266100bfc3b9e794f40b32ffd053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0eb6856903f7f1006e43d7e21915f72e729a26bf6bc5f59bc7ed2e1456a8a5fc9ecc6e2cd3c48e0103769ccd6faa87e45b8b256207a2e341cd068d433c7296fb374")!
    let d1 = sodium.utils.hex2bin("06005089769da0def9f37289f9e5ff6e78710b9747d8a0971591abf2e4fb")!
    let d2 = sodium.utils.hex2bin("060082eb9d3660b82984f3c1c1051f8751ab5585b7d0ad354d9b5c56f755")!
    
    func start() {

        DispatchQueue.global().async {
            self.handShake()
        }
    }
    
    func handShake() {
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m1)
            self.didReceiveMsg = false
        }
        sleep(4)
        readData = m2
        delegate?.didReceiveMessage()
        
        sleep(4)
        readData = m3
        delegate?.didReceiveMessage()
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m4)
            self.didReceiveMsg = false
        }
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], d1)
            self.didReceiveMsg = false
        }
        
        sleep(4)
        readData = d2
        delegate?.didReceiveMessage()
    }
    
    override func write(_ data: [Data]) throws {
        print("write is called")
        writeData = data
        didReceiveMsg = true
    }
    
    override func read() throws -> Data {
        print("read is called")
        return readData
    }
}

class SaltChannelTests: XCTestCase {
    let sodium = Sodium()

    func testHandshake() {
        
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true

        let clientSignSec = sodium.utils.hex2bin("55f4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientSignPub = sodium.utils.hex2bin("5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncSec = sodium.utils.hex2bin("77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")!
        let clientEncPub = sodium.utils.hex2bin("8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")!
        let serverSignPub = sodium.utils.hex2bin("07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        
        let r1 = sodium.utils.hex2bin("010505050505")!
        let r2 = sodium.utils.hex2bin("010505050505")!
        
        let mock = SaltChannelHostMock()
        mock.start()
        let channel = SaltChannel(channel: mock, clientSignSec: clientSignSec, clientSignPub: clientSignPub)
        
        XCTAssertThrowsError(try channel.getRemoteSignPub()) { error in
            XCTAssertEqual(error as? SaltChannel.SaltChannelError, SaltChannel.SaltChannelError.setupNotDone)
        }
        
        do {
            try channel.handshake(clientEncSec: clientEncSec, clientEncPub: clientEncPub)
        
            XCTAssertEqual(try channel.getRemoteSignPub(), serverSignPub)
        
            try channel.write([r1])
            
            channel.didReceiveMsg = false
            if WaitUntil.waitUntil(10, channel.didReceiveMsg == true) {
                let data = try! channel.read()
                XCTAssertEqual(data, r2)
            }
            

        } catch {
            print(error)
            XCTAssertTrue(false)
        }
    }
}
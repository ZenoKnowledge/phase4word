//
//  CryptoService.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/21/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import SwiftyRSA
import CryptoSwift


class CryptoService {
//
//    let secretKey: SecKey?
//    let publicKey: SecKey?
//    let pubKey16: String?
//
    static let shared = CryptoService()
    
    private init() {
//        secretKey = try! retrieveKey()
//        publicKey = SecKeyCopyPublicKey(secretKey!)
//        pubKey16 = secKeyToHexString(key: publicKey)
    }

    
    
    /*
    func secGenerateKeys() throws -> SecKey {
        
        // how do I get the secure enclave working? it crashes on me
        let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                            .privateKeyUsage,
                                            nil)!   // Ignore error
        let tag = "online.phase4.keys".data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrType as String:            kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String:   256,
//             kSecAttrTokenID as String:         kSecAttrTokenIDSecureEnclave,
             kSecPrivateKeyAttrs as String: [
                 kSecAttrIsPermanent as String:    true,
                 kSecAttrApplicationTag as String: tag,
                 kSecAttrAccessControl as String:  access
             ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
//        let publicKey = SecKeyCopyPublicKey(privateKey)
//
        return privateKey
    } */
    
    func generateKey() throws -> SecKey {
        //this function does not have the secure enclave token. it seems to work.

//        let access =
//            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
//                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//                                            .privateKeyUsage,
//                                            nil)!   // Ignore error
        let tag = ("online.phase4.keys").data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrType as String:            kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String:   4096,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String: true,
                 kSecAttrApplicationTag as String: tag,
//                 kSecAttrAccessControl as String: access
                ]
        ]

        var error: Unmanaged<CFError>?
        guard let secretKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return secretKey
    }

    

    func retrieveKey() throws -> SecKey {
        let tag = ("online.phase4.keys").data(using: .utf8)!
        
        let query: [String: Any] =
            [kSecClass as String: kSecClassKey,
             kSecAttrApplicationTag as String: tag,
             kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
             kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw CryptoError.cannotRetrieveKey }
        let key = item as! SecKey
        
        return key
    }
    
    
    func secKeyToHexString(key: SecKey?) -> String {
            var b16key = ""
            var error:Unmanaged<CFError>?
            if let cfdata = SecKeyCopyExternalRepresentation(key!, &error) {
                let data = cfdata as Data
                b16key = data.hexDescription
                print(b16key)
            }
            return b16key
    }
    
    func secKeyToData(key: SecKey?) -> Data? {
        var error:Unmanaged<CFError>?
        return SecKeyCopyExternalRepresentation(key!, &error) as Data?
    }
    
    
    
    func algotest(_ privateKey: SecKey, algorithm: SecKeyAlgorithm) {
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            print("error")
            return
        }
    }

//    func sign(privateKey: SecKey, data: Data) throws -> String {
//        
//        var error: Unmanaged<CFError>?
//        let rsa: SecKeyAlgorithm = .ecdsaSignatureDigestX962SHA256
//        guard let signature = SecKeyCreateSignature(privateKey, rsa, data as CFData, &error) as Data? else {
//            throw CryptoError.stdError
//        }
//        
//        return String(data: signature, encoding: .utf8)!
//    }
    
//    func verify(publicKey: SecKey, data: Data, signature: Data) throws -> Bool {
//        var error: Unmanaged<CFError>?
//        let rsa: SecKeyAlgorithm = .rsaSignatureDigestPKCS1v15SHA256
//        guard SecKeyVerifySignature(publicKey, rsa, data as CFData, signature as CFData, &error) else {
//            throw CryptoError.stdError
//        }
//
//        return true
//
//    }

    
    func sign(key: Key, data: Data) -> String {
        let clear = ClearMessage(data: data)
        let signed = try! clear.signed(with: key as! PrivateKey, digestType: .sha256)
        print("\n\n\n" + signed.base64String)
        print("\n\n\n" + signed.data.hexDescription)
        return signed.base64String
    }
    
    func verify(publicKey: Key, data: Data, base64EncSignature: String) -> Bool {
        let signature = try! Signature(base64Encoded: base64EncSignature)
        let clear = ClearMessage(data: data)
        let isSuccessful = try! clear.verify(with: publicKey as! PublicKey, signature: signature, digestType: .sha256)
        
        return isSuccessful
    }


    enum CryptoError: Error {
        case stdError
        case cannotRetrieveKey
        
    }

    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    func cha20IvMaker(digest: String) -> [UInt8] {
        // this function takes a sha256 digest (64 bytes) and returns the first 8 bytes in an array
        let bytes = digest.bytes
        
        let index0 = bytes.index(bytes.startIndex, offsetBy: 8)
        
        let nonce = Array(bytes[..<index0])
        
//        let nonce: [UInt8] = Array(string0.utf8)

        print("nonce.count \(nonce.count)")
        return nonce
    }
    
    func encryptData(data: Data, code: String) -> [UInt8] {
        let key = Array(code.sha256().sha256().bytes.dropFirst(32))
        let iv = cha20IvMaker(digest: code.sha256())
        let cipherData = try! ChaCha20(key: key, iv: iv).encrypt(data.bytes)
        return cipherData
    }

    func decryptBytes(bytes: [UInt8], code: String) -> Data {
        let key = Array(code.sha256().sha256().bytes.dropFirst(32))
        let iv = cha20IvMaker(digest: code.sha256())
        let decrypted = try! ChaCha20(key: key, iv: iv).decrypt(bytes)
        let data = Data(bytes: decrypted)
        return data
    }
    
    
    
//    func aesEncrypt(data: Data, code: String) -> ([UInt8], String) {
//        let digest = data.hexDescription.sha256()
//        let key = String(digest.sha256().dropFirst(32))
//        let iv = String(code.sha256().dropFirst(48))
//        print("key, iv", key, iv, key.bytes.count, iv.bytes.count)
//        let cipherData = try! AES(key: key, iv: iv).encrypt(data.bytes)
//        return (cipherData, digest)
//    }
//
//    func aesDecrypt(cipherData: [UInt8], digest: String, code: String) -> Data {
//        let key = String(digest.sha256().dropFirst(32))
//        let iv = String(code.sha256().dropFirst(48))
//        let decryptedBytes = try! AES(key: key, iv: iv).decrypt(cipherData)
//        let data = Data(bytes: decryptedBytes)
//
//        return data
//    }
    
    
    

    func shaDivider(digest: String) -> (seg0: [UInt8], seg1: [UInt8])? {
        // this function takes a sha256 digest (64 bytes) and splits it into a tuple containing 2 (32 byte) arrays
        
        guard digest.count == 64 else { return nil }
        print("count == 64")
        let index0 = digest.index(digest.startIndex, offsetBy: 32)
        let index1 = digest.index(index0, offsetBy: 32)
        
        guard index1 == digest.endIndex else { return nil }
        print("index1 == digest.endIndex")
        let string0 = String(digest[..<index0])
        let string1 = String(digest[index0..<index1])
        
        let seg0: [UInt8] = Array(string0.utf8)
        let seg1: [UInt8] = Array(string1.utf8)
        
        return (seg0, seg1)
        
    }
}
extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension String {
    
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: sha2(input: stringData as NSData))
        }
        return ""
    }
    
    private func sha2(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}

extension Data {
    
    //returns a Base 16 encoded string
//    func sha256() -> String {
//        let digest = sha2(input: self as NSData)
//        return hexStringFromData(input: digest)
//    }
    func sha256data() -> Data {
        let digest = sha2(input: self as NSData)
        return digest as Data
    }
    
    private func sha2(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}

//
//  Ping.swift
//  iOS Ping
//
//  Created by Richard Stockdale on 07/08/2019.
//  Copyright © 2019 RGB Consulting. All rights reserved.
//

import Foundation

public class Ping {
    
    public enum PingResult {
        case pingDidFail
        case pingDidTimeOut
        case pingDidSucceed
        
        public func description() -> String {
            switch self {
            case .pingDidFail:
                return "Failed"
            case .pingDidTimeOut:
                return "Timed out"
            case .pingDidSucceed:
                return "Success"
            }
        }
    }
    
    public typealias CompletionBlock = (PingResult, String) -> Void
    
    private var simplePing: SimplePing
    private var completionCallback: CompletionBlock
    private var sendTimer: Timer?
    private var startTime: TimeInterval?
    
    public private(set) var host: String
    
    public init(hostName: String, completion: @escaping CompletionBlock) {
        host = hostName
        simplePing = SimplePing(hostName: hostName, addressStyle: .icmpV4)
        completionCallback = completion
        simplePing.delegate = self
    }
    
    public func sendPing() { // TODO: Add a completion handler
        simplePing.start()
        sendTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { [weak self] (timer) in
            self?.completionCallback(.pingDidTimeOut, "Timed out")
        })
    }
}

// MARK: - Helper Methods
extension Ping {
    fileprivate func displayAddress(for address: Data) -> String {
        var error = Int32(0)
        let hostStrDataCount = Int(NI_MAXHOST)
        var hostStrData = Data(count: hostStrDataCount)
        hostStrData.withUnsafeMutableBytes{ (hostStrPtr: UnsafeMutablePointer<Int8>) in
            address.withUnsafeBytes{ (sockaddrPtr: UnsafePointer<sockaddr>) in
                error = getnameinfo(sockaddrPtr, socklen_t(address.count), hostStrPtr, socklen_t(hostStrDataCount), nil, 0, NI_NUMERICHOST)
            }
        }
        
        if error == 0, let hostStr = String(data: hostStrData, encoding: .ascii) {
            return hostStr
        }
        else {
            return "?"
        }
    }
    
    fileprivate func shortError(from error: Error) -> String {
        let nsError = error as NSError
        
        /* *** Handle DNS errors as a special case. *** */
        if nsError.domain == kCFErrorDomainCFNetwork as String && nsError.code == Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) {
            if let failure = (nsError.userInfo[kCFGetAddrInfoFailureKey as String] as? NSNumber)?.int32Value,
                failure != 0,
                let failureCStr = gai_strerror(failure), let failureStr = String(cString: failureCStr, encoding: .ascii)
            {
                return failureStr /* To do things perfectly we should punny-decode the error message… */
            }
        }
        
        /* *** Otherwise try various properties of the error object. *** */
        return nsError.localizedFailureReason ?? nsError.localizedDescription
    }
    
    fileprivate func getMilisecondsTaken() -> String {
        let now = NSDate().timeIntervalSince1970
        let diff = now - startTime!
        
        let ms = diff * 1000
        
        return "\(Double(round(1000*ms)/1000))"
    }
}

// MARK: - Delegate methods
extension Ping: SimplePingDelegate {
    public func simplePing(_ pinger: SimplePing, didStart address: Data) {
        print("Pinging: ", displayAddress(for: address))
        startTime = Date().timeIntervalSince1970
        simplePing.sendPing(data: nil)
    }
    
    public func simplePing(_ pinger: SimplePing, didFail error: Error) {
        simplePing.stop()
        sendTimer?.invalidate()
        completionCallback(.pingDidFail, shortError(from: error))
    }
    
    public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        print("Sent ping \(UInt(sequenceNumber))")
    }
    
    public func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        simplePing.stop()
        sendTimer?.invalidate()
        completionCallback(.pingDidFail, shortError(from: error))
    }
    
    public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        print("Ping \(UInt(sequenceNumber)) response received. Size \(size_t(packet.count))")
        simplePing.stop()
        sendTimer?.invalidate()
        completionCallback(.pingDidSucceed, "\(UInt(sequenceNumber)) in \(getMilisecondsTaken())ms. Size \(size_t(packet.count))")
    }
    
    public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        print("Ping response of unexpected size received. Size: \(size_t(packet.count))")
        simplePing.stop()
        sendTimer?.invalidate()
        completionCallback(.pingDidSucceed, "Unexpected packet size: \(size_t(packet.count))")
    }
}

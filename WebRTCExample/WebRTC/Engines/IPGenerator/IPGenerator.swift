//
//  IPGenerator.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation

protocol IPGeneratorProtocol {
    func getIPAddress() -> String?
}

final class IPGenerator: IPGeneratorProtocol {
    func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    if let name = String(validatingUTF8: interface.ifa_name), name == "en0" {
                        var addr = interface.ifa_addr.pointee
                        let bufferSize = Int(NI_MAXHOST)
                        var hostName = [CChar](repeating: 0, count: bufferSize)
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostName, socklen_t(bufferSize),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostName)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

# SwiftPing
A network Ping implementation for iOS. Written in Swift.

A wrapper for [SimpleSwiftPing](https://github.com/Frizlab/SimpleSwiftPing) by François Lamboley and example application.

## Usage

    let ping = Ping.init(hostName: hostName!, completion: { (result, message) in
	    
	    // Do something with the response.
	    
    })
    ping?.sendPing()



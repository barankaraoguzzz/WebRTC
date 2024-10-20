# WebRTCExample

## Overview
`WebRTCExample` is a small project to demonstrate the capability of WebRTC in order to create a real time communication between clients over a peer-to-peer connection. Among the others, it includes SDP manager, ICE candidates exchanging and local/remote video rendering.

This is a **Swift** project using the **WebRTC** framework. From an architectural point of view this project has followed the MVVM architecture pattern in which each of the concerns' layers was separated: signaling, parsing data, socket communication and so on.

### Important Note:
The project uses **UDP** to communicate between clients. This will then only work if both clients are on the **same WiFi network**. Note that for connectivity, devices should be on the same local network.

## Project Structure

### 1. WebRTCClient

The `WebRTCClient` class encapsulates a peer-to-peer connection through WebRTC. It wraps the creation of offers and answers, ICE candidate exchange, and setup of local and remote video streams.

**Key Responsibilities:**
WebRTC connections management - setup, connect, disconnect.
 Creating of offers and answers with SDP.
 ICE candidates handling.
 Management of local audio/video, switching of front / back cameras.

Protocols:
 `WebRTCClientDelegate`: Callbacks about changes of connection state, generation of ICE candidate and changes in signaling state.
- `WebRTCClientProtocol`: This describes the public interface that should be used by `WebRTCClient` for managing the connection and for sending/receiving offers/candidates, or changing media settings like mute, speaker and switch camera.

- **Usage:**
 You can create a WebRTC connection by `connect()`, create an offer with `makeOffer()`, or process an incoming offer/answer using `receiveOffer()` and `receiveAnswer()` respectively.

### 2. CallViewModel
The CallViewModel mediates between WebRTCClient and the UI. It controls the flow of a call process, creating an offer, showing and handling local and remote video streams.

- **Key Responsibilities:**
  - Handles user input from UI: for example, calling button press, mute, speaker, switch camera.
  - Manages WebRTC connection lifecycle.
- Processes incoming signalling messages (offers, answers and ICE candidates), and sends outgoing ones.
  - Coordinates the UI updates due to changes of the connection state.

## CallViewModelProtocol

The `CallViewModelProtocol` describes the required methods that will be utilized by `CallViewModel` to communicate with the UI. This is the bridge between the `ViewModel` and the `ViewController`, enabling the UI to perform anything from making a call, refreshing user information, to handling the actions of a call.

### Methods:

* `didTapCallButton()`: Called when the user presses the "Call" button. It establishes the WebRTC connection and sends an offer.
- `updateAlias(value: String)`: Updates the alias value that the user enters. This alias is used while sending the signaling message.

- `updateRemoteIpAddress(value: String)`: Updates the remote IP address entered by the user. This IP is used for connecting to another peer on the same network.

- `didTapAcceptButton()`: An event when the user accepts an incoming call. It receives the offer and returns an answer.
• `didTapRejectButton()`: Called when a user has to reject an incoming call. It disconnects the current WebRTC session.
 
• `didTapMeetingViewActions(type: MeetingView.ButtonType)`: Allows for in-call actions like toggling mute, enabling/disabling speaker, switching camera, or ending the call. The `MeetingView.ButtonType` parameter specifies the kind of action, such as mute, speaker, switch camera.

These ensure the correct binding of the ViewModel to the ViewController for the smooth passage of information between UI and business logic during a WebRTC call session.

- **Protocols:**
  - `CallViewModelProtocol`: Defines what actions should be handled by the `CallViewModel`, such as making a call, accepting a call, and updating alias/IP.
  - `ActionSendable`: Provides an abstraction to send actions, such as updating the UI.

### 3. SignalParser
The `SignalParser` is utilized for encoding and decoding signaling messages - offer, answer, and ICE candidates - to JSON format and vice-versa. It uses Swift's `Codable` protocol for encoding/decoding.

- **Key Responsibilities:**
  - Convert signaling messages to JSON data.
  - Parse JSON data back into signaling message models.

- **Methods:**
  - `parseToData(_:)`: Converts a `SignalingMessage` into `Data` format (JSON).
  - `parseToString(_:)`: Converts a `SignalingMessage` into a JSON `String`.

### 4. SignalGenerator
The `SignalGenerator` generates signaling messages (`SignalingMessage`) based on session descriptions or ICE candidates.

- **Key Responsibilities:**
  - Create a signaling message from an SDP offer/answer.
  - Create a message from an ICE candidate.

### 5. LocalSocketConnecter & LocalSocketDataNotifier
These classes control socket communication. `LocalSocketConnecter` controls the real socket connection and listens for coming data. `LocalSocketDataNotifier` observes and processes coming signaling messages.

- **Key Responsibilities:**
- Send/receive messages on a local UDP socket.
  - Notify the `CallViewModel` when messages are received.

- **Methods:**
  - `listen()`: Starts the UDP listener.
  - `send(message:to:)`: Sends a message to a remote host.

## Testing

This project uses comprehensive unit tests via **XCTest** to ensure that the WebRTC operations, signaling, and socket communication flow logically work as intended.

### Key Tests:

**LocalSocketDataNotifierTests:** Verifies that the notifier listens for incoming signaling messages and notifies the appropriate components, ensuring the proper handling of signaling data through UDP communication.

**CallViewModel Tests:** Tests the main logic of a call, which among other things, ensures that:

`didTapCallButton()` initiates the connection and prepares and sends an offer.
`didTapAcceptButton()` processes the incoming offer and prepares the answer.
`didTapMeetingViewActions()` toggles mute, speaker, and switch camera actions correctly.

### Example Test:

```swift
    func testShouldReceiveSignalingMessage() {
        let expectation = expectation(description: "Observe signaling message")
        let expectedSignalingMessage = SignalingMessage(type: "offer", sessionDescription: nil, senderProp: nil, candidate: nil)
        
        mockSignalGenerator.mockSignalMessage = expectedSignalingMessage
        
        dataNotifier.startListening()
        dataNotifier.observe { signalingMessage in
            XCTAssertEqual(signalingMessage.type, expectedSignalingMessage.type)
            expectation.fulfill()
        }
        mockSocketConnecter.messageReceivedCallback?("IncomingMessage")
        waitForExpectations(timeout: 1, handler: nil)
    }
```
## Running Tests

To run the tests, launch the project using Xcode and execute all tests using `Cmd+U`, or use the menu option `Product > Test`.

## Installation

1. Clone the repository:
   ```bash
    git clone https://github.com/your-username/WebRTCExample.git
   ```
2. If using CocoaPods, run `pod install`, or ensure that the WebRTC framework is installed via Swift Package Manager.
3. Open project in Xcode:
   ```bash
   open WebRTCExample.xcodeproj
   ```
4. Build and run on simulator or device.

## Dependencies

* **WebRTC Framework**: This project uses a WebRTC framework for handling peer-to-peer video and audio communication.
- **Combine**: This is the basic framework for reactive programming and data binding within the app.
- **AtomicDesignSystem**: A local package that encapsulates the project's design system, providing reusable components for **fonts** and **colors**. It helps maintain consistency across the app by centralizing UI styling.
- **IQKeyboardManager**: A library for managing the keyboard when a user needs to interact with text fields in an easier way since it does not let the keyboard cover up UI elements. Helps you manage the keyboard, so you do not need to write extra code in its management.
atomic-design-system: A local package that wraps the design system of the project. It exports reusable components for fonts and colors. Having UI styles in a central place pays a lot in keeping the app consistent.
 XCTest: For writing and running unit tests.
- **XCTest**: For writing and running unit tests.




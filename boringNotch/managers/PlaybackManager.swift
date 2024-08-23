import SwiftUI
import AppKit
import Combine

import CoreAudio
import AudioToolbox

class PlaybackManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isMuted = 0
    @Published var MrMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    
    init() {
        self.isPlaying = false
        self.isMuted = 0
        self.MrMediaRemoteSendCommandFunction = { _, _ in }
        handleLoadMediaHandlerApis()
    }
    
    private func handleLoadMediaHandlerApis() {
        // Load framework
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else { return }
        
        // Get a Swift function for MRMediaRemoteSendCommand
        guard let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) else { return }
        
        typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, AnyObject?) -> Void
        
        MrMediaRemoteSendCommandFunction = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)
    }
    
    deinit {
        self.MrMediaRemoteSendCommandFunction = { _, _ in }
    }
    
    func playPause() -> Bool {
        if self.isPlaying {
            MrMediaRemoteSendCommandFunction(2, nil)
            self.isPlaying = false
            return false
        } else {
            MrMediaRemoteSendCommandFunction(0, nil)
            self.isPlaying = true
            return true
        }
    }
    
        
    func nextTrack() {
        // Implement next track action
        MrMediaRemoteSendCommandFunction(4, nil)
    }
    
    func previousTrack() {
        // Implement previous track action
        MrMediaRemoteSendCommandFunction(5, nil)
    }
    
    func muteUnmute() {
        var defaultOutputDeviceID = AudioObjectID(kAudioObjectSystemObject)
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        
        var defaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        // Get the default output device ID
        let status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &defaultOutputDevicePropertyAddress,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )
        
        guard status == noErr else {
            print("Error getting default output device: \(status)")
            return
        }

        // Get the mute property
        var mute: UInt32 = 0
        propertySize = UInt32(MemoryLayout<UInt32>.size)
        var mutePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let muteStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &mutePropertyAddress,
            0,
            nil,
            &propertySize,
            &mute
        )
        
        guard muteStatus == noErr else {
            print("Error getting mute status: \(muteStatus)")
            return
        }

        // Toggle mute state
        mute = (mute == 0) ? 1 : 0
        
        let setMuteStatus = AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &mutePropertyAddress,
            0,
            nil,
            propertySize,
            &mute
        )
        
        guard setMuteStatus == noErr else {
            print("Error setting mute status: \(setMuteStatus)")
            return
        }
        self.isMuted = Int(mute)
        print("Mute status changed to: \(mute == 1 ? "Muted" : "Unmuted")")
    }

}

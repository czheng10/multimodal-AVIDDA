# AVIDDA: Accessible Video-based Interface for Driver Drowsiness Alerts

## Table of Contents
All of our code can be found under the "AVIDDA/" subdirectory, so we will go over this in detail:
- AVIDDA/
    - `Assets.xcassets/` - subdirectory holding asset files such as app logo and app icon design
    - `AVIDDAApp.swift` - main entry point of our application
    - `ContentView.swift` - main UI page of our application, where the map, camera recording, and alerts will be displayed
    - `FrameHandler.swift` - backend logic for video frame collection and processing, feature extraction, drowsiness prediction, and alert triggering.
    - `FrameView.swift` - frontend logic on how the live camera recording will look on our UI
    - `Info.plist` - configuration file for app settings
    - `map.gif` - GIF asset for mocking navigation journey on our main UI page
    - `alarm.caf` - audio file asset for auditory alert
    - `AlertView.swift` - frontend logic for displaying the visual drowsiness alert
    - `AVIDDA.entitlements`- configuration file for advance permissions
    - `OpeningView.swift` - frontend logic for presenting instructions on the introductory pages of our UI

Other files/subdirectories that appear in this repository are:
- AVIDDA.xcodeproj - organizational information package for Xcode
- AVIDDATests/ - subdirectory for testing logic
- AVIDDAUITests/ - subdirectory for UI testing logic
- entitlements.entitlements - configuration file for advance permissions



## Setup Instructions
### Needed Infrastructure
Our application requires connecting an iPhone (12 or higher) to your MacOS laptop. Xcode must be installed on the laptop.

### Setup Instructions
1. Install Xcode with Swift onto your MacOS.
2. Clone this project onto your MacOs: `git clone https://github.com/czheng10/multimodal-AVIDDA.git`
3. Connect your iPhone to your MacOS.
4. Agree to "Trust this Computer" after connecting your iPhone to your MacOS.
5. Change directory into your cloned project folder and open up this project on Xcode.
6. Select this project's outermost file (`AVIDDA.xcodeproj`) in the Project Navigator
7. Select AVIDDA under Targets, and then the "Signing & Capabilities" tab
8. Click "+ Capability", search for "Background Modes" and add it
9. Check "Audio, AirPlay, and Picture in Picture" and "Background processing".

You are now ready to build and run AVIDDA.

### Build/Run Instructions
1. Navigate to the "AVIDDA/" directory
2. At the top of the project, switch the build device from "Any iOS Device (arm64)" to your connected iPhone
3. Either click the "start the active scheme" play button on the top left of Xcode, or type `Cmd + R` to build the project. Make sure your iPhone is unlocked. The project will launch automatically.
4. Give permission to AVIDDA to use your camera.

You are now ready to begin recording.

<b> 6.8510: Last updated by Cindy Zheng, Margaret Yu 05/25</b>

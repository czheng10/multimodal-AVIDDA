# AVIDDA: Accessible Video-based Interface for Driver Drowsiness Alerts

## Table of Contents
The majority of our code for our app can be found under the "AVIDDA/" subdirectory or in IPYNB files, so we will go over this in detail:
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
- `68510FinalProject.ipynb` - Google Colab/Jupyter Notebook outlining our processes for model training and testing, threshold determination, and evaluation
- `68510FinalProject_appcode.ipynb` - Google Colab/Jupyter Notebook containing the cleaned version of our detection model, implemented in Python and ready for use. <i>Note: If mediapipe fails to install, simply restart the runtime and try again.</i>

Other files/subdirectories that appear in this repository are:
- AVIDDA.xcodeproj - organizational information package for Xcode
- AVIDDATests/ - subdirectory for testing logic
- AVIDDAUITests/ - subdirectory for UI testing logic
- entitlements.entitlements - configuration file for advance permissions

## What Files Should I Run?
The two major components to run as an end-user testing AVIDDA would be the `AVIDDA/` subdirectory and the `68510FinalProject_appcode.ipynb`. Decide which to run as follows:
- <b>I am interested in AVIDDA's prediction accuracy and speed, and want to see the different model parameters. I can pre-record a 10-second video: </b> You will need to download `68510FinalProject_appcode.ipynb` and upload your 10-second video, then run all cells. No other setup is necessary!
- <b> I am interested in AVIDDA's user interface, and want to experience the entire user path. I am okay with a longer setup process: </b> You will need to build and run the `AVIDDA/` subdirectory to launch the app. Follow the "Application Setup Instructions" portion of this README to do so.

## Application Setup Instructions
### Needed Infrastructure
#### Hardware
Our application requires connecting an iPhone (12 or higher) to your MacOS laptop. 

### Software 
1. Please download Xcode onto your MacOS laptop from the Appstore.
2. Install HomeBrew with `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. Install Ruby with `brew install rbenv`, `rbenv init`, and then `rbenv install 3.4.3`. Note that you may need to change the PATH in `.zshrc` to use Ruby 3.4.3 rather than Apple's built-in version.
4. Install CocoaPods with `gem install cocoapods`
5. Navigate to the directory containing the AVIDDA XPRoj file and run `pod install`

### Setup Instructions
1. Turn on Developer Mode on your iPhone: <b>Settings > Privacy & Security > Developer Mode</b>. This may cause your iPhone to restart.
2. Clone this project onto your MacOs: `git clone https://github.com/czheng10/multimodal-AVIDDA.git`
3. Connect your iPhone to your MacOS.
4. Agree to "Trust this Computer" after connecting your iPhone to your MacOS.
5. Change directory into your cloned project folder and open up this project on Xcode.
6. Select this project's outermost file (`AVIDDA.xcodeproj`) in the Project Navigator
7. Select AVIDDA under Targets, and then the "Signing & Capabilities" tab.
8. Under "Signings", add your Apple account in "Team".
9. Also modify the Bundle Identifier to create one unique to you. We recommend the format `com.<yourname>.AVIDDA`.
10. On your iPhone, navigate to <b>Settings > General > VPN & Device Management</b> and trust your developer app. 

You are now ready to build and run AVIDDA.

### Build/Run Instructions
1. Navigate to the "AVIDDA/" directory
2. At the top of the project, switch the build device from "Any iOS Device (arm64)" to your connected iPhone
3. Either click the "start the active scheme" play button on the top left of Xcode, or type `Cmd + R` to build the project. Make sure your iPhone is unlocked. The project will launch automatically.
4. Give permission to AVIDDA to use your camera.

You are now ready to begin recording.

<b> 6.8510: Last updated by Cindy Zheng, Margaret Yu 05/25</b>

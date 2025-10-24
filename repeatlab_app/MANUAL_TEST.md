# RepeatLab Manual Test Cases

This document contains comprehensive manual test cases for the RepeatLab app using Gherkin syntax. These tests cover all major features and user flows.

## Test Environment Setup

**Prerequisites:**
- Device with iOS or Android
- Audio files in supported formats (MP3, WAV, M4A, OGG, FLAC)
- Internet connection for premium features testing
- Test accounts for premium subscription testing

---

## 🚀 App Launch & Onboarding

### Feature: App First Launch
```gherkin
Scenario: First time user opens the app
  Given the app is installed but never opened
  When I launch the app
  Then I should see the onboarding screen
  And I should see "Welcome to RepeatLab" as the first slide
  And I should see navigation dots at the bottom
  And I should see a "Next" button

Scenario: Navigate through onboarding slides
  Given I am on the onboarding screen
  When I tap "Next" on the first slide
  Then I should see the second slide about "Create Precise Loops"
  When I tap "Next" on the second slide
  Then I should see the third slide about "Privacy First"
  And I should see privacy policy acceptance checkboxes
  And I should see analytics acceptance checkbox

Scenario: Complete onboarding with privacy acceptance
  Given I am on the privacy slide of onboarding
  When I check "I accept the Privacy Policy and Terms of Service"
  And I optionally check "I accept usage analytics"
  And I tap "Get Started"
  Then I should see the premium screen
  When I close the premium screen
  Then I should see the home screen with no songs

Scenario: Skip onboarding without privacy acceptance
  Given I am on the privacy slide of onboarding
  When I try to tap "Get Started" without accepting privacy policy
  Then the button should be disabled
  And I should not be able to proceed
```

### Feature: App Subsequent Launches
```gherkin
Scenario: User opens app after completing onboarding
  Given I have completed onboarding previously
  When I launch the app
  Then I should go directly to the home screen
  And I should not see the onboarding flow
```

---

## 🎵 Audio File Management

### Feature: Adding Audio Files
```gherkin
Scenario: Add first audio file successfully
  Given I am on the home screen with no songs
  When I tap the "+" add song button
  And I select a valid MP3 file from the file picker
  Then I should see a loading indicator
  And the file should be copied to app directory
  And I should see the song appear in the songs list
  And I should see the song title and artist (if available)

Scenario: Add M4A file with automatic conversion
  Given I am on the home screen
  When I tap the "+" add song button
  And I select an M4A file from the file picker
  Then I should see a loading indicator
  And the M4A file should be automatically converted to MP3
  And I should see the converted song appear in the songs list

Scenario: Add multiple different audio formats
  Given I am on the home screen
  When I add files with extensions: MP3, WAV, OGG, FLAC
  Then all files should be successfully imported
  And all songs should appear in the songs list
  And each should display correct metadata

Scenario: Cancel file selection
  Given I am on the home screen
  When I tap the "+" add song button
  And I cancel the file picker dialog
  Then I should return to the home screen
  And no new song should be added

Scenario: Handle unsupported file format
  Given I am on the home screen
  When I try to add an unsupported file format
  Then I should see an error message
  And the file should not be added to the library

Scenario: Handle corrupted audio file
  Given I am on the home screen
  When I try to add a corrupted audio file
  Then I should see an error message about file format
  And the file should not be added to the library
```

### Feature: Song Library Management
```gherkin
Scenario: View songs list
  Given I have multiple songs in my library
  When I am on the home screen
  Then I should see all songs listed
  And each song should show title and artist (if available)
  And each song should show duration

Scenario: Delete single song
  Given I have at least one song in my library
  When I swipe left on a song
  Then I should see a "Delete Song" button
  When I tap "Delete Song"
  Then I should see a confirmation dialog
  When I confirm deletion
  Then the song should be removed from the list
  And all associated loops should be deleted

Scenario: Cancel song deletion
  Given I have swiped left on a song
  When I see the "Delete Song" button
  And I tap elsewhere or swipe back
  Then the delete button should disappear
  And the song should remain in the list

Scenario: Open song for editing
  Given I have at least one song in my library
  When I tap on a song
  Then I should navigate to the song editing screen
  And I should see the waveform display
  And I should see playback controls
```

---

## 🎧 Audio Playback

### Feature: Basic Playback Controls
```gherkin
Scenario: Play song from beginning
  Given I am on the song editing screen
  And the song is not currently playing
  When I tap the play button
  Then the song should start playing from the beginning
  And the play button should change to a pause button
  And I should see the position indicator moving

Scenario: Pause playing song
  Given I am on the song editing screen
  And the song is currently playing
  When I tap the pause button
  Then the song should pause
  And the pause button should change to a play button
  And the position indicator should stop moving

Scenario: Resume paused song
  Given I am on the song editing screen
  And the song is paused at a specific position
  When I tap the play button
  Then the song should resume from the paused position
  And playback should continue normally

Scenario: Skip forward 10 seconds
  Given I am on the song editing screen
  And the song is playing
  When I tap the "forward 10 seconds" button
  Then the playback position should jump forward by 10 seconds
  And playback should continue from the new position

Scenario: Skip backward 10 seconds
  Given I am on the song editing screen
  And the song is playing at least 10 seconds in
  When I tap the "back 10 seconds" button
  Then the playback position should jump backward by 10 seconds
  And playback should continue from the new position

Scenario: Skip backward from beginning
  Given I am on the song editing screen
  And the song is playing within the first 10 seconds
  When I tap the "back 10 seconds" button
  Then the playback position should go to the beginning (0:00)
  And playback should continue from the beginning
```

### Feature: Waveform Navigation
```gherkin
Scenario: Seek by tapping waveform
  Given I am on the song editing screen
  When I tap on a specific point in the waveform
  Then the playback position should jump to that point
  And if the song was playing, it should continue from the new position

Scenario: Drag to scrub through audio
  Given I am on the song editing screen
  When I drag my finger across the waveform
  Then the playback position should follow my finger
  And I should see the position indicator update in real-time
  When I release my finger
  Then playback should continue from the final position
```

### Feature: Background Playback
```gherkin
Scenario: Continue playback when app goes to background
  Given I am on the song editing screen
  And the song is playing
  When I minimize the app or switch to another app
  Then the audio should continue playing in the background
  And I should see media controls in the notification panel

Scenario: Control playback from lock screen
  Given the app is playing audio in the background
  When I lock the device
  Then I should see media controls on the lock screen
  And I should be able to play/pause from the lock screen

Scenario: Control playback from notification panel
  Given the app is playing audio in the background
  When I pull down the notification panel
  Then I should see RepeatLab media controls
  And I should be able to play/pause from the notification
```

---

## 🔄 Loop Management

### Feature: Creating Loops (Free User)
```gherkin
Scenario: Create first loop as free user
  Given I am a free user on the song editing screen
  And the song has no existing loops
  When I position the playhead at a desired start point
  And I tap "Add Loop"
  Then a new loop should be created starting at the current position
  And the loop should be automatically selected and activated
  And I should see the loop displayed on the timeline
  And I should see "Loop 1" in the loop list

Scenario: Try to create second loop as free user
  Given I am a free user on the song editing screen
  And the song already has one loop
  When I tap "Add Loop"
  Then I should see the premium paywall screen
  And no new loop should be created
  When I close the paywall
  Then I should return to the song editing screen
```

### Feature: Creating Loops (Premium User)
```gherkin
Scenario: Create multiple loops as premium user
  Given I am a premium user on the song editing screen
  When I create multiple loops at different positions
  Then all loops should be created successfully
  And each loop should have a unique name (Loop 1, Loop 2, etc.)
  And each loop should have a different color
  And all loops should be visible on the timeline

Scenario: Create loop with automatic end point
  Given I am on the song editing screen
  When I create a loop without setting an end point
  And I play the loop
  Then the loop end should automatically be set to the song's end
  And the loop should play from start point to song end
```

### Feature: Loop Point Setting
```gherkin
Scenario: Set loop start point
  Given I have an active loop selected
  When I position the playhead at a desired start point
  And I tap "Set Loop Start"
  Then the loop's start point should be updated to the current position
  And I should see the loop's visual representation update on the timeline

Scenario: Set loop end point
  Given I have an active loop selected
  When I position the playhead at a desired end point
  And I tap "Set Loop End"
  Then the loop's end point should be updated to the current position
  And I should see the loop's visual representation update on the timeline

Scenario: Validate loop start cannot be after end
  Given I have a loop with an end point set
  When I try to set the start point after the end point
  Then I should see an error message
  And the start point should not be updated

Scenario: Validate loop end cannot be before start
  Given I have a loop with a start point set
  When I try to set the end point before the start point
  Then I should see an error message
  And the end point should not be updated
```

### Feature: Loop Playback
```gherkin
Scenario: Play loop continuously
  Given I have a loop with both start and end points set
  When I select the loop and tap play
  Then the song should play from the loop start
  And when it reaches the loop end, it should jump back to the loop start
  And this should repeat continuously until I stop playback

Scenario: Switch between loop mode and full song mode
  Given I have a loop selected and loop mode is enabled
  When I disable loop mode
  Then the song should play normally from start to finish
  When I re-enable loop mode
  Then the song should return to loop playback behavior

Scenario: Jump to different loop
  Given I have multiple loops created
  When I tap on a different loop in the loop list
  Then playback should jump to that loop's start position
  And that loop should become the active loop
  And loop mode should be enabled for the selected loop
```

### Feature: Loop Editing
```gherkin
Scenario: Edit loop name
  Given I have a loop created
  When I tap the edit button on the loop
  Then I should see the loop editing dialog
  When I change the loop name and save
  Then the loop should display the new name in the loop list

Scenario: Edit loop timing with time inputs
  Given I have a loop created
  When I tap the edit button on the loop
  And I modify the start time in hours:minutes:seconds:milliseconds format
  And I tap save
  Then the loop's start point should be updated to the new time
  And the loop should be validated for correct timing

Scenario: Edit loop timing with invalid format
  Given I am editing a loop's timing
  When I enter an invalid time format (e.g., minutes > 59)
  Then I should see an error message about invalid format
  And the changes should not be saved

Scenario: Delete loop
  Given I have at least one loop created
  When I tap the delete button on a loop
  Then I should see a confirmation dialog
  When I confirm deletion
  Then the loop should be removed from the loop list
  And if it was the active loop, loop mode should be disabled
```

### Feature: Loop Reordering
```gherkin
Scenario: Reorder loops by drag and drop
  Given I have multiple loops created
  When I long press on a loop in the loop list
  And I drag it to a different position
  Then the loop should move to the new position
  And the loop order should be updated
  And all loops should remain functional
```

---

## 🎼 Pitch Control (Free Feature)

### Feature: Pitch Control Access
```gherkin
Scenario: All users can access pitch control
  Given I am on the song editing screen (free or premium user)
  When I navigate to the pitch control section
  Then I should see the pitch adjustment slider
  And I should be able to adjust pitch settings
  And no premium paywall should appear

Scenario: Navigate between tempo and pitch tabs
  Given I am on the song editing screen
  When I see the tempo/pitch control section
  Then I should see tabs for "Tempo" and "Pitch"
  When I tap the "Pitch" tab
  Then I should see the pitch control interface
  When I tap the "Tempo" tab
  Then I should see the tempo control interface
```

### Feature: Pitch Adjustment Functionality
```gherkin
Scenario: Adjust pitch using semitones
  Given I am on the song editing screen with pitch tab selected
  When I adjust the pitch slider to +3 semitones
  Then the song should play 3 semitones higher than original
  And the pitch indicator should show "+3"
  And the audio should maintain its original speed

Scenario: Test pitch range limits
  Given I am on the pitch control tab
  When I set the pitch to minimum (-12 semitones)
  Then the song should play one octave lower
  And the pitch indicator should show "-12"
  When I set the pitch to maximum (+12 semitones)
  Then the song should play one octave higher
  And the pitch indicator should show "+12"

Scenario: Reset pitch to original
  Given I have adjusted the pitch to any non-zero value
  When I tap the reset button or set pitch to 0
  Then the song should return to original pitch
  And the pitch indicator should show "0"
  And the audio should sound exactly like the original

Scenario: Real-time pitch adjustment during playback
  Given the song is currently playing
  When I adjust the pitch slider
  Then the pitch change should be applied immediately
  And playback should continue without interruption
  And the new pitch should be audible instantly

Scenario: Pitch adjustment with paused audio
  Given the song is paused
  When I adjust the pitch slider
  Then the pitch setting should be saved
  When I resume playback
  Then the song should play with the adjusted pitch
```

### Feature: Pitch and Speed Independence
```gherkin
Scenario: Pitch change independent of speed (Free user)
  Given I am a free user with pitch control access
  When I adjust the pitch to +5 semitones
  Then the pitch should change without affecting speed
  And the song should play at original tempo but higher pitch

Scenario: Pitch change independent of speed (Premium user)
  Given I am a premium user
  When I set speed to 0.8x and pitch to +2 semitones
  Then the song should play slower than original (0.8x speed)
  And the song should play 2 semitones higher than original
  And both adjustments should work independently

Scenario: Reset one control without affecting the other
  Given I have both speed and pitch adjusted
  When I reset the pitch to 0
  Then only the pitch should return to original
  And the speed adjustment should remain unchanged
  When I reset the speed to 1.0x
  Then only the speed should return to original
  And the pitch adjustment should remain unchanged
```

### Feature: Pitch Control UI/UX
```gherkin
Scenario: Compact pitch control interface
  Given I am on the song editing screen
  When I view the tempo/pitch control section
  Then it should use minimal screen space
  And the interface should be intuitive
  And both tempo and pitch tabs should be easily accessible

Scenario: Visual pitch feedback
  Given I am adjusting the pitch
  When I move the pitch slider
  Then I should see the current semitone value displayed
  And the display should update in real-time
  And positive values should be clearly distinguished from negative

Scenario: Pitch slider precision
  Given I am using the pitch slider
  When I make small adjustments
  Then I should be able to set precise semitone values
  And the slider should respond to fine movements
  And the value should snap to whole semitones

Scenario: Pitch control accessibility
  Given I am using the pitch control
  When I interact with the slider
  Then it should be accessible via touch gestures
  And the current value should be clearly visible
  And the control should work on different screen sizes
```

### Feature: Musical Transposition Use Cases
```gherkin
Scenario: Transpose song to match vocal range
  Given I have a song that's too high for my vocal range
  When I adjust the pitch to -4 semitones
  Then the song should play in a lower key
  And I should be able to sing along comfortably
  And the chord progressions should remain musically correct

Scenario: Transpose song to match instrument tuning
  Given I have a guitar tuned down a half step
  When I adjust the song pitch to -1 semitone
  Then the song should match my guitar tuning
  And I should be able to play along accurately

Scenario: Practice transposition skills
  Given I want to practice a song in different keys
  When I adjust the pitch to various semitone values
  Then each adjustment should create a musically valid transposition
  And I should be able to practice the same song in multiple keys

Scenario: Combine pitch with looping for practice
  Given I have created a loop for a difficult section
  When I adjust the pitch to a comfortable key
  And I play the loop repeatedly
  Then the loop should maintain the pitch adjustment
  And I should be able to practice the section in the new key
```

### Feature: Pitch Control Error Handling
```gherkin
Scenario: Handle extreme pitch adjustments gracefully
  Given I adjust the pitch to extreme values (-12 or +12)
  When the audio plays
  Then the sound quality should remain acceptable
  And the app should not crash or produce audio artifacts
  And the pitch should be accurately applied

Scenario: Pitch control with different audio formats
  Given I have songs in different formats (MP3, WAV, OGG, FLAC)
  When I apply pitch adjustments to each format
  Then pitch control should work consistently across all formats
  And audio quality should be maintained for all file types

Scenario: Memory usage with pitch processing
  Given I have pitch adjustment applied
  When I play long audio files or multiple songs
  Then memory usage should remain reasonable
  And the app should not slow down or crash
  And pitch processing should remain smooth
```

---

## ⚡ Speed Control (Premium Feature)

### Feature: Speed Control Access
```gherkin
Scenario: Free user tries to adjust speed
  Given I am a free user on the song editing screen
  When I try to adjust the speed slider
  Then the slider should not respond
  When I release the slider
  Then I should see the premium paywall screen

Scenario: Premium user accesses speed control
  Given I am a premium user on the song editing screen
  When I interact with the speed control section
  Then I should be able to adjust all speed settings
  And changes should be applied immediately
```

### Feature: Multiplier Mode Speed Control
```gherkin
Scenario: Adjust speed using multiplier mode
  Given I am a premium user with multiplier mode selected
  When I adjust the speed slider to 0.75x
  Then the song should play at 75% of original speed
  And the speed indicator should show "0.8×"
  And the audio pitch should remain unchanged

Scenario: Test speed range limits
  Given I am a premium user with multiplier mode selected
  When I set the speed to minimum (0.5x)
  Then the song should play at half speed
  When I set the speed to maximum (2.0x)
  Then the song should play at double speed
  And audio quality should remain acceptable

Scenario: Reset speed to normal
  Given I am a premium user with modified playback speed
  When I set the speed back to 1.0x
  Then the song should play at normal speed
  And all timing should return to original values
```

### Feature: BPM Mode Speed Control
```gherkin
Scenario: Set original BPM manually
  Given I am a premium user with BPM mode selected
  When I tap "Set BPM" and enter "120" as original BPM
  Then the original BPM should be set to 120
  And the current BPM should also be set to 120
  And the BPM range should be calculated (60-240)

Scenario: Adjust current BPM
  Given I have set an original BPM of 120
  When I adjust the current BPM slider to 90
  Then the song should play at 75% speed (90/120)
  And the BPM indicator should show "90 BPM"

Scenario: Use tap BPM detection
  Given I am in BPM mode
  When I tap "Tap BPM"
  And I tap the TAP button in rhythm with the music (at least 4 taps)
  Then the app should calculate and display the detected BPM
  When I tap "Use BPM"
  Then the detected BPM should be set as the original BPM

Scenario: Validate BPM range limits
  Given I have set an original BPM
  When I try to set current BPM below the minimum
  Then it should be limited to the calculated minimum
  When I try to set current BPM above the maximum
  Then it should be limited to the calculated maximum
```

---

## 📊 Waveform Visualization (Premium Feature)

### Feature: Waveform Zoom Access
```gherkin
Scenario: Free user tries to zoom waveform
  Given I am a free user on the song editing screen
  When I tap the zoom in button
  Then I should see the premium paywall screen
  And the waveform zoom should not change

Scenario: Premium user accesses zoom controls
  Given I am a premium user on the song editing screen
  When I tap the zoom in button
  Then the waveform should zoom in
  And I should see more detail in the waveform
  And zoom controls should appear temporarily
```

### Feature: Waveform Zoom Functionality
```gherkin
Scenario: Zoom in on waveform
  Given I am a premium user on the song editing screen
  When I tap the zoom in button multiple times
  Then the waveform should progressively zoom in
  And I should see more detailed waveform data
  And the zoom level should be limited to maximum (5.0x)

Scenario: Zoom out on waveform
  Given I am a premium user with zoomed-in waveform
  When I tap the zoom out button
  Then the waveform should zoom out
  And I should see more of the song timeline
  And the zoom level should be limited to minimum (0.25x)

Scenario: Use zoom slider
  Given I am a premium user on the song editing screen
  When I tap a zoom button to show the zoom slider
  And I drag the zoom slider to different positions
  Then the waveform zoom should update in real-time
  And the zoom slider should disappear after 2 seconds of inactivity

Scenario: Maintain position during zoom
  Given I am viewing a specific part of the waveform
  When I zoom in or out
  Then the center position should remain approximately the same
  And I should not lose my place in the song
```

---

## 🌍 Internationalization

### Feature: Language Support
```gherkin
Scenario: App displays in device language
  Given my device is set to German language
  When I open the app
  Then all UI text should be displayed in German
  And all error messages should be in German
  And all dialog text should be in German

Scenario: Unsupported language fallback
  Given my device is set to an unsupported language
  When I open the app
  Then all UI text should be displayed in English (fallback)
  And the app should function normally

Scenario: Test all supported languages
  Given the app supports 16 languages
  When I test each supported language
  Then all UI elements should be properly translated
  And text should fit properly in UI elements
  And no text should be cut off or overlapping
```

---

## 💎 Premium Features & Subscription

### Feature: Premium Status Detection
```gherkin
Scenario: Check premium status on app launch
  Given I have a valid premium subscription
  When I launch the app
  Then premium features should be unlocked
  And I should not see premium upgrade prompts

Scenario: Check free user status
  Given I do not have a premium subscription
  When I launch the app
  Then premium features should be locked
  And I should see premium upgrade prompts when accessing premium features
```

### Feature: Premium Purchase Flow
```gherkin
Scenario: View premium features screen
  Given I am a free user
  When I tap on premium upgrade prompts
  Then I should see the premium features screen
  And I should see a list of premium features
  And I should see pricing information
  And I should see purchase buttons

Scenario: Purchase yearly subscription
  Given I am on the premium features screen
  When I tap the yearly subscription button
  Then I should see the system purchase dialog
  When I complete the purchase
  Then I should see a success message
  And premium features should be unlocked immediately

Scenario: Purchase lifetime option
  Given I am on the premium features screen
  When I tap the lifetime purchase button
  Then I should see the system purchase dialog
  When I complete the purchase
  Then I should see a success message
  And premium features should be unlocked permanently

Scenario: Restore previous purchases
  Given I previously purchased premium on another device
  When I tap "Restore Purchases"
  Then the app should check with the app store
  And my premium status should be restored
  And premium features should be unlocked
```

### Feature: Premium Feature Restrictions
```gherkin
Scenario: Free user feature limitations
  Given I am a free user
  Then I should be limited to one loop per song
  And speed control should show premium paywall
  And waveform zoom should show premium paywall
  And I should have access to unlimited songs
  And I should have access to basic playback controls

Scenario: Premium user feature access
  Given I am a premium user
  Then I should have unlimited loops per song
  And speed control should be fully functional
  And waveform zoom should be fully functional
  And all basic features should remain available
```

---

## 🔧 Settings & Preferences

### Feature: User Settings
```gherkin
Scenario: Access settings from drawer
  Given I am on the home screen
  When I open the navigation drawer
  And I tap on "Settings"
  Then I should see the settings screen
  And I should see analytics toggle
  And I should see data management options

Scenario: Toggle analytics consent
  Given I am on the settings screen
  When I toggle the analytics setting
  Then my preference should be saved
  And analytics collection should be enabled/disabled accordingly

Scenario: Delete all local data
  Given I am on the settings screen
  When I tap "Delete All Local Data"
  Then I should see a confirmation dialog
  When I confirm the action
  Then all songs and loops should be deleted
  And I should return to an empty home screen
```

### Feature: Legal & Privacy
```gherkin
Scenario: View privacy policy
  Given I am in the app
  When I navigate to privacy policy
  Then I should see the complete privacy policy
  And it should be displayed in my device language
  And all links should be functional

Scenario: View terms of service
  Given I am in the app
  When I navigate to terms of service
  Then I should see the complete terms of service
  And it should be displayed in my device language

Scenario: View legal notices
  Given I am in the app
  When I navigate to legal notices
  Then I should see developer information
  And contact information should be displayed
```

---

## 🎯 Tutorial & Help

### Feature: Interactive Tutorial
```gherkin
Scenario: Start tutorial from song screen
  Given I am on a song editing screen
  When I tap the help or tutorial button
  Then I should see the interactive tutorial overlay
  And I should see the first tutorial step highlighted
  And I should see tutorial explanation text

Scenario: Navigate through tutorial steps
  Given I am in the interactive tutorial
  When I tap "Next" on each tutorial step
  Then I should progress through all tutorial steps
  And each step should highlight the relevant UI element
  And I should see contextual help text for each step

Scenario: Skip tutorial
  Given I am in the interactive tutorial
  When I tap "Skip"
  Then I should see a confirmation
  When I confirm skipping
  Then the tutorial should close
  And I should return to normal app usage

Scenario: Complete tutorial
  Given I am in the interactive tutorial
  When I complete all tutorial steps
  Then the tutorial should close automatically
  And my tutorial completion status should be saved
  And I should not see the tutorial again automatically
```

---

## 🐛 Error Handling & Edge Cases

### Feature: Network Connectivity
```gherkin
Scenario: Premium features without internet
  Given I have no internet connection
  When I try to access premium purchase screen
  Then I should see an appropriate error message
  And the app should handle the offline state gracefully

Scenario: Restore purchases without internet
  Given I have no internet connection
  When I try to restore purchases
  Then I should see a network error message
  And the app should not crash
```

### Feature: Audio File Errors
```gherkin
Scenario: Handle corrupted audio file
  Given I try to import a corrupted audio file
  When the import process fails
  Then I should see a clear error message
  And the app should not crash
  And I should be able to try importing another file

Scenario: Handle very large audio file
  Given I try to import a very large audio file (>100MB)
  When the import process starts
  Then I should see a progress indicator
  And the import should either complete successfully or show appropriate error
  And the app should remain responsive

Scenario: Handle very short audio file
  Given I import an audio file shorter than 5 seconds
  When I try to create loops
  Then the app should handle the short duration appropriately
  And loop creation should work within the available time range
```

### Feature: Memory & Performance
```gherkin
Scenario: Handle multiple large songs
  Given I have imported multiple large audio files
  When I switch between different songs
  Then the app should manage memory efficiently
  And performance should remain acceptable
  And the app should not crash due to memory issues

Scenario: Background app termination
  Given the app is playing audio in the background
  When the system terminates the app due to memory pressure
  Then audio playback should stop gracefully
  And when I reopen the app, it should restore to a consistent state
```

### Feature: Data Persistence
```gherkin
Scenario: App crash recovery
  Given I have songs and loops created
  When the app crashes unexpectedly
  And I restart the app
  Then all my songs should still be available
  And all loops should be preserved
  And the app should start normally

Scenario: Device storage full
  Given the device storage is nearly full
  When I try to import a new audio file
  Then I should see an appropriate error message about storage
  And the app should not crash
  And existing songs should remain accessible
```

---

## 📱 Platform-Specific Tests

### Feature: iOS Specific
```gherkin
Scenario: iOS file picker integration
  Given I am on iOS
  When I tap add song
  Then I should see the iOS file picker
  And I should be able to browse iCloud files
  And I should be able to select from Music library (if permitted)

Scenario: iOS background audio permissions
  Given I am on iOS
  When audio plays in background
  Then I should see proper iOS media controls
  And Control Center should show RepeatLab controls
  And Lock screen should show media controls
```

### Feature: Android Specific
```gherkin
Scenario: Android file picker integration
  Given I am on Android
  When I tap add song
  Then I should see the Android file picker
  And I should be able to browse device storage
  And I should be able to select from various file locations

Scenario: Android background audio permissions
  Given I am on Android
  When audio plays in background
  Then I should see notification with media controls
  And notification should persist during playback
  And I should be able to control playback from notification
```

---

## 🔄 Regression Tests

### Feature: Core Functionality Regression
```gherkin
Scenario: Basic workflow still works after updates
  Given the app has been updated
  When I import a song
  And I create a loop
  And I play the loop
  Then all basic functionality should work as expected
  And no previously working features should be broken

Scenario: Premium features still work after updates
  Given I am a premium user and the app has been updated
  When I test all premium features
  Then speed control should work correctly
  And waveform zoom should work correctly
  And unlimited loops should work correctly
  And no premium features should be broken
```

---

## 📊 Performance Tests

### Feature: Performance Benchmarks
```gherkin
Scenario: App launch time
  Given the app is not running
  When I launch the app
  Then the app should launch within 3 seconds
  And the home screen should be responsive immediately

Scenario: Audio file import time
  Given I have a typical audio file (3-5 minutes, MP3)
  When I import the file
  Then the import should complete within 10 seconds
  And the waveform should be generated within 5 seconds

Scenario: Waveform rendering performance
  Given I have a song loaded
  When I zoom in and out on the waveform
  Then zoom operations should be smooth (>30 FPS)
  And there should be no noticeable lag

Scenario: Loop playback performance
  Given I have a loop with very short duration (1-2 seconds)
  When I play the loop continuously
  Then loop transitions should be seamless
  And there should be no audio gaps or clicks
```

---

## Test Execution Notes

### Test Data Requirements
- Audio files of different formats and sizes
- Test accounts with and without premium subscriptions
- Various device configurations (iOS/Android, different screen sizes)

### Test Environment Setup
- Clean app installation for onboarding tests
- Existing user data for feature tests
- Network connectivity variations for premium tests

### Expected Results Documentation
- All scenarios should pass for release candidate
- Performance benchmarks should meet specified criteria
- Error handling should be graceful and user-friendly

---

*This manual test suite should be executed before each release to ensure all features work correctly across different user scenarios and device configurations.*

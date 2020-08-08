# Selenium

TODO:

• ~Fix persistence through resprings (as well as the "SNOOZED" indicator).~ ✅

• ~Finish the custom stepper cell UI (and add a smaller subtitle that says until HH:mm, like android's Do Not Disturb UI on Marshmallow), then make it actually work.~ ✅

• ~Replace all 'For X amount of time' methods with the custom stepper cell.~ ✅

• ~Figure out how to grab notification cells + requests more reliably.~ ✅ I think this is fixed? not sure what caused problems in the first place.

• ~Create pref pane with options to choose UIDatePicker intervals, choosing wether "Tap To Change" should appear when tapping on snooze or just straight open the UIAlertController, choose UIStepper intervals, and what snooze options should be available (currently there are supposed to be only 2, but should be more useful when more options like DND and location are added).~ ✅ Prefs created, some of these options will be added soon.

• Not compatible with Axon, but compatible with Grupi. Need to figure out how to make it compatible with Axon.

• \[Maybe for a future update\]Make an option for the Snooze button in the notification cell actions snooze automatically using the last setting used, and only open the UIAlertController when using the 'Tap To Change' option after that (and also not in the form of a UIAlertController, should expand on a tap to a view that looks more like a floating AirPods / App Clip menu in the middle of the screen).

• \[Optional\] In addition to the previous one, also add a subtitle to the Snooze action in the notification cell that says what was the last used option.

• \[Future update\] DND options - started to work on this, but stopped because of all of the important fixes need to be done, listed above. Features should be as simple as snoozing all incoming notifications when DND is on && Snooze CCUI toggle is on - although should be accounted for a situation where the user turns DND off manualey, and be persistent through resprings as well; those are the difficulties. Could be especially useful when combined with 'DND While Driving' as well. (Found in code by the looking for {DND start} without curly braces)

• \[Future release\] Location options - same as the previous one, just with 'Until I leave this location' (similar to Shortcuts Automations) and 'Until I arrive to location X', with location list being configurable from the pref pane the same way Shortcut Automation does (so the user will get options like 'Until I arrive Home' and 'Until I arrive Work' that would work with and benefit from iOS built-in significant locations and location recognition by WiFi just like Shortcut Automations).

• \[Important!\] Clean-up. There's a lot more of that to do...
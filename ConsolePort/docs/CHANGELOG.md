# Changelog

## 1.0.3 — 2026-10-11

- Fix modifier satellites retaining humanoid abilities after a druid form change or login in animal form. Hover icons, tooltips, and cooldowns now resolve from the shared action-bar page used by the main bar.
- Remove outgoing-spell cooldown fallback so a humanoid cooldown does not keep a satellite visible when its current slot contains a different ability or is empty.
- Prevent protected satellite layering changes during combat; reconcile layering after combat while preserving cooldown text and swipes.
- Keep existing saved settings, bindings, and layout geometry. The maintainer confirmed the form-satellite and combat fixes in game.

## 1.0.2 — 2026-10-06

- Correct callback order insertion and resolve owners registered after the first hook.
- Restore cursor tracking when a forbidden frame becomes allowed again.
- Safely reject invalid frame-tracker inputs and skip unavailable frame coordinates.
- Keep talent-specialization temporaries out of the global namespace.
- Correct the main TOC reference to Core/CVar.lua to match filename case.
- Retain the tested 1.0.1 iterative scanner fixes and saved-settings compatibility.


## 1.0.1 — Interface-options crash fix

- Fixed stack/memory exhaustion while scanning large addon UI trees when opening Blizzard Interface options through `/tomtom`, the controller menu, or other entry points.
- Replaced recursive action-button and controller-navigation traversal with iterative scans and duplicate/cycle guards. Parent/container and scroll-parent lookups are iterative as well.
- Preserved existing traversal order, action-bar filtering, visibility rules, and scroll ancestry. No arbitrary frame-count limit was added.
- Updated version metadata for all eight bundled modules. Existing Enhanced users can retain their saved settings.
- Automated regression/stress checks passed; the affected user confirmed the reported crash no longer occurred in game.

## Retained changes from ConsolePortLK 1.5.0-rc2

## Cooldowns and bars

- Cooldown text resolves frame/owner references consistently, updates through its own throttled driver, measures against the owning button, and uses whole-second/minute formatting and urgency colors.
- Shared rendering separates main and satellite roles, maintains one text owner per layout, and coordinates with OmniCC ownership. Blizzard swipes remain available.
- Cooldown/page events refresh cached action identities and visible state, including delayed refreshes where the client changes page information after the triggering event.
- Spell cooldown fallback handles cases where an action-slot cooldown is temporarily empty after form/page transitions.
- Minimal satellites ignore short global cooldowns, support visibility thresholds, suppress the currently held modifier layer, and retire expired cooldowns without requiring another button press or hover.
- Satellite hotkey labels restore after expiry; combined-modifier elements stack above the single-modifier elements.
- Minimal geometry, icons, art, highlights, and shadows follow button size proportionally. Approved bumper placement is retained.
- Triple wings retain static layer identity, action/cooldown lookup, persistent visibility, and saved geometry.
- Layout presentation profiles retain separate size/scale/art/geometry preferences while sharing the appropriate cooldown preferences.
- Original optional indicator presence/absence semantics are restored. Optional upper indicators start unchecked on a fresh profile. Existing explicit saved choices are preserved.
- Orthodox optional buttons receive official first-enable geometry in v161; runtime confirmation of that final adjustment is pending.
- Slice-mask update timing is corrected and redundant cooldown updates are removed.

## Settings and navigation

- Ordinary first settings launch selects General and its heading. Session-local navigation remembers the selected subsection across shoulder-tab changes and close/reopen.
- Forced calibration/bindings setup does not consume the ordinary first-settings navigation state.
- Bindings capture focuses only while the bindings view is active; settings shoulder navigation uses secure proxies.
- Integrated Action Bars settings remain populated. The legacy pop-out editor is hidden from that path.
- Save/reload decisions compare final values with the loaded baseline, rather than treating any past click as a pending change. Presentation repairs avoid destructive duplicate rendering.
- Exiting Advanced reapplies benign bar presentation. The game menu’s ConsolePort entry follows the settings category path.

## Bindings, defaults, and compatibility

- Binding override updates avoid redundant writes and callbacks, incorporating the documented dan-schales upstream contribution. Calibration updates only changed bindings, and world-entry invalidation queues appropriately during combat.
- Calibrated stick-click fallback and cursor click handling account for physical mappings and valid button types.
- Seven non-Wii presets share one changed fresh default: CP_R_DOWN under CTRL is MULTIACTIONBAR4BUTTON5 instead of EXTRAACTIONBUTTON1. This is RT+A in the tested Xbox trigger profile. Existing saved bindings take precedence. Other preset binding defaults and the Wii template remain unchanged.
- Fresh defaults enable the pixel bridge and controller nameplates, disable the optional keyboard and double-modifier-tap behavior. Existing user preferences remain authoritative.
- Callback backlog handling and nameplate polling reduce redundant work; this is a source-level optimization, not a measured performance claim.
- Removed action/button debug chat noise; corrected the optional GetSpecialization API spelling and raid-marker editor display.
- Existing local cooldown diagnostic state is retained. It does not automatically transmit reports.
- Optional FormFreedom menu helpers integrate with controller selection and reconcile bar state afterward. Automatic druid cancellation remains in the standalone FormFreedom addon.
- Help text reflects the revised fresh defaults. A locale-only interaction note is present but is not claimed as a visible UI feature.

## Scope and evidence

These are retained final-source changes, not every historical experiment. The official controller artwork and native layout behavior remain the reference baseline. See TESTING.md for runtime confirmations and limits; UPSTREAM-CHANGES.md lists every changed source file.

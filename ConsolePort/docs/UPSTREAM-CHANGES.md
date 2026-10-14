# Upstream review inventory

Baseline: official ConsolePortLK 1.5.0-rc2 release package; upstream tag/commit `994793729ca4a5b97e87df7ce6b986ec2a370d55`. Current release: Enhanced 1.0.2, retaining development v161 and the tested 1.0.1 Interface-options scanner fix.

Release 1.0.1 additionally changes `ConsolePort/Drivers/UITracker.lua` and `ConsolePort/Drivers/UINode.lua` and updates version metadata in all eight module TOCs. The inventory below records the original v161 publication baseline.

See CHANGELOG.md for behavior grouped by subsystem and TESTING.md for evidence. The table is exhaustive for differing files inside the eight addon roots before publication documentation is added. Development-only reports are relocated out of the addon roots.

| File | Difference |
| --- | --- |
| `ConsolePort/Config/Binds.lua` | Changed |
| `ConsolePort/Config/Lookup.lua` | Changed |
| `ConsolePort/Config/Splash.lua` | Changed |
| `ConsolePort/ConsolePort.toc` | Changed |
| `ConsolePort/Controllers/PS4/PS4.lua` | Changed |
| `ConsolePort/Controllers/PS5/PS5.lua` | Changed |
| `ConsolePort/Controllers/STEAM/Steam.lua` | Changed |
| `ConsolePort/Controllers/STEAMDECK/SteamDeck.lua` | Changed |
| `ConsolePort/Controllers/SWITCH/Switch.lua` | Changed |
| `ConsolePort/Controllers/WMExt.lua` | Changed |
| `ConsolePort/Controllers/XBOX/Xbox.lua` | Changed |
| `ConsolePort/Controllers/XBOXELITE/XboxElite.lua` | Changed |
| `ConsolePort/Core/Callback.lua` | Changed |
| `ConsolePort/Cursors/Interface.lua` | Changed |
| `ConsolePort/Frames/Config.lua` | Changed |
| `ConsolePort/Frames/Nameplate.lua` | Changed |
| `ConsolePort/Init/Init.lua` | Changed |
| `ConsolePort/Init/Slash.lua` | Changed |
| `ConsolePort/Init/Wrapper.lua` | Changed |
| `ConsolePort/Locale/enUS.lua` | Changed |
| `ConsolePortAdvanced/Browser.lua` | Changed |
| `ConsolePortBar/BUILD-v161.txt` | Added development report |
| `ConsolePortBar/CONTROLLER-AUDIT-v161.md` | Added development report |
| `ConsolePortBar/ConsolePortBar.toc` | Changed |
| `ConsolePortBar/Core/Bar.lua` | Changed |
| `ConsolePortBar/Core/Config.lua` | Changed |
| `ConsolePortBar/Core/Lookup.lua` | Changed |
| `ConsolePortBar/Core/SliceMask.lua` | Changed |
| `ConsolePortBar/Core/Wrapper.lua` | Changed |
| `ConsolePortBar/Libs/ActionButton.lua` | Changed |
| `ConsolePortHelp/Pages/Features.lua` | Changed |
| `ConsolePortHelp/Pages/Gameplay.lua` | Changed |
| `ConsolePortKeyboard/ConsolePortKeyboard.toc` | Changed |
| `ConsolePortKeyboard/Core/Config.lua` | Changed |
| `ConsolePortUI_Menu/Menu_Frame.lua` | Changed |

## Release package versus Git checkout

All controller artwork in this candidate is retained byte-for-byte from the official release package. Twelve Steam Deck icon files in that release package differ from the upstream Git tag checkout. These inherited packaging differences are not new artwork created by Enhanced. Text line endings also differ between archive and checkout; compare normalized text when reviewing behavior.

## Contribution path

Fork leoaviana/ConsolePortLK into SuttonX/ConsolePortLK-Enhanced to preserve ancestry. Upload these sources to the fork, then open a pull request targeting the original repository’s master branch if you want to offer the changes upstream. The original maintainer decides whether to incorporate them.

Release 1.0.2 additionally changes Core/Callback.lua, Drivers/UIStack.lua, Drivers/UITracker.lua, Drivers/UINode.lua and Init/Wrapper.lua for callback, frame-tracking, geometry availability and temporary-variable handling.

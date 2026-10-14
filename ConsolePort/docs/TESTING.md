# Testing status

## 1.0.2 reliability fixes

Mock checks pass for callback order/owners/unregister, invalid and delayed frame discovery, forbid/unforbid, missing frame coordinates, and specialization global isolation. Scanner regression tests cover 8,000 action widgets and 20,000 cursor widgets with deep hierarchies and cycle guards. Runtime Lua is parsed as Lua 5.1; XML script bodies and file references are checked separately.

In game: retain SavedVariables; open Interface through the controller menu and /tomtom with the full addon set. Navigate tabs, scrolling options, closing/reopening windows, and frames created late. Confirm controller action bars, cooldowns and druid form paging still work. Test enabling/disabling addon sets and profile switching. Report errors and exact reproduction steps. On 2026-10-06 the maintainer reported no ConsolePortLK Enhanced issues after installing the audit build alongside the other updated addons and testing profile switching. This overall pass does not prove every failure case was separately exercised.


## 1.0.1 Interface-options fix

The affected user confirmed no crash after installing the two-file fix and retesting in game with their addon setup. Automated tests compared old/new traversal order and filtering; action scanning passed 8,000-sibling and 8,000-descendant trees, and cursor scanning passed 20,000-sibling and 20,000-descendant trees. Both modified Lua files passed syntax checks. These tests address the reported recursive scanner failure; they do not establish compatibility with every addon combination or remove the client’s overall memory limits.

## Existing gameplay testing

The development and runtime tests used an Xbox controller with LT/RT rear-trigger modifiers, on a WotLK 3.3.5a client. Minimal and Triple layouts, cooldown text/swipes, settings navigation, checkbox behavior, layout preference retention including logout/login, and FormFreedom coexistence were confirmed in game during development.

v153 is the locked restore point preceding the druid cancellation experiments. v160 restored that lineage with only the optional FormFreedom cursor/menu-state bridge; the user confirmed the shared setup worked. v161 adds the official Orthodox optional-button first-enable geometry (size 64, offsets 440/9). That last adjustment has source/audit validation but is not yet user-tested in game.

Other controller presets and all WoWPadX modifier choices have been compared against official source and share the changed implementation. This is not a hardware test of every controller or every modifier combination. Steam Input and GameNative configurations have not been independently tested.

A previously observed Prowl/stealth-break cooldown issue could no longer be reproduced. Barkskin cooldown text and swipe were confirmed after breaking stealth from both the base and modifier bar. This does not establish every possible enemy-caused stealth-break scenario.

The final Orthodox optional-button placement remains a source-validated change requiring a specific first-enable in-game check. Report other-controller issues with controller preset, physical modifier assignments, mapper, bar layout, reproduction steps, and any Lua error.

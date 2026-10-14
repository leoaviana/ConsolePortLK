local _, Help = ...

-- MAIN DIRECTORY PAGE
Help:AddPage('Features', "welcome-page", [[<HTML><BODY>
<H1 align="center">ConsolePortLK Features</H1><br/>
<H2 align="left">Discover the features built for the 3.3.5a client.</H2>
<br/>
<p align="left">
    ConsolePortLK is more than just a direct backport of the original ConsolePort version 1.9.17. It has been heavily modified and expanded with brand new systems and UI overhauls designed specifically to bring a modern controller experience to WotLK.
</p><br/>

<H1 align="center">Explore the New Features</H1><br/>
<p align="left">
    <a href="page:Pixel Bridge">|cff69ccf0• Pixel Bridge (Experimental)|r</a><br/><br/>
    <a href="page:Utility Ring">|cff69ccf0• Revamped Utility Ring|r</a><br/><br/>
    <a href="page:Unit Popup">|cff69ccf0• Immersive Unit Popup|r</a><br/><br/>
    <a href="page:Action Bar">|cff69ccf0• Modernized Action Bars|r</a><br/><br/>
    <a href="page:Settings Panel">|cff69ccf0• Revamped Settings Panel|r</a><br/><br/>
    <a href="page:Controller Presets">|cff69ccf0• Modern Controller Presets|r</a><br/><br/>
    <a href="page:More to Come">|cff69ccf0• More to Come / Suggestions|r</a>
</p><br/>
</BODY></HTML>]])


-- SUBPAGES
Help:AddPage('Pixel Bridge', 'Features', [[<HTML><BODY>
    <H1 align="center">
        Pixel Bridge
    </H1><br/>
    <p align="left">
        The |cFFFF6600Pixel Bridge|r is an experimental synchronization system designed to close the gap between the game client and WoWpadX.
        <br/><br/>
        By encoding your character's real-time state into tiny, unnoticeable pixels in the corner of your screen, ConsolePort can communicate useful information to WoWpadX without the need for intrusive memory reading.
    </p><br/>
    <H2 align="left">
        What does it enable?
    </H2>
    <p align="left">
        While ConsolePort handles the interface, the Pixel Bridge provides the external mapper with "eyes" inside the game world. This enables some QoL features in WoWpadX such as:
        <br/><br/>
        |cff69ccf0• Precise Haptic Feedback:|r Your controller can vibrate or change LED colors based on your actual health percentage.<br/>
        |cff69ccf0• Adaptive Movement:|r The system can automatically detect if your character is walking or running, adjusting stick sensitivity on the fly for smoother navigation.<br/>
        |cff69ccf0• Combat Awareness:|r External overlays or rumble effects can trigger the moment you enter combat or start targeting a spell reticle.<br/>
        |cff69ccf0• Intelligent Mouselook:|r Prevents "ghost" cursor movements by instantly syncing the camera toggle state between the game and your sticks.
    </p><br/>
    <H2 align="left">
        How to use it
    </H2>
    <p align="left">
        Pixel Bridge is enabled by default in this community build. You can turn it off or back on from the <a href="run:ConsolePortOldConfig:OpenCategory('Config')">|cff69ccf0Settings|r</a> menu using |cFFFF6600Enable Pixel Bridge|r.
        <br/><br/>
        Once enabled, you will notice a tiny (8x1 pixel) flickering magenta block in the top-left corner of your screen. This is the "Beacon" that your controller software uses to lock onto the game window. 
        <br/><br/>
        |cffff269bNote:|r For the bridge to work, the top-left corner of your game window must be visible and not obscured by other applications (like Discord overlays or web browsers).
    </p><br/>
    <H2 align="left">
        Performance and Safety
    </H2>
    <p align="left">
        The Pixel Bridge is entirely passive. It does not modify game files, read protected memory, or interact with the server in any way. It simply displays a few colored pixels, making it the safest way to achieve advanced haptic integration.
        <br/><br/>
        In terms of performance, the impact is effectively zero. It takes less processing power than showing a single icon on your action bar.
    </p>
</BODY></HTML>]])

Help:AddPage('Utility Ring', 'Features', [[<HTML><BODY>
<H1 align="center">Utility Ring</H1>
<br/>
<p align="left">
    The Utility Ring has been completely rebuilt to offer a dynamic, 8-slot OR 16-slot rotational quick-menu for on-the-fly actions.
</p><br/>
<p align="left">
    <b>What's New:</b><br/>
    • <b>Preset System:</b> Save and create different ring configurations.<br/>
    • <b>New Settings Page:</b> A dedicated UI setting tab makes configuring your ring easier than ever. Just select items, macros, or spells directly from there.<br/>
    • <b>Quest Auto-Assign:</b> The ring can automatically detect active quest items from your tracker and slot them in for quick access.
</p>
</BODY></HTML>]])

Help:AddPage('Unit Popup', 'Features', [[<HTML><BODY>
<H1 align="center">Unit Popup</H1>
<br/>
<p align="left">
    The standard, clunky right-click dropdown menu has been replaced with a completely custom Unit Popup designed specifically for controllers.
</p><br/>
<p align="left">
    This new menu cleanly categorizes all targeting, interacting, and loot options into an immersive, controller-friendly interface. It completely modernizes how you interact with players and NPCs.
</p>
</BODY></HTML>]])

Help:AddPage('Action Bar', 'Features', [[<HTML><BODY>
<H1 align="center">Action Bar Enhancements</H1>
<br/>
<p align="left">
    The Action Bar module has been updated to give you more aesthetic control over your UI, matching the look and feel of modern ConsolePort versions.
</p><br/>
<p align="left">
    You now have access to multiple visual presets. You can choose to stick with the classic rounded buttons, or switch to the modern, squared-off button presets to give your UI a sleek, retail-style finish.
</p>
</BODY></HTML>]])

Help:AddPage('Settings Panel', 'Features', [[<HTML><BODY>
<H1 align="center">Settings Panel</H1>
<br/>
<p align="left">
    The main configuration window has undergone a massive visual overhaul.
</p><br/>
<p align="left">
    The revamped Settings Panel features a cleaner, modernized aesthetic that makes navigating tabs, binding keys, and tweaking advanced settings significantly more intuitive and visually pleasing compared to the older layout.
</p>
</BODY></HTML>]])

Help:AddPage('Controller Presets', 'Features', [[<HTML><BODY>
<H1 align="center">Controller Presets</H1>
<br/>
<p align="left">
    ConsolePortLK includes built-in presets for the newest generation of gaming hardware.
</p><br/>
<p align="left">
    <b>Supported Presets Include:</b><br/>
    • PlayStation 5 (DualSense)<br/>
    • Xbox Series X/S<br/>
    • Steam Deck<br/><br/>

    Additionally, all of these new presets fully support extra hardware mapping. If your controller is equipped with rear paddle buttons, you can map them seamlessly within the addon.
</p>
</BODY></HTML>]])

Help:AddPage('More to Come', 'Features', [[<HTML><BODY>
<H1 align="center">More to Come</H1>
<br/>
<p align="left">
    ConsolePortLK is an active, ongoing project. New features, bug fixes, and quality-of-life updates are continuously being developed, despite not coming fast enough due to time constraints.
</p><br/>
<p align="left">
    Have an idea for a new feature? Found a bug?<br/>
    <a href="website:https://github.com/leoaviana/ConsolePortLK/issues">|cff69ccf0Click here to send suggestions or report issues directly on the GitHub page.|r</a>
</p>
</BODY></HTML>]])
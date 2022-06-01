local _, Help = ...



Help:AddPage('3.3.0 (Port, must read) Specifics', nil, [[<HTML><BODY>
<H1 align="center">Port Specifics</H1><br/>
<H2 align="left">A note to first time users on the modified version of ConsolePort for the legacy WOTLK client</H2>
<br/>
<p align="left">Some features doesn't work here due to outdated addon engine of the client, some may have workarounds though and probably some of these
features are still in help page in case of any of them getting fixed but probably disabled or not even existant on Settings page.</p>
<br/>
<H1 align="center">What is not working?</H1>
<br/>
<p align="left"><a href="page:What is not working?">|cff69ccf0You can see what has/can not been implemented and what is not currently working on this page. (click here)|r</a></p><br/>
<br/>
<H1 align="center">Workarounds</H1>
<br/>
<p align="left"><a href="page:What is not working?">|cff69ccf0Some features may need some sort of workaround by the player to work, and they are listed on this page. (click here)|r</a></p>

</BODY></HTML>]])

Help:AddPage('What is not working?', '3.3.0 (Port, must read) Specifics', [[<HTML><BODY>
<H1 align="center">What is not working?</H1>
<br/>
<p align="left">*   Camera functions: most of them cannot work on WoTLK, that's because camera features was added in Legion and there is no known workaround for that.</p><br/>
<p align="left">*   Highlight Next Target: Should not work also because if i'm not wrong, this is also a Legion feature</p><br/>
<p align="left">*   Interact Button : Interact button is partially working. It's expected to behave intelligently, when targetting a player or enemy depending on the actionbutton which is bound to the same key configured in the interact feature, it should cast a spell or use an item but that does not happen and at the moment I don't know how to fix it.</p><br/>
<p align="left">*   Loot Button : I'm not sure, but probably the same reason as Interact button, so it's disabled for now.</p><br/>
<p align="left"><a href="website:https://github.com/leoaviana/ConsolePort-WOTLK">|cff69ccf0If you see something broken, you can report on the github page of this project, click here to obtain a link|r</a></p>
<br/>
</BODY></HTML>]])

Help:AddPage('Workarounds', '3.3.0 (Port, must read) Specifics', [[<HTML><BODY>
<H1 align="center">Workarounds</H1>
<br/>
<p align="left">*   EasyMotion (Unit hotkeys): Not really a workaround but more like a tip, you will need an unitframe for this one, tested with ShadowedUnitFrames and XPerl Unitframes but hopefully will work with any unitframe addon available.<a href="page:Unit hotkeys">|cff69ccf0You can see what EasyMotion is by clicking here|r</a></p>

</BODY></HTML>]])
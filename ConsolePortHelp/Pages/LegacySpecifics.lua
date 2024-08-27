local _, Help = ...



Help:AddPage('Port Specifics', "welcome-page", [[<HTML><BODY>
<H1 align="center">Port Specifics</H1><br/>
<H2 align="left">A note to first time users on this unofficial version of ConsolePort for the legacy WOTLK client</H2>
<br/>
<p align="left">Some features doesn't work here due to outdated addon engine of the client, some may have workarounds though and probably some of these
features are still present at the advanced page in case of any of them getting fixed but probably disabled or not even available on Settings page.</p>
<br/>
<H1 align="center">What is not working?</H1>
<br/>
<p align="left"><a href="page:What is not working?">|cff69ccf0You can see what has/can not been implemented and what is not currently working on this page. (click here)|r</a></p><br/>
<br/>
<H1 align="center">Workarounds</H1>
<br/>
<p align="left"><a href="page:Workarounds and Tips">|cff69ccf0Some features may need some user work to get working properly or to have an improved user experience, they are listed on this page. (click here)|r</a></p>
<br/>
<H2 align="left">Is there any way to implement some of the important missing functions to make feature X working?</H2>
<br/>
<p align="left">Probably, with some reverse engineering and memory editing some functions can be implemented on the client (for example, camera functions) but injecting libraries and changing specific parts of memory can trigger warden and may result in a ban.</p>
<br/>
</BODY></HTML>]])

Help:AddPage('What is not working?', 'Port Specifics', [[<HTML><BODY>
<H1 align="center">What is not working?</H1>
<br/>
<p align="left">*   Camera functions: Some camera related stuff won't work on WoTLK, that's because most camera features we're implemented in Legion and there is no known workaround for that.</p><br/>
<p align="left">*   Highlight Next Target: Not possible because this is also a Legion feature</p><br/>
<p align="left">*   Interact Button/Interact Lite : Interact button is bugged because of missing functions, so it's disabled (at least for now).</p><br/>
<p align="left"><a href="website:https://github.com/leoaviana/ConsolePort-WOTLK">|cff69ccf0If you see something else broken, you can report on the github page of this project, click here to obtain a link|r</a></p>
<br/>
</BODY></HTML>]])

Help:AddPage('Workarounds and Tips', 'Port Specifics', [[<HTML><BODY>
<H1 align="center">Workarounds and Tips</H1>
<br/>
<p align="left">*   EasyMotion (Unit hotkeys): You will need an unitframe addon to be able to use this feature, tested with ShadowedUnitFrames and XPerl Unitframes but hopefully will work with any unitframe addon available.<a href="page:Unit hotkeys">|cff69ccf0You can see what EasyMotion is by clicking here|r</a></p>

</BODY></HTML>]])
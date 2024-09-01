# ConsolePortLK

This AddOn is the backported version of ConsolePort 1.9.17 for World of Warcraft - Wrath of the Lich King legacy client (3.3.5a).<br /><br />

Beware that the World of Warcraft 3.3.5a client is old and it's no longer supported, this project has been created only for learning purposes (Lua programming).<br/><br/>

I have ported it long time ago and never released, now I'm finally sharing what I was able to do. It may not have complete ConsolePort 1.9.17 functionality parity due to missing functions in the old client Lua API implementation but I believe it is in an usable state, but it has not been extensively tested (raids, instances, battlegrounds)
so there might be bugs but I believe I've fixed most if not all game breaking bugs.

<br />

<h2>What is ConsolePort?</h2>
ConsolePort is an interface add-on for World of Warcraft that will give you a handful of nifty features
in order to let you play the game on a controller - without inconvenience.
<br/><br/>
Consisting of several modules, ConsolePort is a fully-fledged solution to handling all the quirks in a game where gamepad support was not intended,
including interface navigation, custom-tailored UI elements to assist in gameplay. You will need a controller mapping software to use this AddOn.
the original project used a app called WoWmapper which already did the mapping automatically, I basically forked and updated WoWmapper
to have a better integration with the Wrath of the Lich King (3.3.5a) client using it's older memory reading functions and increase controller compatibility, however it's not required, you can use any controller mapping software.

## Screenshots:

<a href="https://user-images.githubusercontent.com/54692677/138369605-3ba273e8-598c-4549-9826-a4edc5411a3e.png">
<img src="https://user-images.githubusercontent.com/54692677/138370327-3c0b24b0-9ea5-4d90-bcf4-eb4638217f00.png" align="right" width="48.5%">
</a>
<a href="https://user-images.githubusercontent.com/54692677/138370446-ceae8a27-5276-4888-94b4-b747a8e1ed40.png">
<img src="https://user-images.githubusercontent.com/54692677/138370452-ddfb95dc-aa13-419d-bf03-4e2502a8a3bb.png" width="48.5%">
</a>

<a href="https://user-images.githubusercontent.com/54692677/138370582-5f14f0e2-9bd7-4980-ac3b-4155e30b70df.png">
<img src="https://user-images.githubusercontent.com/54692677/138370592-054fe76a-4b55-4da0-996a-8bb68118f692.png" align="right" width="48.5%">
</a>
<a href="https://user-images.githubusercontent.com/54692677/138370708-f074085d-9396-4c3c-8bb4-3a731ea261b9.png">
<img src="https://user-images.githubusercontent.com/54692677/138370714-fe06daba-ca0e-49af-97f9-e8e5e2ffd5ca.png" width="48.5%">
</a>

<a href="https://user-images.githubusercontent.com/54692677/138371330-0a63a2ca-05e6-4707-b96a-c73c841f5955.png">
<img src="https://user-images.githubusercontent.com/54692677/138371293-e03b7df5-b74e-4dba-abd2-0aa0eea5a2d6.png" align="right" width="48.5%">
</a>
<a href="https://user-images.githubusercontent.com/54692677/138371431-185684b8-f1f4-4d22-af17-47716daa1703.png">
<img src="https://user-images.githubusercontent.com/54692677/138371373-c0a53844-710b-4fbe-90bc-261b5b7cd016.png" width="48.5%">
</a>


## Installation:

1. Download **[Latest Version](https://github.com/leoaviana/ConsolePortLK/releases/latest)**
2. Unpack the Zip file
3. Copy (or drag and drop) all of the extracted folders (ConsolePort, ConsolePortBar, etc.) into your Wow-Directory\Interface\AddOns
4. Download **[WoWmapperX](https://github.com/leoaviana/WoWmapperX)**
5. Start WoWmapperX and connect your controller.
5. Restart WoW

## Commands:

    /cp               Show all addon commands in the chatbox
    /cp actionbar     Modify controller actionbar
    /cp config        Open the configuration panel
    /cp cvar          (Advanced) list of console variables
    /cp help          Help & Tutorials
    /cp recalibrate   Recalibrate your controller
    /cp resetall      Full addon reset (irreversible)
    /cp type          Change controller type

## FAQ:

### I would like to report a bug. What i need to do?
Make sure you're using the latest version of [ConsolePort](https://github.com/leoaviana/ConsolePortLK/releases/latest)
<br />
Describe your issue in as much detail as possible.
<br />
If your issue is graphical, please take some screenshots to illustrate it.
<br />
What were you doing when the problem occurred?
<br />
Explain how people can reproduce the issue.
<br />
<br />
### Can you port this to 2.4.3 or older?
ConsolePort relies mostly on [RestrictedEnvironment](https://wowwiki-archive.fandom.com/wiki/RestrictedEnvironment) functions and [SecureHandlers](https://wowwiki-archive.fandom.com/wiki/SecureHandlers), most of those we're implemented into the game client after patch 3.0, so <b>no.</b> I'm not saying that it is completely impossible to port because I don't know but as far I know there is no alternatives to RestrictedEnvironment on older clients, it seems like that there is an alternative to SecureHandlers implemented in patch 2.0 but the documentation about it is scarce and I do not have any interest in porting it to older versions.

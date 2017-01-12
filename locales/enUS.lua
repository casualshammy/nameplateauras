local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "enUS", true);
L["Default icon size"] = true;
L["General"] = true;
L["Profiles"] = true;
L["Icon X-coord offset"] = true;
L["Icon Y-coord offset"] = true;
L["Space between icons"] = true;
L["Text"] = true;
L["Icon borders"] = true;
L["Spells"] = true;
L["Open profiles dialog"] = true;
L["Border thickness"] = true;
L["Show border around buff icons"] = true;
L["Show border around debuff icons"] = true;
L["Magic"] = true;
L["Curse"] = true;
L["Disease"] = true;
L["Poison"] = true;
L["Other"] = true;
L["Add new spell: "] = true;
L["Add spell"] = true;
L["Click to select spell"] = true;
L["Delete all spells"] = true;
L["Do you really want to delete ALL spells?"] = true;
L["Yes"] = true;
L["No"] = true;
L["Spell seems to be nonexistent"] = true;
L["Spell already exists (%s)"] = true;
L["Unknown spell: %s"] = true;
L[ [=[You should enter spell name instead of spell id.
Use "%s" option if you want to track spell with specific id]=] ] = true;
L["Check spell ID"] = true;
L["Please reload UI to apply changes"] = true;
L["Reload UI"] = true;
L["Options are not available in combat!"] = true;
L["Value must be a number"] = true;
L["Always display icons at full opacity (ReloadUI is required)"] = true;
L["Hide Blizzard's aura frames (Reload UI is required)"] = true;
L["Display tenths of seconds"] = true;
L["Display auras on player's nameplate"] = true;
L["Display auras on nameplates of friendly units"] = true;
L["Always show auras cast by myself"] = true;
L["Timer style:"] = true;
L["Icon anchor:"] = true;
L["Frame anchor:"] = true;
L["Sort mode:"] = true;
L["None"] = true;
L["By expire time, ascending"] = true;
L["By expire time, descending"] = true;
L["By icon size, ascending"] = true;
L["By icon size, descending"] = true;
L["By aura type (de/buff) + expire time"] = true;
L["Texture with timer"] = true;
L["Circular"] = true;
L["Circular with OmniCC support"] = true;
L["Circular with timer"] = true;
L["Font"] = true;
L["Font scale"] = true;
L["Font size"] = true;
L["Anchor point"] = true;
L["Anchor to icon"] = true;
L["X offset"] = true;
L["Y offset"] = true;
L["< 5sec"] = true;
L["< 1min"] = true;
L["> 1min"] = true;
L["Text color"] = true;
L["Stack text"] = true;
L["Timer text"] = true;
L[ [=[Scale font size
according to
icon size]=] ] = true;
L["Icon size"] = true;
L["Aura type"] = true;
L["Mode"] = true;
L["Delete spell"] = true;
L["Disabled"] = true;
L["All auras"] = true;
L["Only my auras"] = true;
L["Show this aura on nameplates of allies"] = true;
L["Show this aura on nameplates of enemies"] = true;
L["TOPRIGHT"] = "Top right";
L["RIGHT"] = "Right";
L["BOTTOMRIGHT"] = "Bottom right";
L["TOP"] = "Top";
L["CENTER"] = "Center";
L["BOTTOM"] = "Bottom";
L["TOPLEFT"] = "Top left";
L["LEFT"] = "Left";
L["BOTTOMLEFT"] = "Bottom left";
L["Buff"] = true;
L["Debuff"] = true;
L["Any"] = true;
L["options:aura-options:allow-multiple-instances"] = "Allow multiple instances of this aura";
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[If this option is checked, you will see all instances of this aura, even on the same nameplate.
Otherwise you will see only one instance of this aura (the longest one)]=];


L["options:general:always-show-my-auras:tooltip"] = [=[This is top priority filter. If you enable this feature,
your auras will be shown regardless of another filters]=];
L["options:timer-text:text-color-note"] = [=[Text colour will be changed
depending on the time remaining:]=];
L["options:auras:enabled-state-mineonly"] = "Enabled, show only my auras";
L["options:auras:enabled-state-all"] = "Enabled, show all auras";
L["options:auras:enabled-state:tooltip"] = [=[Enables/disables aura

%s: aura will not be shown
%s: aura will be shown if you've cast it
%s: show all auras]=];
L["options:auras:pvp-state-indefinite"] = "Show this aura during PvP combat";
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Show this aura during PvP combat only";
L["options:auras:pvp-state-dontshowinpvp"] = "Don't show this aura during PvP combat";
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Minimum duration to display tenths of seconds";
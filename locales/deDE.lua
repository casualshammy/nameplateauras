local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "deDE");
L = L or {}
L["< 1min"] = "< 1 Min."
L["< 5sec"] = "< 5 Sek."
L["> 1min"] = "> 1 Min."
L["Add new spell: "] = "Neuen Zauber hinzufügen:"
L["Add spell"] = "Zauber hinzufügen"
L["All auras"] = "Alle Auren"
L["Always display icons at full opacity (ReloadUI is required)"] = "Symbole immer mit voller Deckkraft anzeigen (UI-Neuladen erforderlich)"
L["Always show auras cast by myself"] = "Auren, die ich gewirkt habe, immer anzeigen"
L["Anchor point"] = "Ankerpunkt"
L["Anchor to icon"] = "Am Symbol anheften"
L["Any"] = "Irgendeiner"
L["Aura type"] = "Auratyp"
L["Border thickness"] = "Randdicke"
L["BOTTOM"] = "Unten"
L["BOTTOMLEFT"] = "Unten links"
L["BOTTOMRIGHT"] = "Unten rechts"
L["Buff"] = "Stärkungszauber"
L["By aura type (de/buff) + expire time"] = "Nach Auratyp (Stärkungs-/Schwächungszauber) und Ablaufzeit"
L["By expire time, ascending"] = "Nach Ablaufzeit, zunehmend"
L["By expire time, descending"] = "Nach Ablaufzeit, abnehmend"
L["By icon size, ascending"] = "Nach Symbolgröße, zunehmend"
L["By icon size, descending"] = "Nach Symbolgröße, abnehmend"
L["CENTER"] = "Mittig"
L["Check spell ID"] = "Zauber-ID prüfen"
L["Circular"] = "Kreisförmig"
L["Circular with OmniCC support"] = "Kreisförmig mit OmniCC-Unterstützung"
L["Circular with timer"] = "Kreisförmig mit Timer"
L["Click to select spell"] = "Klicken, um einen Zauber auszuwählen"
L["Curse"] = "Fluch"
L["Debuff"] = "Schwächungszauber"
L["Default icon size"] = "Standard-Symbolgröße"
L["Delete all spells"] = "Alle Zauber entfernen"
L["Delete spell"] = "Zauber löschen"
L["Disabled"] = "Deaktiviert"
L["Disease"] = "Krankheit"
L["Display auras on nameplates of friendly units"] = "Auren auf Namensplaketten verbündeter Einheiten anzeigen"
L["Display auras on player's nameplate"] = "Auren auf der Namensplakette des Spieler anzeigen"
L["Display tenths of seconds"] = "Zehntelsekunden anzeigen"
L["Do you really want to delete ALL spells?"] = "Willst du wirklich ALLE Zauber entfernen?"
L["Font"] = "Schriftart"
L["Font scale"] = "Schriftskalierung"
L["Font size"] = "Schriftgröße"
L["Frame anchor:"] = "Rahmenanker"
L["General"] = "Allgemein"
L["Hide Blizzard's aura frames (Reload UI is required)"] = "Blizzards Auraelemente ausblenden (UI-Neuladen erforderlich)"
L["Icon anchor:"] = "Symbolanker:"
L["Icon borders"] = "Symbolrahmen"
L["Icon size"] = "Symbolgröße"
L["Icon X-coord offset"] = "Symbolverschiebung X-Richtung"
L["Icon Y-coord offset"] = "Symbolverschiebung Y-Richtung"
L["LEFT"] = "Links"
L["Magic"] = "Magie"
L["Mode"] = "Modus"
L["No"] = "Nein"
L["None"] = "Keine"
L["Only my auras"] = "Nur meine Auren"
L["Open profiles dialog"] = "Profildialog öffnen"
L["Options are not available in combat!"] = "Optionen sind im Kampf nicht verfügbar!"
L["options:aura-options:allow-multiple-instances"] = "Mehrere Exemplare dieser Aura erlauben"
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[Falls diese Option angehakt ist, wirst du alle Exemplare dieser Aura sehen, auch wenn diese sich auf derselben Namensplakette befinden.
Anderenfalls wirst du nur ein Exemplar dieser Aura sehen (die mit der größten Restdauer)]=]
L["options:auras:add-new-spell:error1"] = [=[Du solltest den Zaubernamen anstatt die Zauber-ID eingeben.
Verwende die Option "%s", wenn du Zauber mit einer bestimmten ID verfolgen möchtest.]=]
--Translation missing 
L["options:auras:enabled-state:tooltip"] = [=[Enables/disables aura

%s: aura will not be shown
%s: aura will be shown if you've cast it
%s: show all auras]=]
--Translation missing 
L["options:auras:enabled-state-all"] = "Enabled, show all auras"
--Translation missing 
L["options:auras:enabled-state-mineonly"] = "Enabled, show only my auras"
--Translation missing 
L["options:auras:pvp-state-dontshowinpvp"] = "Don't show this aura during PvP combat"
--Translation missing 
L["options:auras:pvp-state-indefinite"] = "Show this aura during PvP combat"
--Translation missing 
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Show this aura during PvP combat only"
--Translation missing 
L["options:general:always-show-my-auras:tooltip"] = [=[This is top priority filter. If you enable this feature,
your auras will be shown regardless of other filters]=]
--Translation missing 
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Minimum duration to display tenths of seconds"
L["options:timer-text:scale-font-size"] = [=[Schriftgröße an
Symbolgröße
anpassen]=]
--Translation missing 
L["options:timer-text:text-color-note"] = [=[Text colour will change
depending on the time remaining:]=]
L["Other"] = "Andere"
L["Please reload UI to apply changes"] = "Bitte UI neuladen, um Änderungen zu übernehmen"
L["Poison"] = "Gift"
L["Profiles"] = "Profile"
L["Reload UI"] = "UI neuladen"
L["RIGHT"] = "Rechts"
L["Show border around buff icons"] = "Rahmen um Stärkungszaubersymbole zeigen"
L["Show border around debuff icons"] = "Rahmen um Schwächungszaubersymbole zeigen"
L["Show this aura on nameplates of allies"] = "Diese Aura auf Namensplaketten Verbündeter anzeigen"
L["Show this aura on nameplates of enemies"] = "Diese Aura auf Namensplaketten von Feinden anzeigen"
L["Sort mode:"] = "Anordnung:"
L["Space between icons"] = "Platz zwischen Symbolen"
L["Spell already exists (%s)"] = "Zauber existiert bereits (%s)"
L["Spell seems to be nonexistent"] = "Zauber scheint nicht zu existieren"
L["Spells"] = "Zauber"
L["Stack text"] = "Stapeltext"
L["Text"] = "Text"
L["Text color"] = "Textfarbe"
L["Texture with timer"] = "Textur mit Timer"
L["Timer style:"] = "Timerstil:"
L["Timer text"] = "Timertext"
L["TOP"] = "Oben"
L["TOPLEFT"] = "Oben links"
L["TOPRIGHT"] = "Oben rechts"
L["Unknown spell: %s"] = "Unbekannter Zauber: %s"
L["Value must be a number"] = "Wert muss eine Zahl sein"
L["X offset"] = "X-Verschiebung"
L["Y offset"] = "Y-Verschiebung"
L["Yes"] = "Ja"

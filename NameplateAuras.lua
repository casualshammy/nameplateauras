local _, addonTable = ...;

local L = LibStub("AceLocale-3.0"):GetLocale("NameplateAuras");
local LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;
local SML = LibStub("LibSharedMedia-3.0");
SML:Register("font", "NAuras_TeenBold", 		"Interface\\AddOns\\NameplateAuras\\media\\teen_bold.ttf", 255);
SML:Register("font", "NAuras_TexGyreHerosBold", "Interface\\AddOns\\NameplateAuras\\media\\texgyreheros-bold-webfont.ttf", 255);

-- // upvalues
local 	_G, pairs, select, WorldFrame, string_match,string_gsub,string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitBuff, UnitDebuff, string_lower,
			UnitReaction, UnitGUID, UnitIsFriend, table_insert, table_sort, table_remove, IsUsableSpell, CTimerAfter =
		_G, pairs, select, WorldFrame, strmatch, 	gsub,		strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitBuff, UnitDebuff, string.lower,
			UnitReaction, UnitGUID, UnitIsFriend, table.insert, table.sort, table.remove, IsUsableSpell, C_Timer.After;

NameplateAurasDB = {};
local SpellTextureByID = setmetatable({}, {
	__index = function(t, key)
		local texture = GetSpellTexture(key);
		t[key] = texture;
		return texture;
	end
});
local SpellNameByID = setmetatable({}, {
	__index = function(t, key)
		local spellName = GetSpellInfo(key);
		t[key] = spellName;
		return spellName;
	end
});
local AllSpellIDsAndIconsByName 	= { };
local AurasPerNameplate 			= { };
local EnabledAurasInfo				= { };
local ElapsedTimer 					= 0;
local Nameplates 					= { };
local NameplatesVisible 			= { };
local LocalPlayerFullName 			= UnitName("player") .. " - " .. GetRealmName();
local InPvPCombat					= false;
local GUIFrame, EventFrame, db, aceDB, LocalPlayerGUID, ProfileOptionsFrame, CoroutineProcessor;

-- // enums as variables: it's done for better performance
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS = 1, 2, 3;
local AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = 1, 2, 3;
local AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIREASC, AURA_SORT_MODE_EXPIREDES, AURA_SORT_MODE_ICONSIZEASC, AURA_SORT_MODE_ICONSIZEDES, AURA_SORT_MODE_AURATYPE_EXPIRE = 1, 2, 3, 4, 5, 6;
local TIMER_STYLE_TEXTURETEXT, TIMER_STYLE_CIRCULAR, TIMER_STYLE_CIRCULAROMNICC, TIMER_STYLE_CIRCULARTEXT = 1, 2, 3, 4;
local CONST_SPELL_PVP_MODES_UNDEFINED, CONST_SPELL_PVP_MODES_INPVPCOMBAT, CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = 1, 2, 3;

local OnStartup, ReloadDB, GetDefaultDBSpellEntry, UpdateSpellCachesFromDB;
local AllocateIcon, UpdateAllNameplates, ProcessAurasForNameplate, UpdateNameplate, Nameplates_OnFontChanged, Nameplates_OnDefaultIconSizeOrOffsetChanged, Nameplates_OnSortModeChanged, Nameplates_OnTextPositionChanged,
	Nameplates_OnIconAnchorChanged, Nameplates_OnFrameAnchorChanged, Nameplates_OnBorderThicknessChanged, OnUpdate;
local ShowGUI, GUICategory_1, GUICategory_2, GUICategory_4, GUICategory_Fonts, GUICategory_AuraStackFont, GUICategory_Borders;
local Print, deepcopy, msg, msgWithQuestion, table_contains_value, table_count, ColorizeText;

--------------------------------------------------------------------------------------------------
----- Initialize
--------------------------------------------------------------------------------------------------
do

	local function InitializeDB()
		-- // set defaults
		local aceDBDefaults = {
			profile = {
				DefaultSpellsLastSetImported = 0,
				CustomSpells2 = { },
				IconXOffset = 0,
				IconYOffset = 50,
				FullOpacityAlways = false,
				Font = "NAuras_TeenBold",
				HideBlizzardFrames = true,
				DefaultIconSize = 45,
				SortMode = AURA_SORT_MODE_EXPIREASC,
				FontScale = 1,
				TimerTextUseRelativeScale = true,
				TimerTextSize = 20,
				TimerTextAnchor = "CENTER",
				TimerTextAnchorIcon = "UNKNOWN",
				TimerTextXOffset = 0,
				TimerTextYOffset = 0,
				TimerTextSoonToExpireColor = { 1, 0.1, 0.1 },
				TimerTextUnderMinuteColor = { 1, 1, 0.1 },
				TimerTextLongerColor = { 0.7, 1, 0 },
				StacksFont = "NAuras_TeenBold",
				StacksFontScale = 1,
				StacksTextAnchor = "BOTTOMRIGHT",
				StacksTextAnchorIcon = "UNKNOWN",
				StacksTextXOffset = -3,
				StacksTextYOffset = 5,
				StacksTextColor = { 1, 0.1, 0.1 },
				TimerStyle = TIMER_STYLE_TEXTURETEXT,
				ShowBuffBorders = true,
				BuffBordersColor = {0, 1, 0},
				ShowDebuffBorders = true,
				DebuffBordersMagicColor = { 0.1, 1, 1 },
				DebuffBordersCurseColor = { 1, 0.1, 1 },
				DebuffBordersDiseaseColor = { 1, 0.5, 0.1 },
				DebuffBordersPoisonColor = { 0.1, 1, 0.1 },
				DebuffBordersOtherColor = { 1, 0.1, 0.1 },
				ShowAurasOnPlayerNameplate = false,
				IconSpacing = 1,
				IconAnchor = "LEFT",
				AlwaysShowMyAuras = false,
				BorderThickness = 2,
				ShowAboveFriendlyUnits = true,
				FrameAnchor = "CENTER",
				MinTimeToShowTenthsOfSeconds = 10,
			},
		};
		
		-- // ...
		aceDB = LibStub("AceDB-3.0"):New("NameplateAurasAceDB", aceDBDefaults);
		-- // convert from old DB
		if (NameplateAurasDB[LocalPlayerFullName] ~= nil) then
			Print("Converting DB to Ace3DB...");
			for index in pairs(NameplateAurasDB[LocalPlayerFullName]) do
				aceDB.profile[index] = deepcopy(NameplateAurasDB[LocalPlayerFullName][index]);
			end
			NameplateAurasDB[LocalPlayerFullName] = nil;
			Print("DB converting is completed");
		end
		-- // adding to blizz options
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras", {
			name = "NameplateAuras",
			type = 'group',
			args = {
				openGUI = {
					type = 'execute',
					order = 1,
					name = 'Open config dialog',
					desc = nil,
					func = function()
						ShowGUI();
						if (GUIFrame) then
							InterfaceOptionsFrameCancel:Click();
						end
					end,
				},
			},
		});
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras", "NameplateAuras");
		local profilesConfig = LibStub("AceDBOptions-3.0"):GetOptionsTable(aceDB);
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras.profiles", profilesConfig);
		ProfileOptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras.profiles", "Profiles", "NameplateAuras");
		-- // processing old and invalid entries
		if (aceDB.profile.TimerTextAnchorIcon == aceDBDefaults.profile.TimerTextAnchorIcon) then
			aceDB.profile.TimerTextAnchorIcon = aceDB.profile.TimerTextAnchor;
		end
		if (aceDB.profile.StacksTextAnchorIcon == aceDBDefaults.profile.StacksTextAnchorIcon) then
			aceDB.profile.StacksTextAnchorIcon = aceDB.profile.StacksTextAnchor;
		end
		-- // creating a fast reference
		aceDB.RegisterCallback("NameplateAuras", "OnProfileChanged", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileCopied", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileReset", ReloadDB);
	end

	function OnStartup()
		-- // getting player's GUID
		LocalPlayerGUID = UnitGUID("player");
		-- // ...
		InitializeDB();
		-- // ...
		ReloadDB();
		-- // starting listening for events
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		-- // adding slash command
		SLASH_NAMEPLATEAURAS1 = '/nauras';
		SlashCmdList["NAMEPLATEAURAS"] = function(msg, editBox)
			if (msg == "ver") then
				local c = UNKNOWN;
				if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
					c = "INSTANCE_CHAT";
				elseif (IsInRaid()) then
					c = "RAID";
				else
					c = "GUILD";
				end
				Print("Waiting for replies from " .. c);
				SendAddonMessage("NAuras_prefix", "requesting", c);
			else
				ShowGUI();
			end
		end
		RegisterAddonMessagePrefix("NAuras_prefix");
		OnStartup = nil;
	end

	local function ReloadDB_SetSpellCache()
		for spellID, spellInfo in pairs(db.CustomSpells2) do
			local spellName = SpellNameByID[spellID];
			if (spellName == nil) then
				Print("<spellid:"..spellID.."> isn't exist. Removing from database...");
				db.CustomSpells2[spellID] = nil;
			else
				if (spellInfo.showOnFriends == nil) then
					spellInfo.showOnFriends = true;
				end
				if (spellInfo.showOnEnemies == nil) then
					spellInfo.showOnEnemies = true;
				end
				if (spellInfo.allowMultipleInstances == nil) then
					spellInfo.allowMultipleInstances = false;
				end
				if (spellInfo.pvpCombat == nil) then
					spellInfo.pvpCombat = CONST_SPELL_PVP_MODES_UNDEFINED;
				end
				if (spellInfo.spellID == nil) then
					db.CustomSpells2[spellID].spellID = spellID;
				end
				if (spellInfo.enabledState == "disabled") then
					spellInfo.enabledState = CONST_SPELL_MODE_DISABLED;
				elseif (spellInfo.enabledState == "all") then
					spellInfo.enabledState = CONST_SPELL_MODE_ALL;
				elseif (spellInfo.enabledState == "my") then
					spellInfo.enabledState = CONST_SPELL_MODE_MYAURAS;
				end
				if (spellInfo.auraType == "buff") then
					spellInfo.auraType = AURA_TYPE_BUFF;
				elseif (spellInfo.auraType == "debuff") then
					spellInfo.auraType = AURA_TYPE_DEBUFF;
				elseif (spellInfo.auraType == "buff/debuff") then
					spellInfo.auraType = AURA_TYPE_ANY;
				end
				UpdateSpellCachesFromDB(spellID);
			end
		end
	end
	
	local function ReloadDB_ImportNewSpells()
		if (db.DefaultSpellsLastSetImported < #addonTable.DefaultSpells2) then
			local spellNamesAlreadyInUsersDB = { };
			for _, spellInfo in pairs(db.CustomSpells2) do
				local spellName = SpellNameByID[spellInfo.spellID];
				if (spellName ~= nil) then
					spellNamesAlreadyInUsersDB[spellName] = true;
				end
			end
			local allNewSpells = { };
			for i = db.DefaultSpellsLastSetImported + 1, #addonTable.DefaultSpells2 do
				local set = addonTable.DefaultSpells2[i];
				for spellID, spellInfo in pairs(set) do
					if (SpellNameByID[spellID] ~= nil and not spellNamesAlreadyInUsersDB[SpellNameByID[spellID]]) then
						allNewSpells[spellID] = spellInfo;
					end
				end
			end
			if (db.DefaultSpellsLastSetImported == 0) then
				for spellID, spellInfo in pairs(allNewSpells) do
					db.CustomSpells2[spellID] = spellInfo;
				end
			else
				if (table_count(allNewSpells) > 0) then
					msgWithQuestion("NameplateAuras\n\nNew and changed spells (total " .. table_count(allNewSpells) .. ") are available for import. Do you want to print their names in chat window?\n(If you click \"Yes\", you will be able to import new spells. If you click \"No\", this prompt will not appear again)",
						function()
							for spellID in pairs(allNewSpells) do
								local link = GetSpellLink(spellID);
								if (link ~= nil) then Print(link); end
							end
							C_Timer.After(0.5, function()
								msgWithQuestion("NameplateAuras\n\nDo you want to import new spells?",
									function()
										for spellID, spellInfo in pairs(allNewSpells) do
											db.CustomSpells2[spellID] = spellInfo;
										end
										ReloadDB_SetSpellCache();
										Print("Imported successfully");
									end,
									function() end);
							end);
						end,
						function() end);
				end
			end
			db.DefaultSpellsLastSetImported = #addonTable.DefaultSpells2;
		end
	end
	
	local function ReloadDB_ConvertInvalidValues()
		for _, entry in pairs({ "IconSize", "DebuffBordersColor", "DisplayBorders", "ShowMyAuras", "DefaultSpells" }) do
			if (db[entry] ~= nil) then
				db[entry] = nil;
				Print("Old db record is deleted: " .. entry);
			end
		end
		if (db.TimerTextSizeMode ~= nil) then
			db.TimerTextUseRelativeScale = (db.TimerTextSizeMode == "relative");
			db.TimerTextSizeMode = nil;
		end
		if (db.SortMode ~= nil and type(db.SortMode) == "string") then
			local replacements = { ["none"] = AURA_SORT_MODE_NONE, ["by-expire-time-asc"] = AURA_SORT_MODE_EXPIREASC, ["by-expire-time-des"] = AURA_SORT_MODE_EXPIREDES,
				["by-icon-size-asc"] = AURA_SORT_MODE_ICONSIZEASC, ["by-icon-size-des"] = AURA_SORT_MODE_ICONSIZEDES, ["by-aura-type-expire-time"] = AURA_SORT_MODE_AURATYPE_EXPIRE };
			db.SortMode = replacements[db.SortMode];
		end
		if (db.TimerStyle ~= nil and type(db.TimerStyle) == "string") then
			local replacements = { [TIMER_STYLE_TEXTURETEXT] = "texture-with-text", [TIMER_STYLE_CIRCULAR] = "cooldown-frame-no-text", [TIMER_STYLE_CIRCULAROMNICC] = "cooldown-frame", [TIMER_STYLE_CIRCULARTEXT] = "circular-noomnicc-text" };
			for newValue, oldValue in pairs(replacements) do
				if (db.TimerStyle == oldValue) then
					db.TimerStyle = newValue;
					break;
				end
			end
		end
		if (db.DisplayTenthsOfSeconds ~= nil) then
			db.MinTimeToShowTenthsOfSeconds = db.DisplayTenthsOfSeconds and 10 or 0;
			db.DisplayTenthsOfSeconds = nil;
		end
		if (db.DefaultSpellsAreImported ~= nil) then
			db.DefaultSpellsLastSetImported = 1;
			db.DefaultSpellsAreImported = nil;
		end
	end
	
	function ReloadDB()
		db = aceDB.profile;
		-- // resetting all caches
		wipe(EnabledAurasInfo);
		-- // convert values
		ReloadDB_ConvertInvalidValues();
		-- // import default spells
		ReloadDB_ImportNewSpells();
		-- // setting caches...
		ReloadDB_SetSpellCache();
		-- // starting OnUpdate()
		if (db.TimerStyle == TIMER_STYLE_TEXTURETEXT or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			EventFrame:SetScript("OnUpdate", function(self, elapsed)
				ElapsedTimer = ElapsedTimer + elapsed;
				if (ElapsedTimer >= 0.1) then
					OnUpdate();				
					ElapsedTimer = 0;
				end
			end);
		else
			EventFrame:SetScript("OnUpdate", nil);
		end
		if (GUIFrame) then
			for _, func in pairs(GUIFrame.OnDBChangedHandlers) do
				func();
			end
		end
		Nameplates_OnFontChanged();
		Nameplates_OnFrameAnchorChanged();
		Nameplates_OnTextPositionChanged();
		Nameplates_OnIconAnchorChanged();
		UpdateAllNameplates(true);
	end
	
	function GetDefaultDBSpellEntry(enabledState, spellID, iconSize, checkSpellID)
		return {
			["enabledState"] =				enabledState,
			["auraType"] =					AURA_TYPE_ANY,
			["iconSize"] =					(iconSize ~= nil) and iconSize or db.DefaultIconSize,
			["spellID"] =					spellID,
			["checkSpellID"] =				checkSpellID,
			["showOnFriends"] =				true,
			["showOnEnemies"] =				true,
			["allowMultipleInstances"] =	false,
			["pvpCombat"] =					CONST_SPELL_PVP_MODES_UNDEFINED,
			["showGlow"] =					nil,
		};
	end
	
	function UpdateSpellCachesFromDB(spellID)
		local spellName = SpellNameByID[spellID];
		if (db.CustomSpells2[spellID] ~= nil and db.CustomSpells2[spellID].enabledState ~= CONST_SPELL_MODE_DISABLED) then
			EnabledAurasInfo[spellName] = {
				["enabledState"] =				db.CustomSpells2[spellID].enabledState,
				["auraType"] =					db.CustomSpells2[spellID].auraType,
				["iconSize"] =					db.CustomSpells2[spellID].iconSize,
				["checkSpellID"] =				db.CustomSpells2[spellID].checkSpellID,
				["showOnFriends"] =				db.CustomSpells2[spellID].showOnFriends,
				["showOnEnemies"] =				db.CustomSpells2[spellID].showOnEnemies,
				["allowMultipleInstances"] =	db.CustomSpells2[spellID].allowMultipleInstances,
				["pvpCombat"] =					db.CustomSpells2[spellID].pvpCombat,
				["showGlow"] =					db.CustomSpells2[spellID].showGlow,
			};
		else
			EnabledAurasInfo[spellName] = nil;
		end
	end
		
end

--------------------------------------------------------------------------------------------------
----- Nameplates
--------------------------------------------------------------------------------------------------
do
	
	local BORDER_TEXTURES = {
		"Interface\\AddOns\\NameplateAuras\\media\\icon-border-1px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-2px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-3px.tga",
		"Interface\\AddOns\\NameplateAuras\\media\\icon-border-4px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-5px.tga",
	};
	
	function AllocateIcon(frame, widthUsed)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, db.FullOpacityAlways and WorldFrame or frame);
			frame.NAurasFrame:SetWidth(db.DefaultIconSize);
			frame.NAurasFrame:SetHeight(db.DefaultIconSize);
			frame.NAurasFrame:SetPoint(db.FrameAnchor, frame, db.IconXOffset, db.IconYOffset);
			frame.NAurasFrame:Show();
		end
		local icon = CreateFrame("Frame", nil, frame.NAurasFrame);
		icon:SetPoint(db.IconAnchor, frame.NAurasFrame, widthUsed, 0);
		icon:SetSize(db.DefaultIconSize, db.DefaultIconSize);
		icon.texture = icon:CreateTexture(nil, "BORDER");
		icon.texture:SetAllPoints(icon);
		icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		icon.border = icon:CreateTexture(nil, "OVERLAY");
		icon.stacks = icon:CreateFontString(nil, "OVERLAY");
		icon.cooldownText = icon:CreateFontString(nil, "OVERLAY");
		if (db.TimerStyle == TIMER_STYLE_CIRCULAR or db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			icon.cooldownFrame = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
			icon.cooldownFrame:SetAllPoints(icon);
			icon.cooldownFrame:SetReverse(true);
			if (db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC) then
				icon.cooldownFrame:SetDrawEdge(false);
				icon.cooldownFrame:SetDrawSwipe(true);
				icon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.8);
				icon.cooldownFrame:SetHideCountdownNumbers(true);
			else
				icon.cooldownFrame.noCooldownCount = true;
			end
			icon.SetCooldown = function(self, startTime, duration)
				if (startTime == 0) then duration = 0; end
				icon.cooldownFrame:SetCooldown(startTime, duration);
			end;
			hooksecurefunc(icon.stacks, "SetText", function(self, text)
				if (text ~= "") then
					if (icon.cooldownFrame:GetCooldownDuration() == 0) then
						icon.stacks:SetParent(icon);
					else
						icon.stacks:SetParent(icon.cooldownFrame);
					end
				end
			end);
			hooksecurefunc(icon.cooldownText, "SetText", function(self, text)
				if (text ~= "") then
					if (icon.cooldownFrame:GetCooldownDuration() == 0) then
						icon.cooldownText:SetParent(icon);
					else
						icon.cooldownText:SetParent(icon.cooldownFrame);
					end
				end
			end);
		end
		icon.size = db.DefaultIconSize;
		icon:Hide();
		icon.cooldownText:SetTextColor(0.7, 1, 0);
		icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
		if (db.TimerTextUseRelativeScale) then
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((db.DefaultIconSize - db.DefaultIconSize / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		icon.border:SetTexture(BORDER_TEXTURES[db.BorderThickness]);
		icon.border:SetVertexColor(1, 0.35, 0);
		icon.border:SetAllPoints(icon);
		icon.border:Hide();
		icon.stacks:SetTextColor(unpack(db.StacksTextColor));
		icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((db.DefaultIconSize / 4) * db.StacksFontScale), "OUTLINE");
		icon.stackcount = 0;
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
		tinsert(frame.NAurasIcons, icon);
	end
		
	local function HideCDIcon(icon)
		icon.border:Hide();
		icon.borderState = nil;
		icon.cooldownText:Hide();
		icon.stacks:Hide();
		icon:Hide();
		icon.shown = false;
		icon.spellID = -1;
		icon.stackcount = -1;
		icon.size = -1;
		LBG_HideOverlayGlow(icon);
	end
	
	local function ShowCDIcon(icon)
		icon.cooldownText:Show();
		icon.stacks:Show();
		icon:Show();
		icon.shown = true;
	end
	
	local function ResizeIcon(icon, size, widthAlreadyUsed)
		icon:SetSize(size, size);
		icon:SetPoint(db.IconAnchor, icon:GetParent(), widthAlreadyUsed, 0);
		if (db.TimerTextUseRelativeScale) then
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((size - size / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((size / 4) * db.StacksFontScale), "OUTLINE");
	end
	
	function UpdateAllNameplates(force)
		if (force) then
			for nameplate in pairs(Nameplates) do
				if (nameplate.NAurasFrame) then
					for _, icon in pairs(nameplate.NAurasIcons) do
						HideCDIcon(icon);
					end
				end
			end
		end
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame and nameplate.UnitFrame.unit) then
				ProcessAurasForNameplate(nameplate, nameplate.UnitFrame.unit);
			end
		end
	end
		
	local function ProcessAurasForNameplate_Filter(isBuff, auraName, auraCaster, auraSpellID, unitIsFriend)
		if (db.AlwaysShowMyAuras and auraCaster == "player") then
			return true;
		else
			local spellInfo = EnabledAurasInfo[auraName];
			if (spellInfo ~= nil) then
				if (spellInfo.enabledState == CONST_SPELL_MODE_ALL or (spellInfo.enabledState == CONST_SPELL_MODE_MYAURAS and auraCaster == "player")) then
					if ((not unitIsFriend and spellInfo.showOnEnemies) or (unitIsFriend and spellInfo.showOnFriends)) then
						if (spellInfo.auraType == AURA_TYPE_ANY or (isBuff and spellInfo.auraType == AURA_TYPE_BUFF or spellInfo.auraType == AURA_TYPE_DEBUFF)) then
							local showInPvPCombat = spellInfo.pvpCombat;
							if (showInPvPCombat == CONST_SPELL_PVP_MODES_UNDEFINED or (showInPvPCombat == CONST_SPELL_PVP_MODES_INPVPCOMBAT and InPvPCombat) or (showInPvPCombat == CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT and not InPvPCombat)) then
								if (spellInfo.checkSpellID == nil or spellInfo.checkSpellID == auraSpellID) then
									return true;
								end
							end
						end
					end
				end
			end
		end
		return false;
	end
	
	local function ProcessAurasForNameplate_MultipleAuraInstances(frame, auraName, auraExpires, auraStack)
		if (EnabledAurasInfo[auraName] ~= nil and EnabledAurasInfo[auraName].allowMultipleInstances) then
			return true;
		else
			for index, value in pairs(AurasPerNameplate[frame]) do
				if (value.spellName == auraName) then
					if (value.expires < auraExpires or value.stacks ~= auraStack) then
						AurasPerNameplate[frame][index] = nil;
						return true;
					else
						return false;
					end
				end
			end
			return true;
		end
		error("Fatal error in <ProcessAurasForNameplate_MultipleAuraInstances>");
	end
		
	function ProcessAurasForNameplate(frame, unitID)
		wipe(AurasPerNameplate[frame]);
		local unitIsFriend = UnitIsFriend("player", unitID);
		if ((LocalPlayerGUID ~= UnitGUID(unitID) or db.ShowAurasOnPlayerNameplate) and (db.ShowAboveFriendlyUnits or not unitIsFriend)) then
			for i = 1, 40 do
				local buffName, _, _, buffStack, _, buffDuration, buffExpires, buffCaster, _, _, buffSpellID = UnitBuff(unitID, i);
				if (buffName ~= nil) then
					if (ProcessAurasForNameplate_Filter(true, buffName, buffCaster, buffSpellID, unitIsFriend)) then
						if (ProcessAurasForNameplate_MultipleAuraInstances(frame, buffName, buffExpires, buffStack)) then
							table_insert(AurasPerNameplate[frame], {
								["duration"] = buffDuration ~= 0 and buffDuration or 4000000000,
								["expires"] = buffExpires ~= 0 and buffExpires or 4000000000,
								["stacks"] = buffStack,
								["spellID"] = buffSpellID,
								["type"] = AURA_TYPE_BUFF,
								["spellName"] = buffName
							});
						end
					end
				end
				local debuffName, _, _, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
				if (debuffName ~= nil) then
					if (ProcessAurasForNameplate_Filter(false, debuffName, debuffCaster, debuffSpellID, unitIsFriend)) then
						if (ProcessAurasForNameplate_MultipleAuraInstances(frame, debuffName, debuffExpires, debuffStack)) then
							table_insert(AurasPerNameplate[frame], {
								["duration"] = debuffDuration ~= 0 and debuffDuration or 4000000000,
								["expires"] = debuffExpires ~= 0 and debuffExpires or 4000000000,
								["stacks"] = debuffStack,
								["spellID"] = debuffSpellID,
								["type"] = AURA_TYPE_DEBUFF,
								["dispelType"] = debuffDispelType,
								["spellName"] = debuffName
							});
						end
					end
				end
				if (buffName == nil and debuffName == nil) then
					break;
				end
			end
		end
		UpdateNameplate(frame);
	end
	
	local function SortAurasForNameplate(auras)
		local t = { };
		for _, spellInfo in pairs(auras) do
			if (spellInfo.spellID ~= nil) then
				table_insert(t, spellInfo);
			end
		end
		if (db.SortMode == AURA_SORT_MODE_NONE) then
			-- // do nothing
		elseif (db.SortMode == AURA_SORT_MODE_EXPIREASC) then
			table_sort(t, function(item1, item2) return item1.expires < item2.expires end);
		elseif (db.SortMode == AURA_SORT_MODE_EXPIREDES) then
			table_sort(t, function(item1, item2) return item1.expires > item2.expires end);
		elseif (db.SortMode == AURA_SORT_MODE_ICONSIZEASC) then
			table_sort(t, function(item1, item2)
				local enabledAuraInfo1 = EnabledAurasInfo[item1.spellName];
				local enabledAuraInfo2 = EnabledAurasInfo[item2.spellName];
				return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) < (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize)
			end);
		elseif (db.SortMode == AURA_SORT_MODE_ICONSIZEDES) then
			table_sort(t, function(item1, item2)
				local enabledAuraInfo1 = EnabledAurasInfo[item1.spellName];
				local enabledAuraInfo2 = EnabledAurasInfo[item2.spellName];
				return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) > (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize)
			end);
		elseif (db.SortMode == AURA_SORT_MODE_AURATYPE_EXPIRE) then
			table_sort(t, function(item1, item2)
				if (item1.type ~= item2.type) then
					return (item1.type == AURA_TYPE_DEBUFF) and true or false;
				end
				if (item1.type == AURA_TYPE_DEBUFF) then
					return item1.expires < item2.expires;
				else
					return item1.expires > item2.expires;
				end
			end);
		end
		return t;
	end
	
	local function UpdateNameplate_SetCooldown(icon, last, spellInfo)
		if (icon.info == nil) then
			icon.info = {
				["text"] = nil,
				["colorState"] = nil,
				["cooldownExpires"] = 0,
				["cooldownDuration"] = 0,
			};
		end
		local info = icon.info;
		if (db.TimerStyle == TIMER_STYLE_TEXTURETEXT or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			if (last > 3600) then
				if (info.text ~= "") then
					icon.cooldownText:SetText("");
					info.text = "";
				end
			elseif (last >= 60) then
				local newValue = math_floor(last/60).."m";
				if (info.text ~= newValue) then
					icon.cooldownText:SetText(newValue);
					info.text = newValue;
				end
			elseif (last >= db.MinTimeToShowTenthsOfSeconds) then
				local newValue = string_format("%d", last);
				if (info.text ~= newValue) then
					icon.cooldownText:SetText(newValue);
					info.text = newValue;
				end
			else
				icon.cooldownText:SetText(string_format("%.1f", last));
				info.text = nil;
			end
			if (last >= 60) then
				if (info.colorState ~= db.TimerTextLongerColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextLongerColor));
					info.colorState = db.TimerTextLongerColor;
				end
			elseif (last >= 5) then
				if (info.colorState ~= db.TimerTextUnderMinuteColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextUnderMinuteColor));
					info.colorState = db.TimerTextUnderMinuteColor;
				end
			else
				if (info.colorState ~= db.TimerTextSoonToExpireColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextSoonToExpireColor));
					info.colorState = db.TimerTextSoonToExpireColor;
				end
			end
			if (db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
				if (spellInfo.expires ~= info.cooldownExpires or spellInfo.duration ~= info.cooldownDuration) then
					icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
					info.cooldownExpires = spellInfo.expires;
					info.cooldownDuration = spellInfo.duration;
				end
			end
		elseif (db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC or db.TimerStyle == TIMER_STYLE_CIRCULAR) then
			if (spellInfo.expires ~= info.cooldownExpires or spellInfo.duration ~= info.cooldownDuration) then
				icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
				info.cooldownExpires = spellInfo.expires;
				info.cooldownDuration = spellInfo.duration;
			end
		end
	end
	
	local function UpdateNameplate_SetStacks(icon, spellInfo)
		if (icon.stackcount ~= spellInfo.stacks) then
			if (spellInfo.stacks > 1) then
				icon.stacks:SetText(spellInfo.stacks);
			else
				icon.stacks:SetText("");
			end
			icon.stackcount = spellInfo.stacks;
		end
	end
	
	local function UpdateNameplate_SetBorder(icon, spellInfo)
		if (db.ShowBuffBorders and spellInfo.type == AURA_TYPE_BUFF) then
			if (icon.borderState ~= spellInfo.type) then
				icon.border:SetVertexColor(unpack(db.BuffBordersColor));
				icon.border:Show();
				icon.borderState = spellInfo.type;
			end
		elseif (db.ShowDebuffBorders and spellInfo.type == AURA_TYPE_DEBUFF) then
			local preciseType = spellInfo.type .. (spellInfo.dispelType or "OTHER");
			if (icon.borderState ~= preciseType) then
				local color = db["DebuffBorders" .. (spellInfo.dispelType or "Other") .. "Color"];
				icon.border:SetVertexColor(unpack(color));
				icon.border:Show();
				icon.borderState = preciseType;
			end
		else
			if (icon.borderState ~= nil) then
				icon.border:Hide();
				icon.borderState = nil;
			end
		end
	end
	
	local function UpdateNameplate_SetGlow(icon, auraInfo, iconResized)
		if (auraInfo and auraInfo.showGlow) then
			LBG_ShowOverlayGlow(icon, iconResized);
		else
			LBG_HideOverlayGlow(icon);
		end
	end
	
	function UpdateNameplate(frame)
		local counter = 1;
		local totalWidth = 0;
		local iconResized = false;
		if (AurasPerNameplate[frame]) then
			local currentTime = GetTime();
			AurasPerNameplate[frame] = SortAurasForNameplate(AurasPerNameplate[frame]);
			for _, spellInfo in pairs(AurasPerNameplate[frame]) do
				local spellName = SpellNameByID[spellInfo.spellID];
				local duration = spellInfo.duration;
				local last = spellInfo.expires - currentTime;
				if (last > 0) then
					if (counter > frame.NAurasIconsCount) then
						AllocateIcon(frame, totalWidth);
					end
					local icon = frame.NAurasIcons[counter];
					if (icon.spellID ~= spellInfo.spellID) then
						icon.texture:SetTexture(SpellTextureByID[spellInfo.spellID]);
						icon.spellID = spellInfo.spellID;
					end
					UpdateNameplate_SetCooldown(icon, last, spellInfo);
					-- // stacks
					UpdateNameplate_SetStacks(icon, spellInfo);
					-- // border
					UpdateNameplate_SetBorder(icon, spellInfo);
					-- // icon size
					local enabledAuraInfo = EnabledAurasInfo[spellName];
					local normalSize = enabledAuraInfo and enabledAuraInfo.iconSize or db.DefaultIconSize;
					if (normalSize ~= icon.size or iconResized) then
						icon.size = normalSize;
						ResizeIcon(icon, icon.size, totalWidth);
						iconResized = true;
					end
					-- // glow
					UpdateNameplate_SetGlow(icon, enabledAuraInfo, iconResized);
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					totalWidth = totalWidth + icon.size + db.IconSpacing;
					counter = counter + 1;
				end
			end
		end
		if (frame.NAurasFrame ~= nil) then
			totalWidth = totalWidth - db.IconSpacing; -- // because we don't need last spacing
			frame.NAurasFrame:SetWidth(totalWidth);
		end
		for k = counter, frame.NAurasIconsCount do
			local icon = frame.NAurasIcons[k];
			if (icon.shown) then
				HideCDIcon(icon);
			end
		end
		-- // hide standart buff frame
		if (db.HideBlizzardFrames and frame.UnitFrame.BuffFrame ~= nil) then
			frame.UnitFrame.BuffFrame:SetAlpha(0);
		end
	end
	
	function Nameplates_OnFontChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					if (icon.shown) then
						if (db.TimerTextUseRelativeScale) then
							icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((icon.size - icon.size / 2) * db.FontScale), "OUTLINE");
						else
							icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
						end
						icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((icon.size / 4) * db.StacksFontScale), "OUTLINE");
					end
				end
			end
		end
	end
	
	function Nameplates_OnDefaultIconSizeOrOffsetChanged(oldDefaultIconSize)
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				nameplate.NAurasFrame:SetPoint("CENTER", nameplate, db.IconXOffset, db.IconYOffset);
				local width = 0;
				for _, icon in pairs(nameplate.NAurasIcons) do
					if (icon.shown == true) then
						if (icon.size == oldDefaultIconSize) then
							icon.size = db.DefaultIconSize;
						end
						ResizeIcon(icon, icon.size, width);
						width = width + icon.size + db.IconSpacing;
					end
				end
				width = width - db.IconSpacing; -- // because we don't need last spacing
				nameplate.NAurasFrame:SetWidth(width);
			end
		end
	end
	
	function Nameplates_OnSortModeChanged()
		for nameplate in pairs(NameplatesVisible) do
			if (nameplate.NAurasFrame and AurasPerNameplate[nameplate] ~= nil) then
				UpdateNameplate(nameplate);
			end
		end
	end
	
	function Nameplates_OnTextPositionChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					icon.cooldownText:ClearAllPoints();
					icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
					icon.stacks:ClearAllPoints();
					icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
				end
			end
		end
	end
	
	function Nameplates_OnIconAnchorChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					icon:ClearAllPoints();
					icon:SetPoint(db.IconAnchor, nameplate.NAurasFrame, 0, 0);
				end
			end
		end
		UpdateAllNameplates(true);
	end
	
	function Nameplates_OnFrameAnchorChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				nameplate.NAurasFrame:ClearAllPoints();
				nameplate.NAurasFrame:SetPoint(db.FrameAnchor, nameplate, db.IconXOffset, db.IconYOffset);
			end
		end
		UpdateAllNameplates(true);
	end
	
	function Nameplates_OnBorderThicknessChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					icon.border:SetTexture(BORDER_TEXTURES[db.BorderThickness]);
				end
			end
		end
	end
	
	function OnUpdate()
		local currentTime = GetTime();
		for frame in pairs(NameplatesVisible) do
			local counter = 1;
			if (AurasPerNameplate[frame]) then
				for _, spellInfo in pairs(AurasPerNameplate[frame]) do
					local duration = spellInfo.duration;
					local last = spellInfo.expires - currentTime;
					if (last > 0) then
						-- // getting reference to icon
						local icon = frame.NAurasIcons[counter];
						-- // setting text
						UpdateNameplate_SetCooldown(icon, last, spellInfo);
						counter = counter + 1;
					end
				end
			end
		end
	end
	
	--@debug@
	
	local function aaaaa()
		local functions = {
			["UpdateNameplate_SetCooldown"] = 	UpdateNameplate_SetCooldown,
			["OnUpdate"] = 						OnUpdate,
		};
		local t = { };
		for funcName, func in pairs(functions) do
			local usage, calls = GetFunctionCPUUsage(func, true);
			if (calls > 0) then
				t[#t+1] = { ["name"] = funcName, ["usage"] = usage, ["calls"] = calls };
			end
		end
		table_sort(t, function(item1, item2)
			return item1.usage > item2.usage;
		end);
		print(GetTime(), "-------------------------- START");
		for _, funcInfo in pairs(t) do
			print(format("%s: usage/calls: %.5f, total calls: %d, total usage: %.5f", funcInfo.name, (funcInfo.usage/funcInfo.calls), funcInfo.calls, funcInfo.usage));
		end
		local tables = {
			["SpellTextureByID"] = 			SpellTextureByID,
			["SpellNameByID"] =				SpellNameByID,
			["AurasPerNameplate"] = 		AurasPerNameplate,
			["EnabledAurasInfo"] = 			EnabledAurasInfo,
			["Nameplates"] = 				Nameplates,
			["NameplatesVisible"] = 		NameplatesVisible,
		};
		for tName, tRef in pairs(tables) do
			print(tName, table_count(tRef));
		end
		print(GetTime(), "-------------------------- END");
		C_Timer.After(300, aaaaa);
	end
	
	function NAuras_Bench()
		aaaaa();
	end
	
	--@end-debug@
	
end

--------------------------------------------------------------------------------------------------
----- GUI
--------------------------------------------------------------------------------------------------
do

	local MAX_AURA_ICON_SIZE = 75;

	local function SetTooltip(frame, text)
		frame:HookScript("OnEnter", function(self, ...)
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
			GameTooltip:SetText(text);
			GameTooltip:Show();
		end)
		frame:HookScript("OnLeave", function(self, ...)
			GameTooltip:Hide();
		end)
	end

	local function PopupReloadUI()
		if (StaticPopupDialogs["NAURAS_MSG_RELOAD"] == nil) then
			StaticPopupDialogs["NAURAS_MSG_RELOAD"] = {
				text = L["Please reload UI to apply changes"],
				button1 = L["Reload UI"],
				OnAccept = function() ReloadUI(); end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopup_Show("NAURAS_MSG_RELOAD");
	end

	local function GUICreateCheckBoxEx(text, func)
		local checkBox = CreateFrame("CheckButton");
		checkBox:SetHeight(20);
		checkBox:SetWidth(20);
		checkBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
		checkBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
		checkBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
		checkBox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
		checkBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
		checkBox.textFrame = CreateFrame("frame", nil, checkBox);
		checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 0, 0);
		checkBox.textFrame:EnableMouse(true);
		checkBox.textFrame:HookScript("OnEnter", function(self, ...) checkBox:LockHighlight(); end);
		checkBox.textFrame:HookScript("OnLeave", function(self, ...) checkBox:UnlockHighlight(); end);
		checkBox.textFrame:Show();
		checkBox.textFrame:HookScript("OnMouseDown", function(self) checkBox:SetButtonState("PUSHED"); end);
		checkBox.textFrame:HookScript("OnMouseUp", function(self) checkBox:SetButtonState("NORMAL"); checkBox:Click(); end);
		checkBox.Text = checkBox.textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		checkBox.Text:SetPoint("LEFT", 0, 0);
		checkBox.SetText = function(self, _text)
			checkBox.Text:SetText(_text);
			checkBox.textFrame:SetWidth(checkBox.Text:GetStringWidth() + checkBox:GetWidth());
			checkBox.textFrame:SetHeight(max(checkBox.Text:GetStringHeight(), checkBox:GetHeight()));
		end;
		local handlersToBeCopied = { "OnEnter", "OnLeave" };
		hooksecurefunc(checkBox, "HookScript", function(self, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:HookScript(script, proc); end end);
		hooksecurefunc(checkBox, "SetScript",  function(self, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:SetScript(script, proc); end end);
		checkBox:SetText(text);
		checkBox:EnableMouse(true);
		checkBox:SetScript("OnClick", func);
		checkBox:Hide();
		return checkBox;
	end
	
	local function GUICreateCheckBoxTristate(textEntries)
		local checkButton = GUICreateCheckBoxEx(textEntries[1], nil);
		checkButton.state = 0;
		checkButton.SetTriState = function(self, tristate)
			self:SetText(textEntries[tristate+1]);
			self:SetChecked(tristate == 1 or tristate == 2);
			self.state = tristate;
		end;
		checkButton.GetTriState = function(self)
			return self.state;
		end;
		checkButton.SetClickHandler = function(self, _func)
			self:SetScript("OnClick", function(_self)
				local newState = _self:GetTriState() + 1;
				if (newState > 2) then newState = 0; end
				_self:SetTriState(newState);
				_func(_self);
			end);
		end;
		return checkButton;
	end
	
	local function GUICreateCheckBoxWithColorPicker(x, y, text, checkedChangedCallback)
		local checkBox = GUICreateCheckBoxEx(text, checkedChangedCallback);
		
		checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 20, 0);
		
		checkBox.ColorButton = CreateFrame("Button", nil, checkBox);
		checkBox.ColorButton:SetPoint("LEFT", 19, 0);
		checkBox.ColorButton:SetWidth(20);
		checkBox.ColorButton:SetHeight(20);
		checkBox.ColorButton:Show();

		checkBox.ColorButton:EnableMouse(true);

		checkBox.ColorButton.colorSwatch = checkBox.ColorButton:CreateTexture(nil, "OVERLAY");
		checkBox.ColorButton.colorSwatch:SetWidth(19);
		checkBox.ColorButton.colorSwatch:SetHeight(19);
		checkBox.ColorButton.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
		checkBox.ColorButton.colorSwatch:SetPoint("LEFT");
		checkBox.ColorButton.SetColor = checkBox.ColorButton.colorSwatch.SetVertexColor;

		checkBox.ColorButton.texture = checkBox.ColorButton:CreateTexture(nil, "BACKGROUND");
		checkBox.ColorButton.texture:SetWidth(16);
		checkBox.ColorButton.texture:SetHeight(16);
		checkBox.ColorButton.texture:SetTexture(1, 1, 1);
		checkBox.ColorButton.texture:SetPoint("CENTER", checkBox.ColorButton.colorSwatch);
		checkBox.ColorButton.texture:Show();

		checkBox.ColorButton.checkers = checkBox.ColorButton:CreateTexture(nil, "BACKGROUND");
		checkBox.ColorButton.checkers:SetWidth(14);
		checkBox.ColorButton.checkers:SetHeight(14);
		checkBox.ColorButton.checkers:SetTexture("Tileset\\Generic\\Checkers");
		checkBox.ColorButton.checkers:SetTexCoord(.25, 0, 0.5, .25);
		checkBox.ColorButton.checkers:SetDesaturated(true);
		checkBox.ColorButton.checkers:SetVertexColor(1, 1, 1, 0.75);
		checkBox.ColorButton.checkers:SetPoint("CENTER", checkBox.ColorButton.colorSwatch);
		checkBox.ColorButton.checkers:Show();
				
		return checkBox;
	end
		
	local function GUICreateColorPicker(parent, x, y, text)
		local colorButton = CreateFrame("Button", nil, parent);
		colorButton:SetPoint("TOPLEFT", x, y);
		colorButton:SetWidth(20);
		colorButton:SetHeight(20);
		colorButton:Hide();
		colorButton:EnableMouse(true);

		colorButton.colorSwatch = colorButton:CreateTexture(nil, "OVERLAY");
		colorButton.colorSwatch:SetWidth(19);
		colorButton.colorSwatch:SetHeight(19);
		colorButton.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
		colorButton.colorSwatch:SetPoint("LEFT");

		colorButton.texture = colorButton:CreateTexture(nil, "BACKGROUND");
		colorButton.texture:SetWidth(16);
		colorButton.texture:SetHeight(16);
		colorButton.texture:SetTexture(1, 1, 1);
		colorButton.texture:SetPoint("CENTER", colorButton.colorSwatch);
		colorButton.texture:Show();

		colorButton.checkers = colorButton:CreateTexture(nil, "BACKGROUND");
		colorButton.checkers:SetWidth(14);
		colorButton.checkers:SetHeight(14);
		colorButton.checkers:SetTexture("Tileset\\Generic\\Checkers");
		colorButton.checkers:SetTexCoord(.25, 0, 0.5, .25);
		colorButton.checkers:SetDesaturated(true);
		colorButton.checkers:SetVertexColor(1, 1, 1, 0.75);
		colorButton.checkers:SetPoint("CENTER", colorButton.colorSwatch);
		colorButton.checkers:Show();
		
		colorButton.text = colorButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		colorButton.text:SetPoint("LEFT", 22, 0);
		colorButton.text:SetText(text);
		return colorButton;
	end
	
	local function GUICreateSlider(parent, x, y, size)
		local frame = CreateFrame("Frame", nil, parent);
		frame:SetHeight(100);
		frame:SetWidth(size);
		frame:SetPoint("TOPLEFT", x, y);

		frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		frame.label:SetPoint("TOPLEFT");
		frame.label:SetPoint("TOPRIGHT");
		frame.label:SetJustifyH("CENTER");
		--frame.label:SetHeight(15);
		
		frame.slider = CreateFrame("Slider", nil, frame);
		frame.slider:SetOrientation("HORIZONTAL")
		frame.slider:SetHeight(15)
		frame.slider:SetHitRectInsets(0, 0, -10, 0)
		frame.slider:SetBackdrop({
			bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true, tileSize = 8, edgeSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }
		});
		frame.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		frame.slider:SetPoint("TOP", frame.label, "BOTTOM")
		frame.slider:SetPoint("LEFT", 3, 0)
		frame.slider:SetPoint("RIGHT", -3, 0)

		frame.lowtext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.lowtext:SetPoint("TOPLEFT", frame.slider, "BOTTOMLEFT", 2, 3)

		frame.hightext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.hightext:SetPoint("TOPRIGHT", frame.slider, "BOTTOMRIGHT", -2, 3)

		frame.editbox = CreateFrame("EditBox", nil, frame)
		frame.editbox:SetAutoFocus(false)
		frame.editbox:SetFontObject(GameFontHighlightSmall)
		frame.editbox:SetPoint("TOP", frame.slider, "BOTTOM")
		frame.editbox:SetHeight(14)
		frame.editbox:SetWidth(70)
		frame.editbox:SetJustifyH("CENTER")
		frame.editbox:EnableMouse(true)
		frame.editbox:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, edgeSize = 1, tileSize = 5,
		});
		frame.editbox:SetBackdropColor(0, 0, 0, 0.5)
		frame.editbox:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)
		frame.editbox:SetScript("OnEscapePressed", function() frame.editbox:ClearFocus(); end)
		frame:Hide();
		return frame;
	end
	
	local function GUICreateButton(parentFrame, text)
		-- After creation we need to set up :SetWidth, :SetHeight, :SetPoint, :SetScript
		local button = CreateFrame("Button", nil, parentFrame);
		button.Background = button:CreateTexture(nil, "BORDER");
		button.Background:SetPoint("TOPLEFT", 1, -1);
		button.Background:SetPoint("BOTTOMRIGHT", -1, 1);
		button.Background:SetColorTexture(0, 0, 0, 1);

		button.Border = button:CreateTexture(nil, "BACKGROUND");
		button.Border:SetPoint("TOPLEFT", 0, 0);
		button.Border:SetPoint("BOTTOMRIGHT", 0, 0);
		button.Border:SetColorTexture(unpack({0.73, 0.26, 0.21, 1}));

		button.Normal = button:CreateTexture(nil, "ARTWORK");
		button.Normal:SetPoint("TOPLEFT", 2, -2);
		button.Normal:SetPoint("BOTTOMRIGHT", -2, 2);
		button.Normal:SetColorTexture(unpack({0.38, 0, 0, 1}));
		button:SetNormalTexture(button.Normal);

		button.Disabled = button:CreateTexture(nil, "OVERLAY");
		button.Disabled:SetPoint("TOPLEFT", 3, -3);
		button.Disabled:SetPoint("BOTTOMRIGHT", -3, 3);
		button.Disabled:SetColorTexture(0.6, 0.6, 0.6, 0.2);
		button:SetDisabledTexture(button.Disabled);

		button.Highlight = button:CreateTexture(nil, "OVERLAY");
		button.Highlight:SetPoint("TOPLEFT", 3, -3);
		button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3);
		button.Highlight:SetColorTexture(0.6, 0.6, 0.6, 0.2);
		button:SetHighlightTexture(button.Highlight);

		button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		button.Text:SetPoint("CENTER", 0, 0);
		button.Text:SetJustifyH("CENTER");
		button.Text:SetTextColor(1, 0.82, 0, 1);
		button.Text:SetText(text);

		button:SetScript("OnMouseDown", function(self) self.Text:SetPoint("CENTER", 1, -1) end);
		button:SetScript("OnMouseUp", function(self) self.Text:SetPoint("CENTER", 0, 0) end);
		return button;
	end
		
	local selectorEx;
	local function GetSelectorEx()
		if (not selectorEx) then
			selectorEx = CreateFrame("Frame", nil, UIParent);
			selectorEx:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
			selectorEx:SetSize(350, 300);
			selectorEx.texture = selectorEx:CreateTexture();
			selectorEx.texture:SetAllPoints(selectorEx);
			selectorEx.texture:SetColorTexture(0, 0, 0, 1);
			
			selectorEx.searchLabel = selectorEx:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			selectorEx.searchLabel:SetPoint("TOPLEFT", 5, -10);
			selectorEx.searchLabel:SetJustifyH("LEFT");
			--selectorEx.searchLabel:SetTextColor(1, 0.82, 0, 1);
			selectorEx.searchLabel:SetText("Search:"); -- // todo: localize
			
			selectorEx.searchBox = CreateFrame("EditBox", nil, selectorEx, "InputBoxTemplate");
			selectorEx.searchBox:SetAutoFocus(false);
			selectorEx.searchBox:SetFontObject(GameFontHighlightSmall);
			selectorEx.searchBox:SetPoint("LEFT", selectorEx.searchLabel, "RIGHT", 10, 0);
			selectorEx.searchBox:SetPoint("RIGHT", selectorEx, "RIGHT", -10, 0);
			selectorEx.searchBox:SetHeight(20);
			selectorEx.searchBox:SetWidth(175);
			selectorEx.searchBox:SetJustifyH("LEFT");
			selectorEx.searchBox:EnableMouse(true);
			selectorEx.searchBox:SetScript("OnEscapePressed", function() selectorEx.searchBox:ClearFocus(); end);
			selectorEx.searchBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText();
				if (text == "") then
					selectorEx.SetList(selectorEx.list);
				else
					local t = { };
					for _, value in pairs(selectorEx.list) do
						if (string_find(value.text:lower(), text:lower())) then
							table_insert(t, value);
						end
					end
					selectorEx.SetList(t, true);
				end
			end);
			selectorEx:HookScript("OnHide", function() selectorEx.searchBox:SetText(""); end);
			
			selectorEx.scrollArea = CreateFrame("ScrollFrame", nil, selectorEx, "UIPanelScrollFrameTemplate");
			selectorEx.scrollArea:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 5, -30);
			selectorEx.scrollArea:SetPoint("BOTTOMRIGHT", selectorEx, "BOTTOMRIGHT", -25, 5);
			selectorEx.scrollArea:Show();
			
			local scrollAreaChildFrame = CreateFrame("Frame", nil, selectorEx.scrollArea);
			selectorEx.scrollArea:SetScrollChild(scrollAreaChildFrame);
			--scrollAreaChildFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 1);
			scrollAreaChildFrame:SetWidth(288);
			scrollAreaChildFrame:SetHeight(288);
			
			selectorEx.buttons = { };
			selectorEx.list = { };
			
			local function GetButton(counter)
				if (selectorEx.buttons[counter] == nil) then
					local button = GUICreateButton(scrollAreaChildFrame, "");
					button.font, button.fontSize, button.fontFlags = button.Text:GetFont();
					button:SetWidth(295);
					button:SetHeight(20);
					button:SetPoint("TOPLEFT", 23, -counter * 22 + 20);
					button.Icon = button:CreateTexture();
					button.Icon:SetPoint("RIGHT", button, "LEFT", -3, 0);
					button.Icon:SetWidth(20);
					button.Icon:SetHeight(20);
					button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
					button:Hide();
					selectorEx.buttons[counter] = button;
					return button;
				else
					return selectorEx.buttons[counter];
				end
			end
			
			selectorEx.SetList = function(t, dontUpdateInternalList)
				for _, button in pairs(selectorEx.buttons) do
					button:Hide();
					button.Icon:SetTexture();
					button.Text:SetFont(button.font, button.fontSize, button.fontFlags);
					button:SetScript("OnClick", nil);
				end
				local counter = 1;
				for _, value in pairs(t) do
					local button = GetButton(counter);
					button.Text:SetText(value.text);
					if (value.font ~= nil) then
						button.Text:SetFont(value.font, button.fontSize, button.fontFlags);
					end
					button.Icon:SetTexture(value.icon);
					button:SetScript("OnClick", function()
						value:func();
						selectorEx:Hide();
					end);
					button:Show();
					counter = counter + 1;
				end
				if (not dontUpdateInternalList) then
					selectorEx.list = t;
				end
			end
			
			selectorEx.GetButtonByText = function(text)
				for _, button in pairs(selectorEx.buttons) do
					if (button.Text:GetText() == text) then
						return button;
					end
				end
				return nil;
			end
			
			selectorEx.SetList({});
			selectorEx:Hide();
			selectorEx:HookScript("OnShow", function(self) self:SetFrameStrata("TOOLTIP"); end);
		end
		
		return selectorEx;
	end
	
	local function ShowGUICategory(index)
		for i, v in pairs(GUIFrame.Categories) do
			for k, l in pairs(v) do
				l:Hide();
			end
		end
		for i, v in pairs(GUIFrame.Categories[index]) do
			v:Show();
		end
	end
	
	local function OnGUICategoryClick(self, ...)
		GUIFrame.CategoryButtons[GUIFrame.ActiveCategory].text:SetTextColor(1, 0.82, 0);
		GUIFrame.CategoryButtons[GUIFrame.ActiveCategory]:UnlockHighlight();
		GUIFrame.ActiveCategory = self.index;
		self.text:SetTextColor(1, 1, 1);
		self:LockHighlight();
		PlaySound("igMainMenuOptionCheckBoxOn");
		ShowGUICategory(GUIFrame.ActiveCategory);
	end
	
	local function CreateGUICategory()
		local b = CreateFrame("Button", nil, GUIFrame.outline);
		b:SetWidth(GUIFrame.outline:GetWidth() - 8);
		b:SetHeight(18);
		b:SetScript("OnClick", OnGUICategoryClick);
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
		b:GetHighlightTexture():SetAlpha(0.7);
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		b.text:SetPoint("LEFT", 3, 0);
		GUIFrame.CategoryButtons[#GUIFrame.CategoryButtons + 1] = b;
		return b;
	end
	
	local function InitializeGUI_CreateSpellInfoCaches()
		GUIFrame:HookScript("OnShow", function()
			local scanAllSpells = coroutine.create(function()
				local misses = 0;
				local id = 0;
				while (misses < 400) do
					id = id + 1;
					local name, _, icon = GetSpellInfo(id);
					if (icon == 136243) then -- 136243 is the a gear icon
						misses = 0;
					elseif (name and name ~= "") then
						misses = 0;
						if (AllSpellIDsAndIconsByName[name] == nil) then AllSpellIDsAndIconsByName[name] = { }; end
						AllSpellIDsAndIconsByName[name][id] = icon;
					else
						misses = misses + 1;
					end
					coroutine.yield();
				end
			end);
			CoroutineProcessor:Queue("scanAllSpells", scanAllSpells);
		end);
		GUIFrame:HookScript("OnHide", function()
			CoroutineProcessor:DeleteFromQueue("scanAllSpells");
			wipe(AllSpellIDsAndIconsByName);
		end);
	end
	
	local function InitializeGUI()
		GUIFrame = CreateFrame("Frame", "NAuras.GUIFrame", UIParent);
		GUIFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
		GUIFrame:SetScript("OnEvent", function(self, event, ...)
			if (event == "PLAYER_REGEN_DISABLED") then
				if (self:IsVisible()) then
					self:Hide();
					self:RegisterEvent("PLAYER_REGEN_ENABLED");
				end
			elseif (event == "PLAYER_REGEN_ENABLED") then
				self:UnregisterEvent("PLAYER_REGEN_ENABLED");
				self:Show();
			end
		end);
		GUIFrame:SetHeight(400);
		GUIFrame:SetWidth(530);
		GUIFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80);
		GUIFrame:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 } 
		});
		GUIFrame:SetBackdropColor(0.25, 0.24, 0.32, 1);
		GUIFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
		GUIFrame:EnableMouse(1);
		GUIFrame:SetMovable(1);
		GUIFrame:SetFrameStrata("DIALOG");
		GUIFrame:SetToplevel(1);
		GUIFrame:SetClampedToScreen(1);
		GUIFrame:SetScript("OnMouseDown", function() GUIFrame:StartMoving(); end);
		GUIFrame:SetScript("OnMouseUp", function() GUIFrame:StopMovingOrSizing(); end);
		GUIFrame:Hide();
		
		GUIFrame.CategoryButtons = {};
		GUIFrame.ActiveCategory = 1;
		
		local header = GUIFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		header:SetFont(GameFontNormal:GetFont(), 22, "THICKOUTLINE");
		header:SetPoint("CENTER", GUIFrame, "CENTER", 0, 210);
		header:SetText("NameplateAuras");
		
		GUIFrame.outline = CreateFrame("Frame", nil, GUIFrame);
		GUIFrame.outline:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		GUIFrame.outline:SetBackdropColor(0.1, 0.1, 0.2, 1);
		GUIFrame.outline:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		GUIFrame.outline:SetPoint("TOPLEFT", 12, -12);
		GUIFrame.outline:SetPoint("BOTTOMLEFT", 12, 12);
		GUIFrame.outline:SetWidth(130);
		
		local closeButton = CreateFrame("Button", "NAuras.GUI.CloseButton", GUIFrame, "UIPanelButtonTemplate");
		closeButton:SetWidth(24);
		closeButton:SetHeight(24);
		closeButton:SetPoint("TOPRIGHT", 0, 22);
		closeButton:SetScript("OnClick", function() GUIFrame:Hide(); end);
		closeButton.text = closeButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		closeButton.text:SetPoint("CENTER", closeButton, "CENTER", 1, -1);
		closeButton.text:SetText("X");
		
		GUIFrame.Categories = {};
		GUIFrame.OnDBChangedHandlers = {};
		table_insert(GUIFrame.OnDBChangedHandlers, function() OnGUICategoryClick(GUIFrame.CategoryButtons[1]); end);
		
		local categories = { L["General"], L["Profiles"], L["Timer text"], L["Stack text"], L["Icon borders"], L["Spells"] };
		for index, value in pairs(categories) do
			local b = CreateGUICategory();
			b.index = index;
			b.text:SetText(value);
			if (index == 1) then
				b:LockHighlight();
				b.text:SetTextColor(1, 1, 1);
				b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, -6);
			elseif (index == #categories) then
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 26);
			else
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 6);
			end
			
			GUIFrame.Categories[index] = {};
			
			if (index == 1) then
				GUICategory_1(index, value);
			elseif (index == 2) then
				GUICategory_2(index, value);
			elseif (index == 3) then
				GUICategory_Fonts(index, value);
			elseif (index == 4) then
				GUICategory_AuraStackFont(index, value);
			elseif (index == 5) then
				GUICategory_Borders(index, value);
			elseif (index == 6) then
				GUICategory_4(index, value);
			else
				
			end
		end
		InitializeGUI_CreateSpellInfoCaches();
	end
	
	function ShowGUI()
		if (not InCombatLockdown()) then
			if (not GUIFrame) then
				InitializeGUI();
			end
			GUIFrame:Show();
			OnGUICategoryClick(GUIFrame.CategoryButtons[1]);
		else
			Print(L["Options are not available in combat!"]);
		end
	end
	
	function GUICategory_1(index, value)
		
		-- // sliderIconSize
		do
		
			local sliderIconSize = GUICreateSlider(GUIFrame, 160, -25, 155);
			sliderIconSize.label:SetText(L["Default icon size"]);
			sliderIconSize.slider:SetValueStep(1);
			sliderIconSize.slider:SetMinMaxValues(1, MAX_AURA_ICON_SIZE);
			sliderIconSize.slider:SetValue(db.DefaultIconSize);
			sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconSize.editbox:SetText(tostring(math_ceil(value)));
				for spellID, spellInfo in pairs(db.CustomSpells2) do
					if (spellInfo.iconSize == db.DefaultIconSize) then
						db.CustomSpells2[spellID].iconSize = math_ceil(value);
						UpdateSpellCachesFromDB(spellID);
					end
				end
				local oldSize = db.DefaultIconSize;
				db.DefaultIconSize = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(oldSize);
			end);
			sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
			sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconSize.editbox:GetText());
					if (v == nil) then
						sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
						msg(L["Value must be a number"]);
					else
						if (v > MAX_AURA_ICON_SIZE) then
							v = MAX_AURA_ICON_SIZE;
						end
						if (v < 1) then
							v = 1;
						end
						sliderIconSize.slider:SetValue(v);
					end
					sliderIconSize.editbox:ClearFocus();
				end
			end);
			sliderIconSize.lowtext:SetText("1");
			sliderIconSize.hightext:SetText(tostring(MAX_AURA_ICON_SIZE));
			table_insert(GUIFrame.Categories[index], sliderIconSize);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSize.slider:SetValue(db.DefaultIconSize); sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize)); end);
		
		end
		
		-- // sliderIconSpacing
		do
			local minValue, maxValue = 0, 50;
			local sliderIconSpacing = GUICreateSlider(GUIFrame, 345, -25, 155);
			sliderIconSpacing.label:SetText(L["Space between icons"]);
			sliderIconSpacing.slider:SetValueStep(1);
			sliderIconSpacing.slider:SetMinMaxValues(minValue, maxValue);
			sliderIconSpacing.slider:SetValue(db.IconSpacing);
			sliderIconSpacing.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconSpacing.editbox:SetText(tostring(math_ceil(value)));
				db.IconSpacing = math_ceil(value);
				UpdateAllNameplates(true);
			end);
			sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing));
			sliderIconSpacing.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconSpacing.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconSpacing.editbox:GetText());
					if (v == nil) then
						sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderIconSpacing.slider:SetValue(v);
					end
					sliderIconSpacing.editbox:ClearFocus();
				end
			end);
			sliderIconSpacing.lowtext:SetText(tostring(minValue));
			sliderIconSpacing.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderIconSpacing);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSpacing.slider:SetValue(db.IconSpacing); sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing)); end);
		
		end
		
		-- // sliderIconXOffset
		do
		
			local sliderIconXOffset = GUICreateSlider(GUIFrame, 160, -85, 155);
			sliderIconXOffset.label:SetText(L["Icon X-coord offset"]);
			sliderIconXOffset.slider:SetValueStep(1);
			sliderIconXOffset.slider:SetMinMaxValues(-200, 200);
			sliderIconXOffset.slider:SetValue(db.IconXOffset);
			sliderIconXOffset.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconXOffset.editbox:SetText(tostring(math_ceil(value)));
				db.IconXOffset = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(db.DefaultIconSize);
			end);
			sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset));
			sliderIconXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconXOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconXOffset.editbox:GetText());
					if (v == nil) then
						sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset));
						Print(L["Value must be a number"]);
					else
						if (v > 200) then
							v = 200;
						end
						if (v < -200) then
							v = -200;
						end
						sliderIconXOffset.slider:SetValue(v);
					end
					sliderIconXOffset.editbox:ClearFocus();
				end
			end);
			sliderIconXOffset.lowtext:SetText("-200");
			sliderIconXOffset.hightext:SetText("200");
			table_insert(GUIFrame.Categories[index], sliderIconXOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconXOffset.slider:SetValue(db.IconXOffset); sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset)); end);
		
		end
	
		-- // sliderIconYOffset
		do
		
			local sliderIconYOffset = GUICreateSlider(GUIFrame, 345, -85, 155);
			sliderIconYOffset.label:SetText(L["Icon Y-coord offset"]);
			sliderIconYOffset.slider:SetValueStep(1);
			sliderIconYOffset.slider:SetMinMaxValues(-200, 200);
			sliderIconYOffset.slider:SetValue(db.IconYOffset);
			sliderIconYOffset.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconYOffset.editbox:SetText(tostring(math_ceil(value)));
				db.IconYOffset = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(db.DefaultIconSize);
			end);
			sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset));
			sliderIconYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconYOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconYOffset.editbox:GetText());
					if (v == nil) then
						sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset));
						Print(L["Value must be a number"]);
					else
						if (v > 200) then
							v = 200;
						end
						if (v < -200) then
							v = -200;
						end
						sliderIconYOffset.slider:SetValue(v);
					end
					sliderIconYOffset.editbox:ClearFocus();
				end
			end);
			sliderIconYOffset.lowtext:SetText("-200");
			sliderIconYOffset.hightext:SetText("200");
			table_insert(GUIFrame.Categories[index], sliderIconYOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconYOffset.slider:SetValue(db.IconYOffset); sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset)); end);
		
		end
		
		
		local checkBoxFullOpacityAlways = GUICreateCheckBoxEx(L["Always display icons at full opacity (ReloadUI is required)"], function(this)
			db.FullOpacityAlways = this:GetChecked();
			PopupReloadUI();
		end);
		checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways);
		checkBoxFullOpacityAlways:SetParent(GUIFrame);
		checkBoxFullOpacityAlways:SetPoint("TOPLEFT", 160, -140);
		table_insert(GUIFrame.Categories[index], checkBoxFullOpacityAlways);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			if (checkBoxFullOpacityAlways:GetChecked() ~= db.FullOpacityAlways) then
				PopupReloadUI();
			end
			checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways);
		end);
		
		local checkBoxHideBlizzardFrames = GUICreateCheckBoxEx(L["Hide Blizzard's aura frames (Reload UI is required)"], function(this)
			db.HideBlizzardFrames = this:GetChecked();
			PopupReloadUI();
		end);
		checkBoxHideBlizzardFrames:SetChecked(db.HideBlizzardFrames);
		checkBoxHideBlizzardFrames:SetParent(GUIFrame);
		checkBoxHideBlizzardFrames:SetPoint("TOPLEFT", 160, -160);
		table_insert(GUIFrame.Categories[index], checkBoxHideBlizzardFrames);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			if (checkBoxHideBlizzardFrames:GetChecked() ~= db.HideBlizzardFrames) then
				PopupReloadUI();
			end
			checkBoxHideBlizzardFrames:SetChecked(db.HideBlizzardFrames);
		end);
		
		-- // checkBoxShowAurasOnPlayerNameplate
		do
		
			local checkBoxShowAurasOnPlayerNameplate = GUICreateCheckBoxEx(L["Display auras on player's nameplate"], function(this)
				db.ShowAurasOnPlayerNameplate = this:GetChecked();
			end);
			checkBoxShowAurasOnPlayerNameplate:SetChecked(db.ShowAurasOnPlayerNameplate);
			checkBoxShowAurasOnPlayerNameplate:SetParent(GUIFrame);
			checkBoxShowAurasOnPlayerNameplate:SetPoint("TOPLEFT", 160, -180);
			table_insert(GUIFrame.Categories[index], checkBoxShowAurasOnPlayerNameplate);
			table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowAurasOnPlayerNameplate:SetChecked(db.ShowAurasOnPlayerNameplate); end);
		
		end
		
		-- // checkBoxShowAboveFriendlyUnits
		do
		
			local checkBoxShowAboveFriendlyUnits = GUICreateCheckBoxEx(L["Display auras on nameplates of friendly units"], function(this)
				db.ShowAboveFriendlyUnits = this:GetChecked();
				UpdateAllNameplates(true);
			end);
			checkBoxShowAboveFriendlyUnits:SetChecked(db.ShowAboveFriendlyUnits);
			checkBoxShowAboveFriendlyUnits:SetParent(GUIFrame);
			checkBoxShowAboveFriendlyUnits:SetPoint("TOPLEFT", 160, -200);
			table_insert(GUIFrame.Categories[index], checkBoxShowAboveFriendlyUnits);
			table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowAboveFriendlyUnits:SetChecked(db.ShowAboveFriendlyUnits); end);
		
		end
		
		-- // checkBoxShowMyAuras
		do
		
			local checkBoxShowMyAuras = GUICreateCheckBoxEx(L["Always show auras cast by myself"], function(this)
				db.AlwaysShowMyAuras = this:GetChecked();
				UpdateAllNameplates(false);
			end);
			checkBoxShowMyAuras:SetChecked(db.AlwaysShowMyAuras);
			checkBoxShowMyAuras:SetParent(GUIFrame);
			checkBoxShowMyAuras:SetPoint("TOPLEFT", 160, -220);
			SetTooltip(checkBoxShowMyAuras, L["options:general:always-show-my-auras:tooltip"]);
			table_insert(GUIFrame.Categories[index], checkBoxShowMyAuras);
			table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowMyAuras:SetChecked(db.AlwaysShowMyAuras); end);
		
		end
			
		-- // dropdownTimerStyle
		do
			
			local TimerStylesLocalization = {
				[TIMER_STYLE_TEXTURETEXT] =		L["Texture with timer"],
				[TIMER_STYLE_CIRCULAR] =		L["Circular"],
				[TIMER_STYLE_CIRCULAROMNICC] =	L["Circular with OmniCC support"],
				[TIMER_STYLE_CIRCULARTEXT] =	L["Circular with timer"],
			};
		
			local dropdownTimerStyle = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownTimerStyle", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownTimerStyle, 300);
			dropdownTimerStyle:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -275);
			local info = {};
			dropdownTimerStyle.initialize = function()
				wipe(info);
				for _, timerStyle in pairs({ TIMER_STYLE_TEXTURETEXT, TIMER_STYLE_CIRCULAR, TIMER_STYLE_CIRCULAROMNICC, TIMER_STYLE_CIRCULARTEXT }) do
					info.text = TimerStylesLocalization[timerStyle];
					info.value = timerStyle;
					info.func = function(self)
						if (self.value == TIMER_STYLE_CIRCULAROMNICC and not IsAddOnLoaded("omnicc")) then
							msg("You cannot select this option, OmniCC is not loaded!"); -- // todo:localize
						else
							db.TimerStyle = self.value;
							_G[dropdownTimerStyle:GetName().."Text"]:SetText(self:GetText());
							PopupReloadUI();
						end
					end
					info.checked = (db.TimerStyle == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownTimerStyle:GetName().."Text"]:SetText(TimerStylesLocalization[db.TimerStyle]);
			dropdownTimerStyle.text = dropdownTimerStyle:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownTimerStyle.text:SetPoint("LEFT", 20, 15);
			dropdownTimerStyle.text:SetText(L["Timer style:"]);
			table_insert(GUIFrame.Categories[index], dropdownTimerStyle);
			table_insert(GUIFrame.OnDBChangedHandlers, function()
				if (_G[dropdownTimerStyle:GetName().."Text"]:GetText() ~= TimerStylesLocalization[db.TimerStyle]) then
					PopupReloadUI();
				end
				_G[dropdownTimerStyle:GetName().."Text"]:SetText(TimerStylesLocalization[db.TimerStyle]);
			end);
			
		end
		
		-- // dropdownIconAnchor
		do
			
			local anchors = { "TOPLEFT", "LEFT", "BOTTOMLEFT" };
			local anchorsLocalization = { [anchors[1]] = L["TOPLEFT"], [anchors[2]] = L["LEFT"], [anchors[3]] = L["BOTTOMLEFT"] };
			local dropdownIconAnchor = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownIconAnchor", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownIconAnchor, 130);
			dropdownIconAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -310);
			local info = {};
			dropdownIconAnchor.initialize = function()
				wipe(info);
				for _, anchor in pairs(anchors) do
					info.text = anchorsLocalization[anchor];
					info.value = anchor;
					info.func = function(self)
						db.IconAnchor = self.value;
						_G[dropdownIconAnchor:GetName().."Text"]:SetText(self:GetText());
						Nameplates_OnIconAnchorChanged();
					end
					info.checked = (db.IconAnchor == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownIconAnchor:GetName().."Text"]:SetText(L[db.IconAnchor]);
			dropdownIconAnchor.text = dropdownIconAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownIconAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownIconAnchor.text:SetText(L["Icon anchor:"]);
			table_insert(GUIFrame.Categories[index], dropdownIconAnchor);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconAnchor:GetName().."Text"]:SetText(L[db.IconAnchor]); end);
		
		end
		
		-- // dropdownFrameAnchor
		do
			
			local anchors = { "CENTER", "LEFT", "RIGHT" };
			local anchorsLocalization = { [anchors[1]] = L["CENTER"], [anchors[2]] = L["LEFT"], [anchors[3]] = L["RIGHT"] };
			local dropdownFrameAnchor = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownFrameAnchor", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownFrameAnchor, 130);
			dropdownFrameAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 316, -310);
			local info = {};
			dropdownFrameAnchor.initialize = function()
				wipe(info);
				for _, anchor in pairs(anchors) do
					info.text = anchorsLocalization[anchor];
					info.value = anchor;
					info.func = function(self)
						db.FrameAnchor = self.value;
						_G[dropdownFrameAnchor:GetName().."Text"]:SetText(self:GetText());
						Nameplates_OnFrameAnchorChanged();
					end
					info.checked = (db.FrameAnchor == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownFrameAnchor:GetName().."Text"]:SetText(L[db.FrameAnchor]);
			dropdownFrameAnchor.text = dropdownFrameAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownFrameAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownFrameAnchor.text:SetText(L["Frame anchor:"]);
			table_insert(GUIFrame.Categories[index], dropdownFrameAnchor);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFrameAnchor:GetName().."Text"]:SetText(L[db.FrameAnchor]); end);
		
		end
		
		-- // dropdownSortMode
		do
			local SortModesLocalization = { 
				[AURA_SORT_MODE_NONE] =				L["None"],
				[AURA_SORT_MODE_EXPIREASC] =		L["By expire time, ascending"],
				[AURA_SORT_MODE_EXPIREDES] =		L["By expire time, descending"],
				[AURA_SORT_MODE_ICONSIZEASC] =		L["By icon size, ascending"],
				[AURA_SORT_MODE_ICONSIZEDES] =		L["By icon size, descending"],
				[AURA_SORT_MODE_AURATYPE_EXPIRE] =	L["By aura type (de/buff) + expire time"]
			};
		
		
			local dropdownSortMode = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownSortMode", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSortMode, 300);
			dropdownSortMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -345);
			local info = {};
			dropdownSortMode.initialize = function()
				wipe(info);
				for _, sortMode in pairs({ AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIREASC, AURA_SORT_MODE_EXPIREDES, AURA_SORT_MODE_ICONSIZEASC, AURA_SORT_MODE_ICONSIZEDES, AURA_SORT_MODE_AURATYPE_EXPIRE }) do
					info.text = SortModesLocalization[sortMode];
					info.value = sortMode;
					info.func = function(self)
						db.SortMode = self.value;
						_G[dropdownSortMode:GetName().."Text"]:SetText(self:GetText());
						Nameplates_OnSortModeChanged();
					end
					info.checked = (db.SortMode == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownSortMode:GetName().."Text"]:SetText(SortModesLocalization[db.SortMode]);
			dropdownSortMode.text = dropdownSortMode:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownSortMode.text:SetPoint("LEFT", 20, 15);
			dropdownSortMode.text:SetText(L["Sort mode:"]);
			table_insert(GUIFrame.Categories[index], dropdownSortMode);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownSortMode:GetName().."Text"]:SetText(SortModesLocalization[db.SortMode]); end);
			
		end
		
	end
	
	function GUICategory_2(index, value)
		local button = GUICreateButton(GUIFrame, L["Open profiles dialog"]);
		button:SetWidth(170);
		button:SetHeight(40);
		button:SetPoint("CENTER", GUIFrame, "CENTER", 70, 0);
		button:SetScript("OnClick", function(self, ...)
			InterfaceOptionsFrame_OpenToCategory(ProfileOptionsFrame);
			GUIFrame:Hide();
		end);
		table_insert(GUIFrame.Categories[index], button);
	end
	
	function GUICategory_Fonts(index, value)
		
		local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
		local textAnchorsLocalization = {
			[textAnchors[1]] = L["TOPRIGHT"],
			[textAnchors[2]] = L["RIGHT"],
			[textAnchors[3]] = L["BOTTOMRIGHT"],
			[textAnchors[4]] = L["TOP"],
			[textAnchors[5]] = L["CENTER"],
			[textAnchors[6]] = L["BOTTOM"],
			[textAnchors[7]] = L["TOPLEFT"],
			[textAnchors[8]] = L["LEFT"],
			[textAnchors[9]] = L["BOTTOMLEFT"]
		};
		local sliderTimerFontScale, sliderTimerFontSize, timerTextColorArea, tenthsOfSecondsArea;
		
		-- // dropdownFont
		do
		
			local fonts = { };
			local button = GUICreateButton(GUIFrame, L["Font"] .. ": " .. db.Font);
			
			for idx, font in next, SML:List("font") do
				table_insert(fonts, {
					["text"] = font,
					["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
					["func"] = function(info)
						button.Text:SetText(L["Font"] .. ": " .. info.text);
						db.Font = info.text;
						Nameplates_OnFontChanged();
					end,
					["font"] = SML:Fetch("font", font),
				});
			end
			table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);
			
			button:SetWidth(170);
			button:SetHeight(24);
			button:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -28);
			button:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -28);
			button:SetScript("OnClick", function(self, ...)
				local fontSelector = GetSelectorEx();
				if (fontSelector:IsVisible()) then
					fontSelector:Hide();
				else
					fontSelector.SetList(fonts);
					fontSelector:SetParent(self);
					fontSelector:ClearAllPoints();
					fontSelector:SetPoint("TOP", self, "BOTTOM", 0, 0);
					fontSelector:Show();
				end
			end);
			table_insert(GUIFrame.Categories[index], button);
			
		end
		
		-- // sliderTimerFontScale
		do
			
			local minValue, maxValue = 0.3, 3;
			sliderTimerFontScale = GUICreateSlider(GUIFrame, 300, -68, 200);
			sliderTimerFontScale.label:SetText(L["Font scale"]);
			sliderTimerFontScale.slider:SetValueStep(0.1);
			sliderTimerFontScale.slider:SetMinMaxValues(minValue, maxValue);
			sliderTimerFontScale.slider:SetValue(db.FontScale);
			sliderTimerFontScale.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.1f", value));
				sliderTimerFontScale.editbox:SetText(tostring(actualValue));
				db.FontScale = actualValue;
				Nameplates_OnFontChanged();
			end);
			sliderTimerFontScale.editbox:SetText(tostring(db.FontScale));
			sliderTimerFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderTimerFontScale.editbox:GetText() ~= "") then
					local v = tonumber(sliderTimerFontScale.editbox:GetText());
					if (v == nil) then
						sliderTimerFontScale.editbox:SetText(tostring(db.FontScale));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderTimerFontScale.slider:SetValue(v);
					end
					sliderTimerFontScale.editbox:ClearFocus();
				end
			end);
			sliderTimerFontScale.lowtext:SetText(tostring(minValue));
			sliderTimerFontScale.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontScale.editbox:SetText(tostring(db.FontScale)); sliderTimerFontScale.slider:SetValue(db.FontScale); end);
		
		end
		
		-- // sliderTimerFontSize
		do
			
			local minValue, maxValue = 6, 96;
			sliderTimerFontSize = GUICreateSlider(GUIFrame, 300, -68, 200);
			sliderTimerFontSize.label:SetText(L["Font size"]);
			sliderTimerFontSize.slider:SetValueStep(1);
			sliderTimerFontSize.slider:SetMinMaxValues(minValue, maxValue);
			sliderTimerFontSize.slider:SetValue(db.TimerTextSize);
			sliderTimerFontSize.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderTimerFontSize.editbox:SetText(tostring(actualValue));
				db.TimerTextSize = actualValue;
				Nameplates_OnFontChanged();
			end);
			sliderTimerFontSize.editbox:SetText(tostring(db.TimerTextSize));
			sliderTimerFontSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderTimerFontSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderTimerFontSize.editbox:GetText());
					if (v == nil) then
						sliderTimerFontSize.editbox:SetText(tostring(db.TimerTextSize));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderTimerFontSize.slider:SetValue(v);
					end
					sliderTimerFontSize.editbox:ClearFocus();
				end
			end);
			sliderTimerFontSize.lowtext:SetText(tostring(minValue));
			sliderTimerFontSize.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontSize.editbox:SetText(tostring(db.TimerTextSize)); sliderTimerFontSize.slider:SetValue(db.TimerTextSize); end);
		
		end
		
		-- // checkBoxUseRelativeFontSize
		do
		
			local checkBoxUseRelativeFontSize = GUICreateCheckBoxEx(L["options:timer-text:scale-font-size"], function(this)
				db.TimerTextUseRelativeScale = this:GetChecked();
				if (db.TimerTextUseRelativeScale) then
					sliderTimerFontScale:Show();
					sliderTimerFontSize:Hide();
				else
					sliderTimerFontScale:Hide();
					sliderTimerFontSize:Show();
				end
			end);
			checkBoxUseRelativeFontSize:SetChecked(db.TimerTextUseRelativeScale);
			checkBoxUseRelativeFontSize:SetParent(GUIFrame);
			checkBoxUseRelativeFontSize:SetPoint("TOPLEFT", 160, -80);
			table_insert(GUIFrame.Categories[index], checkBoxUseRelativeFontSize);
			table_insert(GUIFrame.OnDBChangedHandlers, function()
				checkBoxUseRelativeFontSize:SetChecked(db.TimerTextUseRelativeScale);
			end);
			checkBoxUseRelativeFontSize:SetScript("OnShow", function(self)
				if (db.TimerTextUseRelativeScale) then
					sliderTimerFontScale:Show();
					sliderTimerFontSize:Hide();
				else
					sliderTimerFontScale:Hide();
					sliderTimerFontSize:Show();
				end
			end);
			checkBoxUseRelativeFontSize:SetScript("OnHide", function(self)
				sliderTimerFontScale:Hide();
				sliderTimerFontSize:Hide();
			end);
		
		end
		
		-- // dropdownTimerTextAnchor
		do
			
			local dropdownTimerTextAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchor", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownTimerTextAnchor, 145);
			dropdownTimerTextAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -125);
			local info = {};
			dropdownTimerTextAnchor.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = textAnchorsLocalization[anchorPoint];
					info.value = anchorPoint;
					info.func = function(self)
						db.TimerTextAnchor = self.value;
						_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.TimerTextAnchor;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(L[db.TimerTextAnchor]);
			dropdownTimerTextAnchor.text = dropdownTimerTextAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownTimerTextAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownTimerTextAnchor.text:SetText(L["Anchor point"]);
			table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchor);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(L[db.TimerTextAnchor]); end);
		
		end
		
		-- // dropdownTimerTextAnchorIcon
		do
			
			local dropdownTimerTextAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchorIcon", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownTimerTextAnchorIcon, 145);
			dropdownTimerTextAnchorIcon:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 315, -125);
			local info = {};
			dropdownTimerTextAnchorIcon.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = textAnchorsLocalization[anchorPoint];
					info.value = anchorPoint;
					info.func = function(self)
						db.TimerTextAnchorIcon = self.value;
						_G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.TimerTextAnchorIcon;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(L[db.TimerTextAnchorIcon]);
			dropdownTimerTextAnchorIcon.text = dropdownTimerTextAnchorIcon:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownTimerTextAnchorIcon.text:SetPoint("LEFT", 20, 15);
			dropdownTimerTextAnchorIcon.text:SetText(L["Anchor to icon"]);
			table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchorIcon);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(L[db.TimerTextAnchorIcon]); end);
		
		end
				
		-- // sliderTimerTextXOffset
		do
			
			local minValue, maxValue = -100, 100;
			local sliderTimerTextXOffset = GUICreateSlider(GUIFrame, 160, -170, 165);
			sliderTimerTextXOffset.label:SetText(L["X offset"]);
			sliderTimerTextXOffset.slider:SetValueStep(1);
			sliderTimerTextXOffset.slider:SetMinMaxValues(minValue, maxValue);
			sliderTimerTextXOffset.slider:SetValue(db.TimerTextXOffset);
			sliderTimerTextXOffset.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderTimerTextXOffset.editbox:SetText(tostring(actualValue));
				db.TimerTextXOffset = actualValue;
				Nameplates_OnTextPositionChanged();
			end);
			sliderTimerTextXOffset.editbox:SetText(tostring(db.TimerTextXOffset));
			sliderTimerTextXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderTimerTextXOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderTimerTextXOffset.editbox:GetText());
					if (v == nil) then
						sliderTimerTextXOffset.editbox:SetText(tostring(db.TimerTextXOffset));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderTimerTextXOffset.slider:SetValue(v);
					end
					sliderTimerTextXOffset.editbox:ClearFocus();
				end
			end);
			sliderTimerTextXOffset.lowtext:SetText(tostring(minValue));
			sliderTimerTextXOffset.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderTimerTextXOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextXOffset.editbox:SetText(tostring(db.TimerTextXOffset)); sliderTimerTextXOffset.slider:SetValue(db.TimerTextXOffset); end);
		
		end
		
		-- // sliderTimerTextYOffset
		do
			
			local minValue, maxValue = -100, 100;
			local sliderTimerTextYOffset = GUICreateSlider(GUIFrame, 335, -170, 165);
			sliderTimerTextYOffset.label:SetText(L["Y offset"]);
			sliderTimerTextYOffset.slider:SetValueStep(1);
			sliderTimerTextYOffset.slider:SetMinMaxValues(minValue, maxValue);
			sliderTimerTextYOffset.slider:SetValue(db.TimerTextYOffset);
			sliderTimerTextYOffset.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderTimerTextYOffset.editbox:SetText(tostring(actualValue));
				db.TimerTextYOffset = actualValue;
				Nameplates_OnTextPositionChanged();
			end);
			sliderTimerTextYOffset.editbox:SetText(tostring(db.TimerTextYOffset));
			sliderTimerTextYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderTimerTextYOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderTimerTextYOffset.editbox:GetText());
					if (v == nil) then
						sliderTimerTextYOffset.editbox:SetText(tostring(db.TimerTextYOffset));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderTimerTextYOffset.slider:SetValue(v);
					end
					sliderTimerTextYOffset.editbox:ClearFocus();
				end
			end);
			sliderTimerTextYOffset.lowtext:SetText(tostring(minValue));
			sliderTimerTextYOffset.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderTimerTextYOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextYOffset.editbox:SetText(tostring(db.TimerTextYOffset)); sliderTimerTextYOffset.slider:SetValue(db.TimerTextYOffset); end);
		
		end
		
		-- // timerTextColorArea
		do
		
			timerTextColorArea = CreateFrame("Frame", nil, GUIFrame);
			timerTextColorArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			timerTextColorArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			timerTextColorArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			timerTextColorArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -210);
			timerTextColorArea:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMRIGHT", 10, 95);
			timerTextColorArea:SetWidth(360);
			table_insert(GUIFrame.Categories[index], timerTextColorArea);
		
		end
		
		-- // timerTextColorInfo
		do
			
			local timerTextColorInfo = timerTextColorArea:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			timerTextColorInfo:SetText(L["options:timer-text:text-color-note"]);
			timerTextColorInfo:SetPoint("TOP", 0, -10);
			
		end
		
		-- // colorPickerTimerTextFiveSeconds
		do
		
			local colorPickerTimerTextFiveSeconds = GUICreateColorPicker(timerTextColorArea, 10, -40, L["< 5sec"]);
			colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor));
			colorPickerTimerTextFiveSeconds:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextSoonToExpireColor = {r, g, b};
					colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextSoonToExpireColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextSoonToExpireColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerTimerTextFiveSeconds);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor)); end);
			
		end
		
		-- // colorPickerTimerTextMinute
		do
		
			local colorPickerTimerTextMinute = GUICreateColorPicker(timerTextColorArea, 135, -40, L["< 1min"]);
			colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor));
			colorPickerTimerTextMinute:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextUnderMinuteColor = {r, g, b};
					colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextUnderMinuteColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextUnderMinuteColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerTimerTextMinute);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor)); end);
		
		end
		
		-- // colorPickerTimerTextMore
		do
		
			local colorPickerTimerTextMore = GUICreateColorPicker(timerTextColorArea, 260, -40, L["> 1min"]);
			colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor));
			colorPickerTimerTextMore:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextLongerColor = {r, g, b};
					colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextLongerColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextLongerColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerTimerTextMore);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor)); end);
		
		end

		-- // tenthsOfSecondsArea
		do
		
			tenthsOfSecondsArea = CreateFrame("Frame", nil, GUIFrame);
			tenthsOfSecondsArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			tenthsOfSecondsArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			tenthsOfSecondsArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			tenthsOfSecondsArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -285);
			tenthsOfSecondsArea:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMRIGHT", 10, 20);
			tenthsOfSecondsArea:SetWidth(360);
			table_insert(GUIFrame.Categories[index], tenthsOfSecondsArea);
			
		end
		
		-- // sliderDisplayTenthsOfSeconds
		do
			
			local minValue, maxValue = 0, 10;
			local sliderDisplayTenthsOfSeconds = GUICreateSlider(tenthsOfSecondsArea, 10, -10, 340);
			sliderDisplayTenthsOfSeconds.label:SetText(L["options:timer-text:min-duration-to-display-tenths-of-seconds"]);
			sliderDisplayTenthsOfSeconds.slider:SetValueStep(0.1);
			sliderDisplayTenthsOfSeconds.slider:SetMinMaxValues(minValue, maxValue);
			sliderDisplayTenthsOfSeconds.slider:SetValue(db.MinTimeToShowTenthsOfSeconds);
			sliderDisplayTenthsOfSeconds.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.1f", value));
				sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(actualValue));
				db.MinTimeToShowTenthsOfSeconds = actualValue;
			end);
			sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(db.MinTimeToShowTenthsOfSeconds));
			sliderDisplayTenthsOfSeconds.editbox:SetScript("OnEnterPressed", function(self, value)
				if (self:GetText() ~= "") then
					local v = tonumber(self:GetText());
					if (v == nil) then
						self:SetText(tostring(db.MinTimeToShowTenthsOfSeconds));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderDisplayTenthsOfSeconds.slider:SetValue(v);
					end
					self:ClearFocus();
				else
					self:SetText(tostring(db.MinTimeToShowTenthsOfSeconds));
					msg(L["Value must be a number"]);
				end
			end);
			sliderDisplayTenthsOfSeconds.lowtext:SetText(tostring(minValue));
			sliderDisplayTenthsOfSeconds.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderDisplayTenthsOfSeconds);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(db.MinTimeToShowTenthsOfSeconds)); sliderDisplayTenthsOfSeconds.slider:SetValue(db.MinTimeToShowTenthsOfSeconds); end);
		
		end
		
	end
	
	function GUICategory_AuraStackFont(index, value)
		
		local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
		local textAnchorsLocalization = {
			[textAnchors[1]] = L["TOPRIGHT"],
			[textAnchors[2]] = L["RIGHT"],
			[textAnchors[3]] = L["BOTTOMRIGHT"],
			[textAnchors[4]] = L["TOP"],
			[textAnchors[5]] = L["CENTER"],
			[textAnchors[6]] = L["BOTTOM"],
			[textAnchors[7]] = L["TOPLEFT"],
			[textAnchors[8]] = L["LEFT"],
			[textAnchors[9]] = L["BOTTOMLEFT"]
		};
		
		-- // dropdownStacksFont
		do
		
			local fonts = { };
			local button = GUICreateButton(GUIFrame, L["Font"] .. ": " .. db.StacksFont);
			
			for idx, font in next, SML:List("font") do
				table_insert(fonts, {
					["text"] = font,
					["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
					["func"] = function(info)
						button.Text:SetText(L["Font"] .. ": " .. info.text);
						db.StacksFont = info.text;
						Nameplates_OnFontChanged();
					end,
					["font"] = SML:Fetch("font", font),
				});
			end
			table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);
			
			button:SetWidth(170);
			button:SetHeight(24);
			button:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -28);
			button:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -28);
			button:SetScript("OnClick", function(self, ...)
				local fontSelector = GetSelectorEx();
				if (fontSelector:IsVisible()) then
					fontSelector:Hide();
				else
					fontSelector.SetList(fonts);
					fontSelector:SetParent(self);
					fontSelector:ClearAllPoints();
					fontSelector:SetPoint("TOP", self, "BOTTOM", 0, 0);
					fontSelector:Show();
				end
			end);
			table_insert(GUIFrame.Categories[index], button);
			
		end
				
		-- // sliderStacksFontScale
		do
			
			local minValue, maxValue = 0.3, 3;
			local sliderStacksFontScale = GUICreateSlider(GUIFrame, 160, -68, 340);
			sliderStacksFontScale.label:SetText(L["Font scale"]);
			sliderStacksFontScale.slider:SetValueStep(0.1);
			sliderStacksFontScale.slider:SetMinMaxValues(minValue, maxValue);
			sliderStacksFontScale.slider:SetValue(db.StacksFontScale);
			sliderStacksFontScale.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.1f", value));
				sliderStacksFontScale.editbox:SetText(tostring(actualValue));
				db.StacksFontScale = actualValue;
				Nameplates_OnFontChanged();
			end);
			sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale));
			sliderStacksFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderStacksFontScale.editbox:GetText() ~= "") then
					local v = tonumber(sliderStacksFontScale.editbox:GetText());
					if (v == nil) then
						sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderStacksFontScale.slider:SetValue(v);
					end
					sliderStacksFontScale.editbox:ClearFocus();
				end
			end);
			sliderStacksFontScale.lowtext:SetText(tostring(minValue));
			sliderStacksFontScale.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderStacksFontScale);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale)); sliderStacksFontScale.slider:SetValue(db.StacksFontScale); end);
		
		end
		
		-- // dropdownStacksAnchor
		do
			
			local dropdownStacksAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchor", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownStacksAnchor, 145);
			dropdownStacksAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -125);
			local info = {};
			dropdownStacksAnchor.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = textAnchorsLocalization[anchorPoint];
					info.value = anchorPoint;
					info.func = function(self)
						db.StacksTextAnchor = self.value;
						_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.StacksTextAnchor;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(L[db.StacksTextAnchor]);
			dropdownStacksAnchor.text = dropdownStacksAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownStacksAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownStacksAnchor.text:SetText(L["Anchor point"]);
			table_insert(GUIFrame.Categories[index], dropdownStacksAnchor);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(L[db.StacksTextAnchor]); end);
		
		end
		
		-- // dropdownStacksAnchorIcon
		do
			
			local dropdownStacksAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchorIcon", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownStacksAnchorIcon, 145);
			dropdownStacksAnchorIcon:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 315, -125);
			local info = {};
			dropdownStacksAnchorIcon.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = textAnchorsLocalization[anchorPoint];
					info.value = anchorPoint;
					info.func = function(self)
						db.StacksTextAnchorIcon = self.value;
						_G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.StacksTextAnchorIcon;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(L[db.StacksTextAnchorIcon]);
			dropdownStacksAnchorIcon.text = dropdownStacksAnchorIcon:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			dropdownStacksAnchorIcon.text:SetPoint("LEFT", 20, 15);
			dropdownStacksAnchorIcon.text:SetText(L["Anchor to icon"]);
			table_insert(GUIFrame.Categories[index], dropdownStacksAnchorIcon);
			table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(L[db.StacksTextAnchorIcon]); end);
		
		end
		
		-- // sliderStacksTextXOffset
		do
			
			local minValue, maxValue = -100, 100;
			local sliderStacksTextXOffset = GUICreateSlider(GUIFrame, 160, -170, 165);
			sliderStacksTextXOffset.label:SetText(L["X offset"]);
			sliderStacksTextXOffset.slider:SetValueStep(1);
			sliderStacksTextXOffset.slider:SetMinMaxValues(minValue, maxValue);
			sliderStacksTextXOffset.slider:SetValue(db.StacksTextXOffset);
			sliderStacksTextXOffset.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderStacksTextXOffset.editbox:SetText(tostring(actualValue));
				db.StacksTextXOffset = actualValue;
				Nameplates_OnTextPositionChanged();
			end);
			sliderStacksTextXOffset.editbox:SetText(tostring(db.StacksTextXOffset));
			sliderStacksTextXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderStacksTextXOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderStacksTextXOffset.editbox:GetText());
					if (v == nil) then
						sliderStacksTextXOffset.editbox:SetText(tostring(db.StacksTextXOffset));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderStacksTextXOffset.slider:SetValue(v);
					end
					sliderStacksTextXOffset.editbox:ClearFocus();
				end
			end);
			sliderStacksTextXOffset.lowtext:SetText(tostring(minValue));
			sliderStacksTextXOffset.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderStacksTextXOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextXOffset.editbox:SetText(tostring(db.StacksTextXOffset)); sliderStacksTextXOffset.slider:SetValue(db.StacksTextXOffset); end);
		
		end
		
		-- // sliderStacksTextYOffset
		do
			
			local minValue, maxValue = -100, 100;
			local sliderStacksTextYOffset = GUICreateSlider(GUIFrame, 335, -170, 165);
			sliderStacksTextYOffset.label:SetText(L["Y offset"]);
			sliderStacksTextYOffset.slider:SetValueStep(1);
			sliderStacksTextYOffset.slider:SetMinMaxValues(minValue, maxValue);
			sliderStacksTextYOffset.slider:SetValue(db.StacksTextYOffset);
			sliderStacksTextYOffset.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderStacksTextYOffset.editbox:SetText(tostring(actualValue));
				db.StacksTextYOffset = actualValue;
				Nameplates_OnTextPositionChanged();
			end);
			sliderStacksTextYOffset.editbox:SetText(tostring(db.StacksTextYOffset));
			sliderStacksTextYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderStacksTextYOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderStacksTextYOffset.editbox:GetText());
					if (v == nil) then
						sliderStacksTextYOffset.editbox:SetText(tostring(db.StacksTextYOffset));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderStacksTextYOffset.slider:SetValue(v);
					end
					sliderStacksTextYOffset.editbox:ClearFocus();
				end
			end);
			sliderStacksTextYOffset.lowtext:SetText(tostring(minValue));
			sliderStacksTextYOffset.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderStacksTextYOffset);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextYOffset.editbox:SetText(tostring(db.StacksTextYOffset)); sliderStacksTextYOffset.slider:SetValue(db.StacksTextYOffset); end);
		
		end
		
		-- // colorPickerStacksTextColor
		do
		
			local colorPickerStacksTextColor = GUICreateColorPicker(GUIFrame, 165, -240, L["Text color"]);
			colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor));
			colorPickerStacksTextColor:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.StacksTextColor = {r, g, b};
					colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor));
					for nameplate in pairs(Nameplates) do
						if (nameplate.NAurasFrame) then
							for _, icon in pairs(nameplate.NAurasIcons) do
								icon.stacks:SetTextColor(unpack(db.StacksTextColor));
							end
						end
					end
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.StacksTextColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.StacksTextColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerStacksTextColor);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor)); end);
		
		end
		
	end
	
	function GUICategory_Borders(index, value)
		
		local debuffArea;
		
		-- // sliderBorderThickness
		do
		
			local minValue, maxValue = 1, 5;
			local sliderBorderThickness = GUICreateSlider(GUIFrame, 160, -30, 325);
			sliderBorderThickness.label:SetText(L["Border thickness"]);
			sliderBorderThickness.slider:SetValueStep(1);
			sliderBorderThickness.slider:SetMinMaxValues(minValue, maxValue);
			sliderBorderThickness.slider:SetValue(db.BorderThickness);
			sliderBorderThickness.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.0f", value));
				sliderBorderThickness.editbox:SetText(tostring(actualValue));
				db.BorderThickness = actualValue;
				Nameplates_OnBorderThicknessChanged();
			end);
			sliderBorderThickness.editbox:SetText(tostring(db.BorderThickness));
			sliderBorderThickness.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderBorderThickness.editbox:GetText() ~= "") then
					local v = tonumber(sliderBorderThickness.editbox:GetText());
					if (v == nil) then
						sliderBorderThickness.editbox:SetText(tostring(db.BorderThickness));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderBorderThickness.slider:SetValue(v);
					end
					sliderBorderThickness.editbox:ClearFocus();
				end
			end);
			sliderBorderThickness.lowtext:SetText(tostring(minValue));
			sliderBorderThickness.hightext:SetText(tostring(maxValue));
			table_insert(GUIFrame.Categories[index], sliderBorderThickness);
			table_insert(GUIFrame.OnDBChangedHandlers, function() sliderBorderThickness.editbox:SetText(tostring(db.BorderThickness)); sliderBorderThickness.slider:SetValue(db.BorderThickness); end);
			
		end
		
		-- // checkBoxBuffBorder
		do
		
			local checkBoxBuffBorder = GUICreateCheckBoxWithColorPicker(160, -90, L["Show border around buff icons"], function(this)
				db.ShowBuffBorders = this:GetChecked();
				UpdateAllNameplates();
			end);
			checkBoxBuffBorder:SetChecked(db.ShowBuffBorders);
			checkBoxBuffBorder:SetParent(GUIFrame);
			checkBoxBuffBorder:SetPoint("TOPLEFT", 160, -90);
			checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor));
			checkBoxBuffBorder.ColorButton:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.BuffBordersColor = {r, g, b};
					checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor));
					UpdateAllNameplates(true);
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.BuffBordersColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.BuffBordersColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], checkBoxBuffBorder);
			table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxBuffBorder:SetChecked(db.ShowBuffBorders); checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor)); end);
			
		end
		
		-- // debuffArea
		do
		
			debuffArea = CreateFrame("Frame", nil, GUIFrame);
			debuffArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			debuffArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			debuffArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			debuffArea:SetPoint("TOPLEFT", 150, -120);
			debuffArea:SetPoint("LEFT", 150, 25);
			debuffArea:SetWidth(360);
			table_insert(GUIFrame.Categories[index], debuffArea);
		
		end
		
		-- // checkBoxDebuffBorder
		do
		
			local checkBoxDebuffBorder = GUICreateCheckBoxEx(L["Show border around debuff icons"], function(this)
				db.ShowDebuffBorders = this:GetChecked();
				UpdateAllNameplates();
			end);
			checkBoxDebuffBorder:SetParent(debuffArea);
			checkBoxDebuffBorder:SetPoint("TOPLEFT", 15, -15);
			checkBoxDebuffBorder:SetChecked(db.ShowDebuffBorders);
			table_insert(GUIFrame.Categories[index], checkBoxDebuffBorder);
			table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxDebuffBorder:SetChecked(db.ShowDebuffBorders); end);
			
		end
		
		-- // colorPickerDebuffMagic
		do
		
			local colorPickerDebuffMagic = GUICreateColorPicker(debuffArea, 15, -45, L["Magic"]);
			colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor));
			colorPickerDebuffMagic:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersMagicColor = {r, g, b};
					colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersMagicColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersMagicColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerDebuffMagic);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor)); end);
		
		end
		
		-- // colorPickerDebuffCurse
		do
		
			local colorPickerDebuffCurse = GUICreateColorPicker(debuffArea, 135, -45, L["Curse"]);
			colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor));
			colorPickerDebuffCurse:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersCurseColor = {r, g, b};
					colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersCurseColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersCurseColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerDebuffCurse);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor)); end);
		
		end
		
		-- // colorPickerDebuffDisease
		do
		
			local colorPickerDebuffDisease = GUICreateColorPicker(debuffArea, 255, -45, L["Disease"]);
			colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor));
			colorPickerDebuffDisease:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersDiseaseColor = {r, g, b};
					colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersDiseaseColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersDiseaseColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerDebuffDisease);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor)); end);
		
		end
		
		-- // colorPickerDebuffPoison
		do
		
			local colorPickerDebuffPoison = GUICreateColorPicker(debuffArea, 15, -70, L["Poison"]);
			colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor));
			colorPickerDebuffPoison:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersPoisonColor = {r, g, b};
					colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersPoisonColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersPoisonColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerDebuffPoison);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor)); end);
		
		end
		
		-- // colorPickerDebuffOther
		do
		
			local colorPickerDebuffOther = GUICreateColorPicker(debuffArea, 135, -70, L["Other"]);
			colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor));
			colorPickerDebuffOther:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersOtherColor = {r, g, b};
					colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersOtherColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersOtherColor) };
				ColorPickerFrame:Show();
			end);
			table_insert(GUIFrame.Categories[index], colorPickerDebuffOther);
			table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor)); end);
		
		end
		
	end
	
	function GUICategory_4(index, value)
		local controls = { };
		local selectedSpell = 0;
		local spellArea, editboxAddSpell, buttonAddSpell, dropdownSelectSpell, sliderSpellIconSize, dropdownSpellShowType, editboxSpellID, buttonDeleteSpell, checkboxShowOnFriends,
			checkboxShowOnEnemies, checkboxAllowMultipleInstances, selectSpell, checkboxPvPMode, checkboxEnabled, checkboxGlow;
		local AuraTypesLocalization = {
			[AURA_TYPE_BUFF] =		L["Buff"],
			[AURA_TYPE_DEBUFF] =	L["Debuff"],
			[AURA_TYPE_ANY] =		L["Any"],
		};
		
		-- // spellArea
		do
		
			spellArea = CreateFrame("Frame", nil, GUIFrame);
			spellArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			spellArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			spellArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			spellArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -85);
			spellArea:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMRIGHT", 10, 0);
			spellArea:SetWidth(360);
			table_insert(controls, spellArea);
		
		end
		
		-- // editboxAddSpell, buttonAddSpell
		do
		
			editboxAddSpell = CreateFrame("EditBox", nil, GUIFrame, "InputBoxTemplate");
			editboxAddSpell:SetAutoFocus(false);
			editboxAddSpell:SetFontObject(GameFontHighlightSmall);
			editboxAddSpell:SetPoint("TOPLEFT", GUIFrame, 172, -30);
			editboxAddSpell:SetHeight(20);
			editboxAddSpell:SetWidth(175);
			editboxAddSpell:SetJustifyH("LEFT");
			editboxAddSpell:EnableMouse(true);
			editboxAddSpell:SetScript("OnEscapePressed", function() editboxAddSpell:ClearFocus(); end);
			editboxAddSpell:SetScript("OnEnterPressed", function() buttonAddSpell:Click(); end);
			local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 0, 15);
			text:SetText(L["Add new spell: "]);
			hooksecurefunc("ChatEdit_InsertLink", function(link)
                if (editboxAddSpell:IsVisible() and editboxAddSpell:HasFocus() and link ~= nil) then
					local spellName = string.match(link, "%[\"?(.-)\"?%]");
					if (spellName ~= nil) then
						editboxAddSpell:SetText(spellName);
						editboxAddSpell:ClearFocus();
						return true;
					end
                end
			end);
			table_insert(GUIFrame.Categories[index], editboxAddSpell);
			
			buttonAddSpell = GUICreateButton(GUIFrame, L["Add spell"]);
			buttonAddSpell:SetWidth(110);
			buttonAddSpell:SetHeight(20);
			buttonAddSpell:SetPoint("LEFT", editboxAddSpell, "RIGHT", 10, 0);
			buttonAddSpell:SetScript("OnClick", function(self, ...)
				local text = editboxAddSpell:GetText();
				if (tonumber(text) ~= nil) then
					msg(format(L["options:auras:add-new-spell:error1"], L["Check spell ID"]));
				else
					local spellID;
					if (AllSpellIDsAndIconsByName[text]) then
						spellID = next(AllSpellIDsAndIconsByName[text]);
					else
						for _spellName, _spellInfo in pairs(AllSpellIDsAndIconsByName) do
							if (string_lower(_spellName) == string_lower(text)) then
								spellID = next(_spellInfo);
							end
						end
					end
					if (spellID ~= nil) then
						local spellName = SpellNameByID[spellID];
						if (spellName == nil) then
							Print(format(L["Unknown spell: %s"], text));
						else
							local alreadyExist = false;
							for spellIDCustom in pairs(db.CustomSpells2) do
								local spellNameCustom = SpellNameByID[spellIDCustom];
								if (spellNameCustom == spellName) then
									alreadyExist = true;
								end
							end
							if (not alreadyExist) then
								db.CustomSpells2[spellID] = GetDefaultDBSpellEntry(CONST_SPELL_MODE_ALL, spellID, db.DefaultIconSize, nil);
								UpdateSpellCachesFromDB(spellID);
								selectSpell:Click();
								local btn = GetSelectorEx().GetButtonByText(spellName);
								if (btn ~= nil) then btn:Click(); end
								UpdateAllNameplates(false);
							else
								msg(format(L["Spell already exists (%s)"], spellName));
							end
						end
						editboxAddSpell:SetText("");
						editboxAddSpell:ClearFocus();
					else
						msg(L["Spell seems to be nonexistent"]);
					end
				end
			end);
			table_insert(GUIFrame.Categories[index], buttonAddSpell);
			
		end
	
		-- // buttonDeleteAllSpells
		do
		
			local buttonDeleteAllSpells = GUICreateButton(GUIFrame, "X");
			buttonDeleteAllSpells:SetWidth(24);
			buttonDeleteAllSpells:SetHeight(24);
			buttonDeleteAllSpells:SetPoint("LEFT", buttonAddSpell, "RIGHT", 5, 0);
			buttonDeleteAllSpells:SetScript("OnClick", function(self, ...)
				if (not StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"]) then
					StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"] = {
						text = L["Do you really want to delete ALL spells?"],
						button1 = L["Yes"],
						button2 = L["No"],
						OnAccept = function()
							for spellID in pairs(db.CustomSpells2) do
								db.CustomSpells2[spellID] = nil;
							end
							ReloadDB();
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					};
				end
				StaticPopup_Show("NAURAS_MSG_DELETE_ALL_SPELLS");
			end);
			buttonDeleteAllSpells:SetScript("OnEnter", function(self, ...)
				GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
				GameTooltip:SetText(L["Delete all spells"]);
				GameTooltip:Show();
			end)
			buttonDeleteAllSpells:SetScript("OnLeave", function(self, ...)
				GameTooltip:Hide();
			end)
			table_insert(GUIFrame.Categories[index], buttonDeleteAllSpells);
		
		end
	
		-- // selectSpell
		do
		
			selectSpell = GUICreateButton(GUIFrame, L["Click to select spell"]);
			selectSpell:SetWidth(285);
			selectSpell:SetHeight(24);
			selectSpell:SetPoint("BOTTOMLEFT", spellArea, "TOPLEFT", 15, 5);
			selectSpell:SetPoint("BOTTOMRIGHT", spellArea, "TOPRIGHT", -15, 5);
			selectSpell:SetScript("OnClick", function(button)
				local t = { };
				for _, spellInfo in pairs(db.CustomSpells2) do
					table_insert(t, {
						icon = SpellTextureByID[spellInfo.spellID],
						text = SpellNameByID[spellInfo.spellID],
						info = spellInfo,
						tooltipSpellID = spellInfo.spellID,
						func = function(self)
							for _, control in pairs(controls) do
								control:Show();
							end
							selectedSpell = self.info.spellID;
							selectSpell.Text:SetText(self.text);
							sliderSpellIconSize.slider:SetValue(db.CustomSpells2[selectedSpell].iconSize);
							sliderSpellIconSize.editbox:SetText(tostring(db.CustomSpells2[selectedSpell].iconSize));
							_G[dropdownSpellShowType:GetName().."Text"]:SetText(AuraTypesLocalization[db.CustomSpells2[selectedSpell].auraType]);
							editboxSpellID:SetText(db.CustomSpells2[selectedSpell].checkSpellID or "");
							checkboxShowOnFriends:SetChecked(db.CustomSpells2[selectedSpell].showOnFriends);
							checkboxShowOnEnemies:SetChecked(db.CustomSpells2[selectedSpell].showOnEnemies);
							checkboxAllowMultipleInstances:SetChecked(db.CustomSpells2[selectedSpell].allowMultipleInstances);
							if (db.CustomSpells2[selectedSpell].enabledState == CONST_SPELL_MODE_DISABLED) then
								checkboxEnabled:SetTriState(0);
							elseif (db.CustomSpells2[selectedSpell].enabledState == CONST_SPELL_MODE_ALL) then
								checkboxEnabled:SetTriState(2);
							else
								checkboxEnabled:SetTriState(1);
							end
							if (db.CustomSpells2[selectedSpell].pvpCombat == CONST_SPELL_PVP_MODES_UNDEFINED) then
								checkboxPvPMode:SetTriState(0);
							elseif (db.CustomSpells2[selectedSpell].pvpCombat == CONST_SPELL_PVP_MODES_INPVPCOMBAT) then
								checkboxPvPMode:SetTriState(1);
							else
								checkboxPvPMode:SetTriState(2);
							end
							checkboxGlow:SetChecked(db.CustomSpells2[selectedSpell].showGlow);
						end,
					});
				end
				table_sort(t, function(item1, item2) return SpellNameByID[item1.info.spellID] < SpellNameByID[item2.info.spellID] end);
				local fontSelector = GetSelectorEx();
				fontSelector.SetList(t);
				fontSelector:SetParent(button);
				fontSelector:ClearAllPoints();
				fontSelector:SetPoint("TOP", button, "BOTTOM", 0, 0);
				fontSelector:Show();
				fontSelector.searchBox:SetFocus();
				fontSelector.searchBox:SetText("");
				for _, control in pairs(controls) do
					control:Hide();
				end
				selectSpell.Text:SetText(L["Click to select spell"]);
			end);
			selectSpell:SetScript("OnHide", function(self)
				for _, control in pairs(controls) do
					control:Hide();
				end
				selectSpell.Text:SetText(L["Click to select spell"]);
				GetSelectorEx():Hide();
			end);
			table_insert(GUIFrame.Categories[index], selectSpell);
			
		end
				
		-- // dropdownSpellShowType
		do
		
			dropdownSpellShowType = CreateFrame("Frame", "NAuras.GUI.Cat4.DropdownSpellShowType", spellArea, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSpellShowType, 180);
			dropdownSpellShowType.text = dropdownSpellShowType:CreateFontString(nil, "ARTWORK", "GameFontNormal");
			dropdownSpellShowType.text:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 18, -150);
			dropdownSpellShowType.text:SetText(L["Aura type"]);
			dropdownSpellShowType:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 118, -140);
			local info = {};
			dropdownSpellShowType.initialize = function()
				wipe(info);
				for _, auraType in pairs({ AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY }) do
					info.text = AuraTypesLocalization[auraType];
					info.value = auraType;
					info.func = function(self)
						db.CustomSpells2[selectedSpell].auraType = self.value;
						UpdateSpellCachesFromDB(selectedSpell);
						_G[dropdownSpellShowType:GetName().."Text"]:SetText(self:GetText());
					end
					info.checked = (info.value == db.CustomSpells2[selectedSpell].auraType);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownSpellShowType:GetName().."Text"]:SetText("");
			table_insert(controls, dropdownSpellShowType);
		
		end
		
		-- // sliderSpellIconSize
		do
		
			sliderSpellIconSize = GUICreateSlider(spellArea, 18, -23, 200);
			sliderSpellIconSize.label:ClearAllPoints();
			sliderSpellIconSize.label:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 18, -190);
			sliderSpellIconSize.label:SetText(L["Icon size"]);
			sliderSpellIconSize:ClearAllPoints();
			sliderSpellIconSize:SetPoint("LEFT", sliderSpellIconSize.label, "RIGHT", 20, 0);
			sliderSpellIconSize.slider:ClearAllPoints();
			sliderSpellIconSize.slider:SetPoint("LEFT", 3, 0)
			sliderSpellIconSize.slider:SetPoint("RIGHT", -3, 0)
			sliderSpellIconSize.slider:SetValueStep(1);
			sliderSpellIconSize.slider:SetMinMaxValues(1, MAX_AURA_ICON_SIZE);
			sliderSpellIconSize.slider:SetScript("OnValueChanged", function(self, value)
				sliderSpellIconSize.editbox:SetText(tostring(math_ceil(value)));
				db.CustomSpells2[selectedSpell].iconSize = math_ceil(value);
				UpdateSpellCachesFromDB(selectedSpell);
				for nameplate in pairs(NameplatesVisible) do
					UpdateNameplate(nameplate);
				end
			end);
			sliderSpellIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderSpellIconSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderSpellIconSize.editbox:GetText());
					if (v == nil) then
						sliderSpellIconSize.editbox:SetText(tostring(db.CustomSpells2[selectedSpell].iconSize));
						Print(L["Value must be a number"]);
					else
						if (v > MAX_AURA_ICON_SIZE) then
							v = MAX_AURA_ICON_SIZE;
						end
						if (v < 1) then
							v = 1;
						end
						sliderSpellIconSize.slider:SetValue(v);
					end
					sliderSpellIconSize.editbox:ClearFocus();
				end
			end);
			sliderSpellIconSize.lowtext:SetText("1");
			sliderSpellIconSize.hightext:SetText(tostring(MAX_AURA_ICON_SIZE));
			table_insert(controls, sliderSpellIconSize);
			
		end
		
		-- // editboxSpellID
		do
		
			editboxSpellID = CreateFrame("EditBox", nil, spellArea);
			editboxSpellID:SetAutoFocus(false);
			editboxSpellID:SetFontObject(GameFontHighlightSmall);
			editboxSpellID.text = editboxSpellID:CreateFontString(nil, "ARTWORK", "GameFontNormal");
			editboxSpellID.text:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 18, -230);
			editboxSpellID.text:SetText(L["Check spell ID"] .. ": ");
			editboxSpellID:SetPoint("LEFT", editboxSpellID.text, "RIGHT", 5, 0);
			editboxSpellID:SetPoint("RIGHT", spellArea, "RIGHT", -30, 0);
			editboxSpellID:SetHeight(20);
			editboxSpellID:SetWidth(215);
			editboxSpellID:SetJustifyH("LEFT");
			editboxSpellID:EnableMouse(true);
			editboxSpellID:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxSpellID:SetBackdropColor(0, 0, 0, 0.5);
			editboxSpellID:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxSpellID:SetScript("OnEscapePressed", function() editboxSpellID:ClearFocus(); end);
			editboxSpellID:SetScript("OnEnterPressed", function(self, value)
				local text = self:GetText();
				local textAsNumber = tonumber(text);
				db.CustomSpells2[selectedSpell].checkSpellID = textAsNumber;
				UpdateSpellCachesFromDB(selectedSpell);
				if (textAsNumber == nil) then
					self:SetText("");
				end
				self:ClearFocus();
			end);
			table_insert(controls, editboxSpellID);
		
		end
		
		-- // buttonDeleteSpell
		do
		
			buttonDeleteSpell = GUICreateButton(spellArea, L["Delete spell"]);
			buttonDeleteSpell:SetWidth(90);
			buttonDeleteSpell:SetHeight(20);
			buttonDeleteSpell:SetPoint("BOTTOMLEFT", spellArea, "BOTTOMLEFT", 20, 10);
			buttonDeleteSpell:SetPoint("BOTTOMRIGHT", spellArea, "BOTTOMRIGHT", -20, 10);
			buttonDeleteSpell:SetScript("OnClick", function(self, ...)
				db.CustomSpells2[selectedSpell] = nil;
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
				selectSpell.Text:SetText(L["Click to select spell"]);
				for _, control in pairs(controls) do
					control:Hide();
				end
			end);
			table_insert(controls, buttonDeleteSpell);
		
		end
			
		-- // checkboxEnabled
		do
			checkboxEnabled = GUICreateCheckBoxTristate({
				ColorizeText(L["Disabled"], 1, 1, 1),
				ColorizeText(L["options:auras:enabled-state-mineonly"], 0, 1, 1),
				ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0),
			});
			checkboxEnabled:SetClickHandler(function(self)
				if (self:GetTriState() == 0) then
					db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_DISABLED;
				elseif (self:GetTriState() == 1) then
					db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_MYAURAS;
				else
					db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_ALL;
				end
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxEnabled:SetParent(spellArea);
			checkboxEnabled:SetPoint("TOPLEFT", 15, -15);
			SetTooltip(checkboxEnabled, format(L["options:auras:enabled-state:tooltip"],
				ColorizeText(L["Disabled"], 1, 1, 1),
				ColorizeText(L["options:auras:enabled-state-mineonly"], 0, 1, 1),
				ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0)));
			table_insert(controls, checkboxEnabled);
			
		end
		
		-- // checkboxShowOnFriends
		do
			checkboxShowOnFriends = GUICreateCheckBoxEx(L["Show this aura on nameplates of allies"], function(this)
				db.CustomSpells2[selectedSpell].showOnFriends = this:GetChecked();
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxShowOnFriends:SetParent(spellArea);
			checkboxShowOnFriends:SetPoint("TOPLEFT", 15, -35);
			table_insert(controls, checkboxShowOnFriends);
		end
		
		-- // checkboxShowOnEnemies
		do
			checkboxShowOnEnemies = GUICreateCheckBoxEx(L["Show this aura on nameplates of enemies"], function(this)
				db.CustomSpells2[selectedSpell].showOnEnemies = this:GetChecked();
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxShowOnEnemies:SetParent(spellArea);
			checkboxShowOnEnemies:SetPoint("TOPLEFT", 15, -55);
			table_insert(controls, checkboxShowOnEnemies);
		end
		
		-- // checkboxAllowMultipleInstances
		do
			checkboxAllowMultipleInstances = GUICreateCheckBoxEx(L["options:aura-options:allow-multiple-instances"], function(this)
				db.CustomSpells2[selectedSpell].allowMultipleInstances = this:GetChecked();
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxAllowMultipleInstances:SetParent(spellArea);
			checkboxAllowMultipleInstances:SetPoint("TOPLEFT", 15, -75);
			SetTooltip(checkboxAllowMultipleInstances, L["options:aura-options:allow-multiple-instances:tooltip"]);
			table_insert(controls, checkboxAllowMultipleInstances);
		end
		
		-- // checkboxPvPMode
		do
			checkboxPvPMode = GUICreateCheckBoxTristate({
				L["options:auras:pvp-state-indefinite"],
				ColorizeText(L["options:auras:pvp-state-onlyduringpvpbattles"], 0, 1, 0),
				ColorizeText(L["options:auras:pvp-state-dontshowinpvp"], 1, 0, 0),
			});
			checkboxPvPMode:SetClickHandler(function(self)
				if (self:GetTriState() == 0) then
					db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_UNDEFINED;
				elseif (self:GetTriState() == 1) then
					db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_INPVPCOMBAT;
				else
					db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT;
				end
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxPvPMode:SetParent(spellArea);
			checkboxPvPMode:SetPoint("TOPLEFT", 15, -95);
			table_insert(controls, checkboxPvPMode);
			
		end
		
		-- // checkboxGlow
		do
			
			checkboxGlow = GUICreateCheckBoxEx("Icon glow", function(this) -- // todo:localize
				db.CustomSpells2[selectedSpell].showGlow = this:GetChecked() or nil; -- // making db smaller
				UpdateSpellCachesFromDB(selectedSpell);
				UpdateAllNameplates(false);
			end);
			checkboxGlow:SetParent(spellArea);
			checkboxGlow:SetPoint("TOPLEFT", 15, -115);
			table_insert(controls, checkboxGlow);
		
		end
		
	end
	
end

--------------------------------------------------------------------------------------------------
----- Useful stuff
--------------------------------------------------------------------------------------------------
do

	function Print(...)
		local text = "";
		for i = 1, select("#", ...) do
			text = text..tostring(select(i, ...)).." "
		end
		DEFAULT_CHAT_FRAME:AddMessage(format("NameplateAuras: %s", text), 0, 128, 128);
	end

	function deepcopy(object)
		local lookup_table = {}
		local function _copy(object)
			if type(object) ~= "table" then
				return object
			elseif lookup_table[object] then
				return lookup_table[object]
			end
			local new_table = {}
			lookup_table[object] = new_table
			for index, value in pairs(object) do
				new_table[_copy(index)] = _copy(value)
			end
			return setmetatable(new_table, getmetatable(object))
		end
		return _copy(object)
	end
	
	function msg(text)
		if (StaticPopupDialogs["NAURAS_MSG"] == nil) then
			StaticPopupDialogs["NAURAS_MSG"] = {
				text = "NAURAS_MSG",
				button1 = OKAY,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopupDialogs["NAURAS_MSG"].text = text;
		StaticPopup_Show("NAURAS_MSG");
	end
	
	function msgWithQuestion(text, funcOnAccept, funcOnCancel)
		local frameName = "NAURAS_MSG_QUESTION";
		if (StaticPopupDialogs[frameName] == nil) then
			StaticPopupDialogs[frameName] = {
				button1 = "Yes",
				button2 = "No",
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopupDialogs[frameName].text = text;
		StaticPopupDialogs[frameName].OnAccept = funcOnAccept;
		StaticPopupDialogs[frameName].OnCancel = funcOnCancel;
		StaticPopup_Show(frameName);
	end
	
	function table_contains_value(t, v)
		for _, value in pairs(t) do
			if (value == v) then
				return true;
			end
		end
		return false;
	end
	
	function table_count(t)
		local count = 0;
		for i in pairs(t) do
			count = count + 1;
		end
		return count;
	end
	
	function ColorizeText(text, r, g, b)
		return string_format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text);
	end
	
	-- // CoroutineProcessor
	do
		CoroutineProcessor = {};
		CoroutineProcessor.frame = CreateFrame("frame");
		CoroutineProcessor.update = {};
		CoroutineProcessor.size = 0;

		function CoroutineProcessor.Queue(self, name, func)
			if (not name) then
				name = string_format("NIL%d", CoroutineProcessor.size + 1);
			end
			if (not CoroutineProcessor.update[name]) then
				CoroutineProcessor.update[name] = func;
				CoroutineProcessor.size = CoroutineProcessor.size + 1;
				CoroutineProcessor.frame:Show();
			end
		end

		function CoroutineProcessor.DeleteFromQueue(self, name)
			if (CoroutineProcessor.update[name]) then
				CoroutineProcessor.update[name] = nil;
				CoroutineProcessor.size = CoroutineProcessor.size - 1;
				if (CoroutineProcessor.size == 0) then
					CoroutineProcessor.frame:Hide();
				end
			end
		end

		CoroutineProcessor.frame:Hide();
		CoroutineProcessor.frame:SetScript("OnUpdate", function(self, elapsed)
			local start = debugprofilestop();
			local hasData = true;
			while (debugprofilestop() - start < 16 and hasData) do
				hasData = false;
				for name, func in pairs(CoroutineProcessor.update) do
					hasData = true;
					if (coroutine.status(func) ~= "dead") then
						local err, ret1, ret2 = assert(coroutine.resume(func));
					else
						CoroutineProcessor:DeleteFromQueue(name);
					end
				end
			end
		end);
	end
	
end

--------------------------------------------------------------------------------------------------
----- Frame for events
--------------------------------------------------------------------------------------------------
do
	
	EventFrame = CreateFrame("Frame");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	EventFrame:RegisterEvent("CHAT_MSG_ADDON");
	EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);
	
	function EventFrame.PLAYER_ENTERING_WORLD()
		if (OnStartup) then
			OnStartup();
		end
		for nameplate in pairs(AurasPerNameplate) do
			wipe(AurasPerNameplate[nameplate]);
		end
	end

	function EventFrame.NAME_PLATE_UNIT_ADDED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = true;
		if (not Nameplates[nameplate]) then
			nameplate.NAurasIcons = {};
			nameplate.NAurasIconsCount = 0;
			Nameplates[nameplate] = true;
			AurasPerNameplate[nameplate] = {};
		end
		ProcessAurasForNameplate(nameplate, unitID);
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Show();
		end
	end
	
	function EventFrame.NAME_PLATE_UNIT_REMOVED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (AurasPerNameplate[nameplate] ~= nil) then
			wipe(AurasPerNameplate[nameplate]);
		end
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Hide();
		end
	end
	
	function EventFrame.UNIT_AURA(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		if (nameplate ~= nil and AurasPerNameplate[nameplate] ~= nil) then
			ProcessAurasForNameplate(nameplate, unitID);
			if (db.FullOpacityAlways and nameplate.NAurasFrame) then
				nameplate.NAurasFrame:Show();
			end
		end
	end
	
	function EventFrame.CHAT_MSG_ADDON(prefix, message, channel, sender)
		if (prefix == "NAuras_prefix") then
			if (string_find(message, "reporting")) then
				local _, toWhom = strsplit(":", message, 2);
				local myName = UnitName("player").."-"..string_gsub(GetRealmName(), " ", "");
				if (toWhom == myName) then
					Print(sender.." is using NAuras");
				end
			elseif (string_find(message, "requesting")) then
				SendAddonMessage("NAuras_prefix", "reporting:"..sender, channel);
			end
		end
	end
	
	local function UpdatePvPState()
		local inPvPCombat = IsUsableSpell(SpellNameByID[195710]); -- // Honorable Medallion
		if (inPvPCombat ~= InPvPCombat) then
			InPvPCombat = inPvPCombat;
			UpdateAllNameplates(false);
		end
		CTimerAfter(1, UpdatePvPState);
	end
	CTimerAfter(1, UpdatePvPState);
	
end

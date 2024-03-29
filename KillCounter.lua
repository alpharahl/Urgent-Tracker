--zo_callLater(functionName, milisecondDelay)
local counter = 0
local deathCounter = 0
local streak = 0
local rankPointsGained = 0

local deathStreak = 0
local t = 0
local dd = 0
local hideMain = false
local overrideHideMain = false


local streak_array = {}
local deathStreak_array = {}
local kb_streak_array = {}

local previousKill = ""
local previousKB = ""
local previousKBTime = 0
local KBTimer = 60

local pushed = 0

local version = 118

local tagged = {}
local taggedTime = {}
local tagDuration = 60

local justKilled = {}
local justKilledTime = {}
local killedDuration = 90


local showingStats = false


local showOOC = false
local doSounds = true

local curXP = 0

local guild = 1
local guildies = {}




--settings stuff
local showingSettings = false
local settings_window = nil
local settings_table = nil



local defaults = {
			totalKills = 0,
			rankPointsGained = 0,
			totalDeaths = 0,
			totalKillingBlows = 0,
			killed = {},
			killedBy = {},
			longestStreak = 0,
			longestDeathStreak = 0,
			offsetX = 0,
			offsetY = 0,
			anchorPoint = TOPRIGHT,
			settings = {},
			["UDP"] = {udp = 0,
				avengeKills = 0,
				empkills = 0,
				udresourceclaim = 0,
				scrollpickup = 0,
				scrollcap = 0
			},
			["SC"] = {
				keepsCaptured = 0,
				resourcesCaptured = 0,
				longestKeepStreak = 0,
				longestResourceStreak = 0

			}
		}



--KC_Fn.table_shallow_copy(t)
local defaultPlayerArray = {
		Name = "",
		Kills = 0,
		KillingBlows = 0,
		Class = "",
		Alliance = 0,
		Avenge_Kills = 0,
		Revent_Kills = 0,
		--Other Stats for possible future use
		isVampire = false,
		Level = 0,
		Damage_Done = 0,
		Healing_Kills = 0--dunno if this is possible

}

local defaultKilledByArray = {
	Name = "",
	KilledBy = 0,
	Class = "",
	Alliance = 0,
	Level = 10,
	vLevel = 0
}

local defaultSettingsArray = {
	Sounds = true,
	ChatKills = true,
	ChatSeiges = true,
	ChatCaptures = true,
	ChatDeaths = true,
	ChatKStreak = true,
	ChatDStreak = true,
	ChatCapStreak = true
}

-- local defaultUDPArray = {
-- 	UrgentDawnAvenges = 0,
-- 	EmpororKills = 0,
-- 	UrgentDawnResourceClaim = 0,
-- 	ElderScrollPickup = 0,
-- 	ElderScrollDrop = 0,
-- 	UDP = 0,
-- }

local temp_targets = {}
local target_default = {
	Name = "",
	Class = "",
	Alliance = ""
}


--Kill Counter Global

KC_G = {}

KC_G.savedVars = {}

KC_G.svDefaults = defaults

local Ckdr = 0

local kbCounter = 0 --killing blows
local kbStreak = 0
local lastKBTime = 0


function KC_G.GetCounter() return counter end
function KC_G.GetDeathCounter() return deathCounter end
function KC_G.GetStreak() return streak end
function KC_G.GetDStreak() return deathStreak end
function KC_G.GetRankPoints() return rankPointsGained end
function KC_G.GetKBStreak() return kbStreak end
function KC_G.GetKillingBlows() return kbCounter end
 
--function KC_AddOnUpdate()
function KC_G.AddOnUpdate()
	if KC_G.savedVars ~= nil then dd = KC_G.savedVars.totalDeaths or 0 end
	if KC_G.savedVars ~= nil then t = KC_G.savedVars.totalKills or 0 end
	
	if KC_G.savedVars ~= nil then
		local arg1, arg2, arg3, arg4, xoff, yoff = KillCounter:GetAnchor()
		--d(KillCounter:GetAnchor())
		KC_G.savedVars.offsetX = xoff
		KC_G.savedVars.offsetY = yoff
		KC_G.savedVars.anchorPoint = arg2
	end
	Ckdr = counter
	if deathCounter > 0 then Ckdr = counter/deathCounter end
    KillCounter_Kills:SetText(string.format("K:(%d) D:(%d) KDR:(%.1f) Streak(%d) KB(%d) KBS(%d)", counter, deathCounter,KC_Fn.round(Ckdr, 2), streak, kbCounter, kbStreak))
    --KillCounter_Deaths:SetText(string.format("Deaths: %d (%d)", deathCounter, dd))
    --KillCounter_Streak:SetText(string.format("Streak: %d", streak))
    --KillCounter_Death_Streak:SetText(string.format("Death Streak: %d", deathStreak))

    KC_G.UpdateGui()


    local t = 0
    --check zone. if in wrong zone hide
    if not IsPlayerInAvAWorld() then
    	if not hideMain and not overrideHideMain then
	    	KC_G.hide()
	    end
	else
		if not overrideHideMain then
			KC_G.show()
		end
    end


    --check tagged times

    for i=1,#taggedTime do
    	t = GetFrameTimeSeconds()
    	if IsUnitInCombat('player') and taggedTime[i] ~= nil then

    		taggedTime[i] = t 
    	end
    	if taggedTime[i] == nil or t - taggedTime[i] > tagDuration then

    		--d("removing " .. tagged[i] .. " from tagged list")
    		table.remove(taggedTime,i)
    		table.remove(tagged,i)
    	end
    end

    t = GetFrameTimeSeconds()
    if t - previousKBTime > KBTimer then 
    	previousKBTime = 0
    	previousKB = ""
    end

    for i=1,#justKilledTime do
    	t = GetFrameTimeSeconds()
    	if IsUnitInCombat('player') and justKilledTime[i] ~= nil then

    		justKilledTime[i] = t 
    	end
    	if justKilledTime[i] == nil or t - justKilledTime[i] > killedDuration then
    		--d("removing " .. tagged[i] .. " from tagged list")
    		table.remove(justKilledTime,i)
    		table.remove(justKilled,i)
    	end
    end

end



--function KC_OnKill
function KC_G.OnKill( eventCode , result , isError , abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log )
	--d( "[" ..result .. "]," .. "[" ..abilityName .. "]," .. "[" ..sourceName .. "]," .. "[" ..sourceType .. "]," .. "[" ..targetName .. "]," .. "[" ..targetType .. "]," .. "[" ..hitValue .. "]," .. "[" ..abilityActionSlotType .. "]," .. "[" ..powerType .. "]," .. "[" ..damageType .. "]" )
	--d(sourceName)
	--d("Unit Name: " .. (GetUnitName("player") .. "^Fx"))
	if sourceName == "" then return end
	--if GetUnitName('player') == zo_strformat("<<1>>", sourceName) and zo_strformat("<<1>>", targetName) ~= GetUnitName('player') and targetType == COMBAT_UNIT_TYPE_OTHER then
		--if log then d("log true") end
		--d(targetName .. " from " .. sourceName .. " result: " .. result .. " abilityName " .. abilityName  .. " sourceType " .. sourceType .. " target Type " .. targetType)
	--end
	--if (result == ACTION_RESULT_KILLING_BLOW)  then d("Killing Blow Nigga on " .. targetName) end
	if (result == ACTION_RESULT_KILLING_BLOW) and
		sourceType == COMBAT_UNIT_TYPE_PLAYER and 
		(GetUnitName("player") == zo_strformat("<<1>>", sourceName) or KC_Fn.table_count(tagged, zo_strformat("<<1>>", targetName)) > 0) and 
			zo_strformat("<<1>>", targetName) ~= previousKill and zo_strformat("<<1>>", targetName) ~= previousKB 
			and KC_Fn.table_count(justKilled, zo_strformat("<<1>>", targetName)) < 1 then
		--d( "[" ..result .. "]," .. "[" ..abilityName .. "]," .. "[" ..sourceName .. "]," .. "[" ..sourceType .. "]," .. "[" ..targetName .. "]," .. "[" ..targetType .. "]," .. "[" ..hitValue .. "]," .. "[" ..abilityActionSlotType .. "]," .. "[" ..powerType .. "]," .. "[" ..damageType .. "]" )
	
		--d("Works")
		--d( "[" ..result .. "]," .. "[" ..abilityName .. "]," .. "[" ..sourceName .. "]," .. "[" ..sourceType .. "]," .. "[" ..targetName .. "]," .. "[" ..targetType .. "]," .. "[" ..hitValue .. "]," .. "[" ..abilityActionSlotType .. "]," .. "[" ..powerType .. "]," .. "[" ..damageType .. "]" )
		local doKB = false
		local s = "|C00CF34Killed " .. zo_strformat("<<1>>", targetName)
		local n = zo_strformat("<<1>>", targetName)
		if KC_G.savedVars.killed[zo_strformat("<<1>>", targetName)] == nil then
			--table.insert(KC_G.savedVars.killed, zo_strformat("<<1>>", targetName))
			
			--create array entry for this one
			
			local t = KC_Fn.table_shallow_copy(defaultPlayerArray)
			t.Name = n
			t.Kills = 1
			if temp_targets[n] ~= nil then
				t.Class = temp_targets[n].Class
				t.Alliance = temp_targets[n].Alliance
			end


			KC_G.savedVars.killed[n] = t

			--KC_G.loadKilled()
			--remove from tagged table
		else 
			KC_G.savedVars.killed[n].Kills = KC_G.savedVars.killed[n].Kills + 1
		end


		if result == ACTION_RESULT_KILLING_BLOW and GetUnitName("player") == zo_strformat("<<1>>", sourceName) and abilityName ~= "" then 
			s = s .. (" with a Killing Blow!")
			--d(result, abilityName, targetName, hitValue, targetType, sourceNamed) 
			previousKB = zo_strformat("<<1>>", targetName)
			previousKBTime = GetFrameTimeSeconds()

			kbCounter = kbCounter + 1
			kbStreak = kbStreak + 1
			doKB = true
			

			if KC_Fn.table_count(justKilled, previousKB) < 1 then
				--d("adding " .. previousKB .. "to just killed list")
				table.insert(justKilled, previousKB)
				table.insert(justKilledTime, previousKBTime)
			end

			KC_G.savedVars.killed[previousKB].KillingBlows = KC_G.savedVars.killed[previousKB].KillingBlows + 1
		
		elseif KC_Fn.table_count(tagged, zo_strformat("<<1>>", targetName)) > 0 then
			local pk = zo_strformat("<<1>>", targetName)
			local pkt = GetFrameTimeSeconds()
			if KC_Fn.table_count(justKilled, previousKB) < 1 then
				--d("adding " .. previousKB .. "to just killed list")
				table.insert(justKilled, pk)
				table.insert(justKilledTime, pkt)
			end
		end
		--d(s,"s: " .. zo_strformat("<<1>>", sourceName) .. " a: " .. abilityName .. " c: " ..  KC_Fn.table_count(tagged, zo_strformat("<<1>>", targetName)))
		if  KC_Fn.table_count(tagged, zo_strformat("<<1>>", targetName)) > 0 then
			local k = KC_Fn.table_find(tagged, zo_strformat("<<1>>", targetName))
			table.remove(tagged, k)
			table.remove(taggedTime, k)
		end
		
		if KC_Fn.CheckSetting("ChatKills") then
			d(s)
		end

		KC_G.savedVars.totalKills = KC_G.savedVars.totalKills + 1;
		counter = counter + 1
		streak = streak + 1
		KC_G.doDeathStreakEnd()
		local b = KC_G.doStreak(doKB)
		previousKill = zo_strformat("<<1>>", targetName)

		--updates class and other thing
		if temp_targets[n] ~= nil and KC_G.savedVars.killed[n] ~= nil then
			KC_G.savedVars.killed[n].Class = temp_targets[n].Class
			KC_G.savedVars.killed[n].Alliance = temp_targets[n].Alliance

		end

		--play sound
		if not b and KC_Fn.CheckSetting("Sounds") then
			PlaySound(SOUNDS.LOCKPICKING_SUCCESS_CELEBRATION) --maybe a kill
	  		PlaySound(SOUNDS.LOCKPICKING_UNLOCKED)
	  	end
	--end if
	elseif sourceType == COMBAT_UNIT_TYPE_PLAYER and GetUnitName("player") == zo_strformat("<<1>>", sourceName) and
	 GetUnitName("player") ~= zo_strformat("<<1>>", targetName) and hitValue > 0 and result ~= ACTION_RESULT_KILLING_BLOW
	 and targetType == COMBAT_UNIT_TYPE_OTHER then -- why the fuck is it other?
		--d(targetType)
		local t = zo_strformat("<<1>>", targetName)
		
		if KC_Fn.table_count(tagged, t) < 1 then
			--tag this guy since we'veww damged him and hes not yet tagged
			--d("tagged " .. t)
			table.insert(tagged, t)
			table.insert(taggedTime, GetFrameTimeSeconds())
			--d("tagged " .. t)
		else
			--update their time
			local k = KC_Fn.table_find(tagged, t)
			taggedTime[k] = GetFrameTimeSeconds()
			--d("Updated " .. " tag time")

		end
	end
	
end

--function KC_OnKilled(eventCode)
function KC_G.OnKilled(eventCode)
	if not IsPlayerInAvAWorld() then return end
    --print the inviter's name to chat
    deathCounter = deathCounter + 1
    KC_G.savedVars.totalDeaths = KC_G.savedVars.totalDeaths + 1;
    local s = "|C9C9C9C"
    if streak > 0  then 
    	if KC_Fn.CheckSetting("ChatKStreak") then
    		s = s .. "Your kill streak has ended! You had a streak of " .. streak 
    	end
    else
    	deathStreak = deathStreak + 1
    	KC_G.doDeathStreak()
    	SC_G.resetStreaks()
    end
    streak = 0
    kbStreak = 0
    --d(GetKillingAttackerInfo())
    --par7-combat unit type?COMBAT_UNIT_TYPE_PLAYER
    --par7 is alliance
   	--par2 is v level it seems.?
   	--par5 seems to be seems to be whether or not they are a player
    local killer, vlevel, level, pvplevel, par5bool, par6bool, alliance, par8str = GetKillingAttackerInfo()
    --d(GetKillingAttackerInfo()) 
    --d(GetClassName(GENDER_MALE, par7int), GetClassName(GENDER_MALE, par2))
    --d(GetAllianceName(par7int))
    killer = zo_strformat("<<1>>", killer)
    if par5bool then

	    if KC_G.savedVars.killedBy[killer] == nil then
	    	local a = KC_Fn.table_shallow_copy(defaultKilledByArray)
	    	a.Name = killer
	    	a.KilledBy = 1
	    	a.Alliance = alliance
	    	a.Level = level
	    	a.vLevel = vlevel
	    	KC_G.savedVars.killedBy[killer] = a
	    	if temp_targets[killer] ~= nil then KC_G.savedVars.killedBy[killer].Class = temp_targets[killer].Class end
	    else
	    	KC_G.savedVars.killedBy[killer].KilledBy = KC_G.savedVars.killedBy[killer].KilledBy + 1
	    	KC_G.savedVars.killedBy[killer].Alliance = alliance
	    	KC_G.savedVars.killedBy[killer].Level = level
	    	KC_G.savedVars.killedBy[killer].vLevel = vlevel
	    	if temp_targets[killer] ~= nil then KC_G.savedVars.killedBy[killer].Class = temp_targets[killer].Class end
	    end
	end

    s = "|C870505You were killed by " .. KC_Fn.Alliance_Color(alliance) ..killer .. ". " .. s

    d(s)


end

--function KC_doStreak() 
function KC_G.doStreak(doKB)
	s = ""
	local ret = false
	if KC_G.savedVars.longestStreak == nil or streak > KC_G.savedVars.longestStreak then
		if KC_Fn.CheckSetting("ChatKStreak") then
			s = s .. ("|C5DD61CNew Kill Streak Record! ")
		end
		KC_G.savedVars.longestStreak = streak
	end

	if streak_array[streak] ~= nil then
		if KC_Fn.CheckSetting("ChatKStreak") then
			s = s .. "|CFFA203" ..(streak_array[streak] .. " (" .. streak .. " Kills). ")
		end
		
		if streak < 17 and KC_Fn.CheckSetting("Sounds") then
			PlaySound(SOUNDS.EMPEROR_CORONATED_EBONHEART)
			PlaySound(SOUNDS.ELDER_SCROLL_CAPTURED_BY_EBONHEART)
			PlaySound(SOUNDS.SKILL_GAINED)
		elseif streak <= 50 and KC_Fn.CheckSetting("Sounds") then
			PlaySound(SOUNDS.LEVEL_UP)
			PlaySound(SOUNDS.LOCKPICKING_BREAK)
		end
		ret = true
	end
	if kb_streak_array[kbStreak] ~= nil and doKB then
		if KC_Fn.CheckSetting("ChatKStreak") then
			s = s .. "|C878787".. (kb_streak_array[kbStreak] .. " (" .. kbStreak .. " KBs). ")
		end
		
	end

	if s ~= "" then
		d(s)
	end


	return ret
end

--function KC_doDeathStreak() 
function KC_G.doDeathStreak()
	if KC_G.savedVars.longestDeathStreak == nil or deathStreak > KC_G.savedVars.longestDeathStreak then
		if KC_Fn.CheckSetting("ChatDStreak") then
			d("|C9C9C9CNew Death Streak Record!")
		end
		KC_G.savedVars.longestDeathStreak = deathStreak
	end
	if deathStreak_array[deathStreak] ~= nil and KC_Fn.CheckSetting("ChatDStreak") then
		d("|C9C9C9C"..  deathStreak_array[deathStreak] .. " (" .. deathStreak .. " Deaths)")
	end

end

--function KC_OnAddOnLoaded(eventCode, addOnName)
function KC_G.OnAddOnLoaded(eventCode, addOnName)
	d(addOnName)
    if(addOnName == "KillCounter") then
    	
        KC_G.savedVars = ZO_SavedVars:New("KillCounter_Data", version, nil, defaults, nil)


        --remove dupes. remove this in a later version
        --KC_G.savedVars.killed = table_unique(KC_G.savedVars.killed) no longer need since KC_G.savedVars version 106
        --for k,v in ipairs(KC_G.savedVars) do
        	--table.remove(KC_G.savedVars, k)
        --end

        --update the saved various to the latest format
        --see function.lua for more info
        --KC_G.savedVars = KC_Fn.updateSaved(KC_G.savedVars, KC_G.svDefaults, {killed = defaultPlayerArray})

        --KC_G.loadKilled(
        if KC_G.savedVars.settings == nil then 
        	KC_G.savedVars.settings = KC_Fn.table_shallow_copy(defaultSettingsArray)
        else
        	for k,v in pairs(defaultSettingsArray) do
        		--print(k,v)
        		if KC_G.savedVars.settings[k] == nil then KC_G.savedVars.settings[k] = v end
        	end
        end

        for k,v in pairs(KC_G.savedVars.killedBy) do
        	if type(v.Alliance) ~= "number" then
        		if v.Alliance == "Ebonheart Pact" then v.Alliance = ALLIANCE_EBONHEART_PACT end
        		if v.Alliance == "Aldmeri Dominion" then v.Alliance = ALLIANCE_ALDMERI_DOMINION end
        		if v.Alliance == "Daggerfall Covenant" then v.Alliance = ALLIANCE_DAGGERFALL_COVENANT end
        	end
        end

        if KC_G.savedVars.totalKillingBlows == nil then KC_G.savedVars.totalKillingBlows = 0 end
        if KC_G.savedVars.rankPointsGained == nil then KC_G.savedVars.rankPointsGained = 0 end

        KillCounter:ClearAnchors()
        KillCounter:SetAnchor(KC_G.savedVars.anchorPoint, GuiRoot, nill, KC_G.savedVars.offsetX, KC_G.savedVars.offsetY)

        curXP = GetUnitXP('player')

        -- if KC_G.savedVars.UDP == nil then
        -- 	KC_G.savedVars.UDP = KC_Fn.table_shallow_copy(defaultUDPArray)
        -- else
        -- 	for k,v in pairs(defaultUDPArray) do
        -- 		if KC_G.savedVars.UDP[k] == nil then KC_G.savedVars.settings[k] = v end
        -- 	end
        -- end
    end


end

--function KC_loadKilled()
function KC_G.loadKilled()
	--d("stats")
	--reset stats killed array
	stats_killed_array = {}
	if KC_G.savedVars ~= nil and KC_G.savedVars.killed ~= nil then
		--d("reloading stats")
		stats_killed_array = {}
        for i=1,#KC_G.savedVars.killed do

			stats_killed_array[i] = KC_G.savedVars.killed[i]
		end
	end

	KC_G.updateStats()
end

--function KC_initStreak()
function KC_G.initStreak() 

	--kill streaks
	streak_array[3] = "Three For One!"
	streak_array[5] = "Killing Spree!"
	streak_array[8] = "Dominating!"
	streak_array[12] = "Unstoppable!"
	streak_array[15] = "Massacre!"
	streak_array[18] = "Annihilation!"
	streak_array[21] = "Legendary!"
	streak_array[25] = "Genocide!"
	streak_array[28] = "Demonic!"
	streak_array[32] = "God Like!"
	streak_array[40] = "Praise Thee, Demi-God!"
	streak_array[50] = "Praise Thee, God of Destruction!"


	kb_streak_array[2] = "Hunter"
	kb_streak_array[3] = "Stalker"
	kb_streak_array[5] = "Killer"
	kb_streak_array[8] = "Slayer!"
	kb_streak_array[12] = "Hit Man!"
	kb_streak_array[15] = "Mass Murderer!"
	kb_streak_array[18] = "Executioner!"
	kb_streak_array[21] = "Assassin!"
	kb_streak_array[25] = "Blood Drinker!"
	kb_streak_array[28] = "Agent of Death!"
	kb_streak_array[32] = "Reaper!"
	kb_streak_array[40] = "Angel of Death!"
	kb_streak_array[50] = "God of Death!"





	deathStreak_array[2] = "Honorless Death!"
	deathStreak_array[3] = "Dry Spell!"
	deathStreak_array[4] = "Unfair Disadvantage!"
	deathStreak_array[5] = "Lover, Not a Fighter!"
	deathStreak_array[6] = "Forsaken!"
	deathStreak_array[7] = "500 ms Latency!"
	deathStreak_array[8] = "Plain Ole Baddie!"
end


--function KC_OnInitialized(self)
function KC_G.OnInitialized(self)
	--if addOnName ~="KillCounter" then return end
    --Register on the top level control...
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_COMBAT_EVENT, KC_G.OnKill)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_PLAYER_DEAD, KC_G.OnKilled)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_ADD_ON_LOADED, KC_G.OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_ACTION_LAYER_PUSHED, KC_G.onActionLayerPushed)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_ACTION_LAYER_POPPED, KC_G.onActionLayerPopped)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_PLAYER_COMBAT_STATE, KC_G.CombatState)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_UNIT_DEATH_STATE_CHANGED, KC_G.DeathStateChanged)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_RETICLE_TARGET_CHANGED, KC_G.TargetChanged)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_AVENGE_KILL, KC_G.AvengeKill)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_REVENGE_KILL, KC_G.RevengeKill)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_RANK_POINT_UPDATE, KC_G.Experience_Update)
    --TODO: put these bitches in a SC_G function call along with other event registers, and call that function from here.
    --lazy bitchii
    --EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_KEEP_ALLIANCE_OWNER_CHANGED, SC_G.KeepChanged)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_OBJECTIVE_CONTROL_STATE, SC_G.ObjectiveControlState)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_CAPTURE_AREA_STATUS, SC_G.CaptureAreaStatus)
    EVENT_MANAGER:RegisterForEvent("KillCounter", EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, KC_G.MemberChange)



 	d("Events Registered")
 	--Slash Commands --
 	SLASH_COMMANDS["/kcreset"] = function (extra)
 		-- reset counter
  		counter = 0
  		deathCounter = 0
  		streak = 0
  		deathStreak = 0
  		SC_G.resetStreaks()

  		if extra == "full" then
  			KC_G.statsResetFull()
  			d("Stats Fully Reset")
  			SC_G.ResetSeigeStats()
  		else
  			d("Current Stats Reset")
  		end

	end


	--General purpose kc command
	SLASH_COMMANDS["/kc"] = function (extra)
 		if string.lower(extra) == "toggle" then
 			overrideHideMain = true
 			KC_G.toggle()
 		end
 		if string.lower(extra) == "addkill" then
 			counter = counter + 1
 		end
 		if string.lower(extra) == "adddeath" then
 			deathCounter = deathCounter + 1
 		end
 		if string.lower(extra) == "addstreak" then
 			streak = streak + 1
 		end
 		if string.lower(extra) == "stats" then
 			if (showingStats) then KC_G.closeStats() 
  			else KC_G.showStats() end
  			showingStats = not showingStats
 		end
 		if string.lower(extra) == "settings" then
 			if (showingSettings) then KC_G.closeSettings() 
  			else KC_G.showSettings() end
  			showingSettings = not showingSettings
 		end
 		if string.lower(extra) == "ooc" then
 			showOOC = not showOOC
 			if showOOC then d ("Now showing Out of Combat Messages")
 			else d ("Out of Combat messages Hidden") end
 		end
 		if string.lower(extra) == "sounds" then
 			doSounds = not doSounds
 			if doSounds then d ("Kill Counter sounds turned on.")
 			else d ("Kill Counter sounds turned off.") end
 		end

	end

	SLASH_COMMANDS["/udt"] = function (extra)
		if string.lower(extra) == "disp" then
			d(KC_G.savedVars.UDP.udp)
		end
		if string.lower(extra) == "add" then
			KC_G.savedVars.UDP.udp = KC_G.savedVars.UDP.udp + 1
		end
		if string.lower(extra) == "avenged" then
			d(KC_G.savedVars.UDP.avengeKills)
		end
		if string.lower(extra) == "guild" then
			d(GetGuildName(3))
		end

	end

	SC_G.slashCommands()

	SLASH_COMMANDS["/kctest1337"] = function (extra)
 		-- reset counter
  		--PlaySound(SOUNDS.LOCKPICKING_BREAK)
  		--PlaySound(SOUNDS.LEVEL_UP) high kill streaks
  		--PlaySound(SOUNDS.EMPEROR_CORONATED_EBONHEART) maybe killing spree
  		--PlaySound(SOUNDS.LOCKPICKING_SUCCESS_CELEBRATION) --maybe a kill
  		--PlaySound(SOUNDS.LOCKPICKING_UNLOCKED)
  		--PlaySound(SOUNDS.EMPEROR_CORONATED_EBONHEART)
  		--PlaySound(SOUNDS.SKILL_GAINED)
  		--d(SOUNDS)
  		--d(GetFrameTimeSeconds())	--d(tagged, taggedTime)
  		--d(GetUnitZone("Player"))
  		--d("|CffFF00dddd")
  		d(KC_G.savedVars.killedBy)
  		--d(KC_G.savedVars.kills['Landymac'].Seige_Kills)
	end

	KC_G.initStreak()
	SC_G.initStreak()
end

--[[]]
function KC_G.Experience_Update(eventCode, unitTag, rankPoints, diff)
	if KC_G.savedVars == nil then return end

	--if reason == XP_REASON_KILL then 
	--d(unitTag, currentExp, maxExp, reason)
	if unitTag == 'player' and KC_G.savedVars.rankPointsGained ~= nil then
		
		--GetUnitRankPoints
		rankPointsGained = rankPointsGained + diff
		KC_G.savedVars.rankPointsGained = KC_G.savedVars.rankPointsGained + diff
		--d(diff .. " ap gained", rankPointsGained)
	end


		
end

--]]

function KC_G.TargetChanged(eventCode, unitTag)
	if not DoesUnitExist('reticleover') then return	end

	if IsUnitPlayer('reticleover') and GetUnitAlliance('reticleover') ~= GetUnitAlliance('player')   then
		local n = GetUnitName('reticleover')

		local c = GetUnitClass('reticleover')
		local a = GetUnitAlliance('reticleover')
		local l = GetUnitLevel('reticleover')
		local vl = GetUnitVeteranRank('reticleover')

		local t = KC_Fn.table_shallow_copy(target_default)
		t.Name = n
		t.Class = c
		t.Alliance = a

		--check if they are in the killed table
		if KC_G.savedVars.killed[n] ~= nil then
			KC_G.savedVars.killed[n].Class = c
			KC_G.savedVars.killed[n].Alliance = a
		else		
			if temp_targets[n] == nil then
				--d("Adding " .. n .. " to temporary table")
				temp_targets[n] = t
			end
		end

		if KC_G.savedVars.killedBy[n] ~= nil then
			KC_G.savedVars.killedBy[n].Class = c
			KC_G.savedVars.killedBy[n].Alliance = a
		else		
			if temp_targets[n] == nil then
				--d("Adding " .. n .. " to temporary table")
				temp_targets[n] = t
			end
		end
	end
	--d(n,c,a)
end





--function KC_onActionLayerPushed(self, arg1, arg2)
function KC_G.onActionLayerPushed(self, arg1, arg2)
	if pushed < 1 then 
		pushed = pushed + 1
		return end
	--d("things")
	if arg2 == 2 then return end
	KillCounter:SetHidden(true)
	if showingStats and stats_window ~= nil then stats_window:SetHidden(true) end
	pushed = pushed + 1
end

--function KC_onActionLayerPopped(self, arg1, arg2)
function KC_G.onActionLayerPopped(self, arg1, arg2)
	KillCounter:SetHidden(false)

	if showingStats and stats_window ~= nil then stats_window:SetHidden(false) end
end

--function KC_doDeathStreakEnd()
function KC_G.doDeathStreakEnd() 
	if deathStreak > 0 then 
		d("Your death streak of " .. deathStreak .. " has ended!")
	end
	deathStreak = 0
end


--function KC_statsResetFull()
function KC_G.statsResetFull()
	for k in pairs (KC_G.savedVars.killed) do
	    KC_G.savedVars.killed [k] = nil
	end
	KC_G.savedVars.killed = {}
	KC_G.savedVars.totalKills = 0
	KC_G.savedVars.totalDeaths = 0
	KC_G.savedVars.longestStreak = 0
	KC_G.savedVars.longestDeathStreak = 0
	--KC_G.loadKilled()
	--d("saved vars: " .. #KC_G.savedVars.Killed)
	KC_G.updateStats(true)
end

--function KC_toggle()
function KC_G.toggle()

	if hideMain then
		KC_G.show()
		d("Kill Counter is now visible. Type /kc toggle to hide.")
	else
		KC_G.hide()
		d("Kill Counter is now hidden. Type /kc toggle to show.")
	end
end

function KC_G.show() 
	KillCounter:SetHidden(false)
	hideMain = false
	KillCounter:SetAlpha(1.0)
end


--function KC_hide()
function KC_G.hide()
	hideMain = true
	KillCounter:SetAlpha(0.0)
	return KillCounter:SetHidden(true)
end

function KC_G.CombatState(self, inCombat)
	if not inCombat then
		if showOOC then d("out of combat") end
		
		--tagged = {}
		--taggedTime = {}
		
		justKilled = {}
		justKilledTime = {}

		--temp_targets = {}


	end

end


function KC_G.DeathStateChanged(self, unitTag, isDead)
	if (isDead) and IsUnitPlayer(unitTag) then
		if GetUnitAlliance(unitTag) ~= GetUnitAlliance('player') and GetUnitName('player') ~= GetUnitName(unitTag) then
			local n = GetUnitName(unitTag)
			--d(n .. " died", unitTag)
		end
	end

	if not isDead and unitTag == 'player' then
		tagged = {}
		taggedTime = {}
		temp_targets = {}
	end

	if not isDead and unitTag ~= 'player' then
		if KC_Fn.table_count(justKilled, GetUnitName(unitTag)) then
			k = KC_Fn.table_find(justKilled, GetUnitName(unitTag))
			table.remove(justKilled, k)
			table.remove(justKilledTime, k)
		end
	end
end



function  KC_G.AvengeKill(eventCode, avengedPlayer, killedPlayer)
	--just killed a player
	--d("avenged")
	local n = zo_strformat("<<1>>", killedPlayer)
	if KC_G.savedVars.killed[n] == nil then
			--table.insert(KC_G.savedVars.killed, zo_strformat("<<1>>", targetName))
			
			--create array entry for this one
			
			local t = KC_Fn.table_shallow_copy(defaultPlayerArray)
			t.Name = n
			t.Avenge_Kills = 1
			if temp_targets[n] ~= nil then
				t.Class = temp_targets[n].Class
				t.Alliance = temp_targets[n].Alliance
			end


			KC_G.savedVars.killed[n] = t

			--KC_G.loadKilled()
			--remove from tagged table
		else 
			KC_G.savedVars.killed[n].Avenge_Kills = KC_G.savedVars.killed[n].Avenge_Kills + 1
		end
		-- the kill counter stuff is done, now to add in the UDP tracking
		if (KC_G.UDAvenge(avengedPlayer) == true) then 
			KC_G.savedVars.UDP.udp = KC_G.savedVars.UDP.udp + 1
			KC_G.savedVars.UDP.avengeKills = KC_G.savedVars.UDP.avengeKills + 1
		end
end

function KC_G.UDAvenge(avengedPlayer)
	--must determine if the player avenged was part of urgent dawn, if yes add +! UDP
	return true
end

function  KC_G.RevengeKill(eventCode, killedPlayer)
	local n = zo_strformat("<<1>>", killedPlayer)
	--d("vengence")
	if KC_G.savedVars.killed[n] == nil then
			--table.insert(KC_G.savedVars.killed, zo_strformat("<<1>>", targetName))
			
			--create array entry for this one
			
			local t = KC_Fn.table_shallow_copy(defaultPlayerArray)
			t.Name = n
			t.Revent_Kills = 1
			if temp_targets[n] ~= nil then
				t.Class = temp_targets[n].Class
				t.Alliance = temp_targets[n].Alliance
			end


			KC_G.savedVars.killed[n] = t

			--KC_G.loadKilled()
			--remove from tagged table
		else 
			KC_G.savedVars.killed[n].Revent_Kills = KC_G.savedVars.killed[n].Revent_Kills + 1
		end
end

function KC_G.MemberChange(GuildID, PlayerName, prevStatus, curStatus)
	d(GuildID)
	-- resp = GetGuildMemberInfo(PlayerName,GuildID)
	resp = GetPlayerGuildMemberIndex(GuildID)
	d(resp)
	charName = zo_strformat(SI_UNIT_NAME,charName)
	if (curStatus == 4) then
		d(charName .. "Logged Off in Guild: " .. GetGuildName(PlayerName))
	elseif (curStatus == 1) then
		d(charName .. "Logged On in Guild: " .. GetGuildName(PlayerName))
	end
	-- d("Guild: " .. GetGuildName(GetGuildId(GuildID)))
	-- d("Player" .. PlayerName)
	-- d("Status" .. curStatus)

	-- d("Guild Member Update " .. guildID .. displayName)
end


--[[
/esoui/art/campaign/leaderboard_top20banner.dds

/iv 
lol 3 way

/esoui/art/mappins/ava_borderkeep_pin_aldmeri.dds
/esoui/art/mappins/ava_borderkeep_pin_daggerfall.dds
/esoui/art/mappins/ava_borderkeep_pin_ebonheart.dds

/esoui/art/campaign/campaign_tabicon_browser_up.dds

/esoui/art/progression/progression_crafting_delevel_up.dds
/esoui/art/progression/progression_crafting_unlocked_down.dds
/esoui/art/mainmenu/menubar_ava_up.dds
/esoui/art/actionbar/quickslotbg.dds
bgs
/esoui/art/itemtooltip/simpleprogbarbg_center.dds
/esoui/art/lorelibrary/lorelibrary_stonetablet.dds

/esoui/art/screens/loadscreen_topmunge_tile.dds
/esoui/art/tooltips/munge_overlay.dds
/esoui/art/unitattributevisualizer/attributebar_dynamic_invulnerable_munge.dds

--]]
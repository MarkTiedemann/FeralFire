
-- TODO: Advanced Faerie Fire options for dealing with invisibility potions, druids,
-- and rogues

-- WONTFIX: When Faerie Fire (*not* Feral) is located on the action bar, the
-- Faerie Fire (Feral) cooldown does not work
-- WONTFIX: On shapeshifting, getting a slot may throw an error

-- EXPLORE: Check who caused debuff so that Rake and Rip can stack (if possible)
-- EXPLORE: Query energy costs for each attack (if possible)
-- EXPLORE: Query whether Track Humanoids is active (if possible)

-- FEATURE: When shapeshifting into Cat Form, automatically click Track Humanoids
-- FEATURE: Implement priority queue for the attacks

local cast = CastSpellByName

local ATTACK_ICON = 'Interface\\Icons\\Ability_Druid_CatFormAttack'
local PROWL_INACTIVE_ICON = 'Interface\\Icons\\Ability_Ambush'
local PROWL_ACTIVE_ICON = 'Interface\\Icons\\Spell_Nature_Invisibilty'
local CLAW_ICON = 'Interface\\Icons\\Ability_Druid_Rake'
local RAKE_ICON = 'Interface\\Icons\\Ability_Druid_Disembowel'
local RIP_ICON = 'Interface\\Icons\\Ability_GhoulFrenzy'
local FAERIE_FIRE_ICON = 'Interface\\Icons\\Spell_Nature_FaerieFire'

function FF_GetDefaultSettings()

    settings = {}

    settings.target_nearest_enemy = true

    settings.track_humanoids = true

    settings.faerie_fire = true

    settings.ravage = true
    settings.ravage_costs = 60

    settings.pounce = false
    settings.pounce_costs = 50

    settings.rake = true
    settings.rake_costs = 35

    settings.claw = true
    settings.claw_costs = 40

    settings.shred = false
    settings.shred_costs = 60

    settings.rip = true
    settings.rip_costs = 30
    settings.rip_threshold = 5

    settings.ferocious_bite = false
    settings.ferocious_bite_costs = 35
    settings.ferocious_bite_threshold = 5

    settings.debug_settings = false
    settings.debug_state = false

    return settings
end

function FF_GetFearieFireRank()

    local FERAL_SPELL_TAB_INDEX = 3
    local tabName, tabTexture, tabSpellOffset, tabNumSpells =
        GetSpellTabInfo(FERAL_SPELL_TAB_INDEX)
    local faerieFireRank = nil

	for spellIndex = tabSpellOffset + 1, tabSpellOffset + tabNumSpells do
        local spellName, spellRank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
        if spellName == 'Faerie Fire (Feral)' then
            local length = string.len(spellRank)
            -- spellRank is a string which looks like this: "Rank #"
            -- To extract the number from the string, we have to use substring
            -- because, in Lua, there is no built-in charAt function
            faerieFireRank = string.sub(spellRank, length, length)
        end
	end

    return faerieFireRank
end

function FF_GetSlot(icon)

    local ACTION_BAR_COUNT = 6
    local SLOTS_PER_ACTION_BAR = 12

    for slot = 1, ACTION_BAR_COUNT * SLOTS_PER_ACTION_BAR  do
        if HasAction(slot) then
            if icon == GetActionTexture(slot) then
                return slot
            end
        end
    end

    return nil
end

function FF_GetState(settings)

    local state = {}

    state.energy = UnitMana('player')
    state.comboPoints = GetComboPoints('player')

    state.hasTarget = GetUnitName('target')
    state.isTargetDead = UnitIsDead('target') == 1

    -- TODO: Improve performance of getting the slots

    state.attackSlot = FF_GetSlot(ATTACK_ICON)
    state.prowlingSlot = FF_GetSlot(PROWL_ACTIVE_ICON) or FF_GetSlot(PROWL_INACTIVE_ICON)
    state.faerieFireSlot = FF_GetSlot(FAERIE_FIRE_ICON)
    state.clawSlot = FF_GetSlot(CLAW_ICON)

    state.isInCombat = UnitAffectingCombat('player') == 1
    state.isAutoAttacking = IsCurrentAction(state.attackSlot)
    state.isProwling = GetActionTexture(state.prowlingSlot) == PROWL_ACTIVE_ICON
    state.isFaerieFireReady = GetActionCooldown(state.faerieFireSlot) == 0
    state.isReady = GetActionCooldown(state.clawSlot) == 0

    state.faerieFireRank = FF_GetFearieFireRank()

    return state
end

function FF_IsDebuffActive(icon)

    local active = false

    for index = 1, 20 do
        if icon == UnitDebuff('target', index) then
            active = true
            break
        end
    end

    return active
end

function FF_StartAttack(settings, state)

    -- Debug settings
    if settings.debug_settings then
        for key, value in pairs(settings) do
            ChatFrame1:AddMessage(key .. '=' .. tostring(value))
        end
    end

    -- Debug state
    if settings.debug_state then
        for key, value in pairs(state) do
            ChatFrame1:AddMessage(key .. '=' .. tostring(value))
        end
    end

    -- Global Cooldown
    if not state.isReady then
        return
    end

    if not state.hasTarget
        or state.isTargetDead then
            -- Target nearest enemy
            if settings.target_nearest_enemy then
                TargetNearestEnemy()
                -- Track Humanoids
                if settings.track_humanoids then
                    return cast('Track Humanoids')
                else
                    return -- prevent accidental pull
                end
            end
    end

    -- Ravage
    if settings.ravage
        and state.isProwling
            and state.energy >= settings.ravage_costs then
                return cast('Ravage')
    end

    -- Pounce
    if settings.pounce
        and state.isProwling
            and state.energy >= settings.pounce_costs then
                return cast('Pounce')
    end

    -- Attack
    if not state.isAutoAttacking then
        cast('Attack')
    end

    -- Faerie Fire (out of combat, for pulling)
    if settings.faerie_fire
        and state.isFaerieFireReady
            and not state.isInCombat
                and not FF_IsDebuffActive(FAERIE_FIRE_ICON) then
                    return cast('Faerie Fire (Feral)(Rank ' .. state.faerieFireRank .. ')')
    end

    -- Rip
    if settings.rip
        and state.comboPoints >= settings.rip_threshold
            and state.energy >= settings.rip_costs
                and not FF_IsDebuffActive(RIP_ICON) then
                    return cast('Rip')
    end

    -- Ferocious Bite
    if settings.ferocious_bite
        and state.comboPoints >= settings.ferocious_bite_threshold
            and state.energy >= settings.ferocious_bite_costs then
                return cast('Ferocious Bite')
    end

    -- Rake
    if settings.rake
        and state.energy >= settings.rake_costs
            and not FF_IsDebuffActive(RAKE_ICON) then
                return cast('Rake')
    end

    -- Claw
    if settings.claw
        and state.energy >= settings.claw_costs then
            return cast('Claw')
    end

    -- Shred
    if settings.shred
        and state.energy >= settings.shred_costs then
            return cast('Shred')
    end

    -- Faerie Fire (in combat)
    if settings.faerie_fire
        and state.isFaerieFireReady
            and not FF_IsDebuffActive(FAERIE_FIRE_ICON) then
                return cast('Faerie Fire (Feral)(Rank ' .. state.faerieFireRank .. ')')
    end

end

function FF_FindValue(message, key)

    local keyLength = string.len(key)
    local startIndex = strfind(message, key .. '=')

    if startIndex == nil then
        return nil
    else
        local endIndex = strfind(message, ' ', startIndex)
            or string.len(message) + 1
        return strsub(message, startIndex + keyLength + 1, endIndex - 1)
    end
end

function FF_ConvertValue(value)

    if value == 'true' then
        return true
    elseif value == 'false' then
        return false
    else
        return tonumber(value)
    end
end

function FF_UpdateSettings(settings, message)

    -- TODO: Improve performance by parsing the message
    -- instead of looping through it, looking for each setting

    for key, value in pairs(settings) do
        local newValue = FF_FindValue(message, key)
        if newValue then
            settings[key] = FF_ConvertValue(newValue)
        end
    end

    return settings
end

function FF_InitSlashCommand()

    SLASH_FERALFIRE1, SLASH_FERALFIRE2 = '/ff', '/feralfire'

    function SlashCmdList.FERALFIRE(message)

        -- TODO: Improve performance by caching the settings for
        -- each message, so they don't have to be updated again

        -- 1. Get default settings
        local settings = FF_GetDefaultSettings()
        -- 2. Update settings based on command message
        settings = FF_UpdateSettings(settings, message)
        -- 3. Get current state based on settings
        local state = FF_GetState(settings)
        -- 4. Start attack based on settings and state
        FF_StartAttack(settings, state)
    end
end

FF_InitSlashCommand()

ChatFrame1:AddMessage('// FeralFire v0.8 loaded')
ChatFrame2:AddMessage('// FeralFire v0.8 loaded')


-- FIXME: Implement Global Cooldown queries
-- FIXME: Query whether Track Humanoids is active, or:
-- FIXME: When shapeshifting into Cat Form, automatically click Track Humanoids

-- IDEA: Implement priority queue instead of 'if ... else ...'
-- IDEA: Feature 'Mend': Undo shapeshifting, cast Healing Touch, shapeshift back into Cat Form

local cast = CastSpellByName

local PROWLING_ICON = 'Interface\\Icons\\Spell_Nature_Invisibilty'
local RAKE_ICON = 'Interface\\Icons\\Ability_Druid_Disembowel'
local RIP_ICON = 'Interface\\Icons\\Ability_GhoulFrenzy'
local FAERIE_FIRE_ICON = 'Interface\\Icons\\Spell_Nature_FaerieFire'

function FF_GetDefaultSettings()

    settings = {}

    settings.attack_slot = 13
    settings.prowling_slot = 14
    settings.faerie_fire_slot = 15

    settings.use_track_humanoids = true

    settings.use_auto_targetting = true

    settings.use_faerie_fire = true
    settings.faerie_fire_rank = 1

    settings.use_rake = true
    settings.rake_costs = 35

    settings.backstab_move = 'Ravage' -- or 'Pounce'

    settings.default_special_attack = 'Claw' -- or 'Shred'
    settings.default_special_attack_costs = 40

    settings.use_rip = true
    settings.rip_costs = 30
    settings.rip_threshold = 5

    settings.use_ferocious_bite = false
    settings.ferocious_bite_costs = 35
    settings.ferocious_bite_threshold = 5

    return settings
end

function FF_GetState(settings)

    local state = {}

    state.energy = UnitMana('player')
    state.comboPoints = GetComboPoints('player')
    state.hasTarget = GetUnitName('target')
    state.isAutoAttacking = IsCurrentAction(settings.attack_slot)
    state.isProwling = GetActionTexture(settings.prowling_slot) == PROWLING_ICON

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

function FF_ShouldCastFaerieFire(settings, state)

    if not settings.use_faerie_fire then
        return false
    end

    if not GetActionCooldown(settings.faerie_fire_slot) == 0 then
        return false
    end

    return not FF_IsDebuffActive(FAERIE_FIRE_ICON)
end

function FF_CastFaerieFire(settings, state)

    cast('Faerie Fire (Feral)(Rank ' .. settings.faerie_fire_rank .. ')')

    -- If Faerie Fire was resisted, attack anyways
    if not FF_IsDebuffActive(FAERIE_FIRE_ICON)
        and not state.isAutoAttacking then
            cast('Attack')
    end
end

function FF_ShouldCastRake(settings, state)

    if not settings.use_rake then
        return false
    end

    if state.energy < settings.rake_costs then
        return false
    end

    if FF_IsDebuffActive(RAKE_ICON) then
        return false
    end

    -- Only use Rake if you don't have enough Combo Points for Rip
    if settings.use_rip
        and state.comboPoints >= settings.rip_threshold then
            return false
    end

    -- Only use Rake if you don't have enough Combo Points for Ferocious Bite
    if settings.use_ferocious_bite
        and state.comboPoints >= settings.ferocious_bite_threshold then
            return false
    end

    return true
end

function FF_CastRake(settings, state)

    cast('Rake')

    -- If Rake was resisted, attack anyways
    if not FF_IsDebuffActive(RAKE_ICON)
        and not state.isAutoAttacking then
            cast('Attack')
    end
end

function FF_StartAttack(settings, state)

    if not state.hasTarget then
        -- Ensure targetting
        if settings.use_auto_targetting then
            TargetNearestEnemy()
            -- Ensure tracking
            if settings.use_track_humanoids then
                return cast('Track Humanoids')
            end
        end
    end

    -- Backstab
    if state.isProwling then
        return cast(settings.backstab_move)
    end

    -- Faerie Fire
    if FF_ShouldCastFaerieFire(settings, state) then
        return FF_CastFaerieFire(settings, state)
    end

    -- Rake
    if FF_ShouldCastRake(settings, state) then
        return FF_CastRake(settings, state)
    end

    -- Rip
    if settings.use_rip
        and state.comboPoints >= settings.rip_threshold
            and state.energy >= settings.rip_costs
                and not FF_IsDebuffActive(RIP_ICON) then
                    return cast('Rip')
    end

    -- Ferocious Bite
    if settings.use_ferocious_bite
        and state.comboPoints >= settings.ferocious_bite_threshold
            and state.energy >= settings.ferocious_bite_costs then
                return cast('Ferocious Bite')
    end

    -- Special Attack
    if state.energy >= settings.default_special_attack_costs then
        return cast(settings.default_special_attack)
    end

    -- Default attack
    if not state.isAutoAttacking then
        return cast('Attack')
    end

end

function FF_FindValue(message, key)

    local keyLength = string.len(key)
    local startIndex = strfind(message, key)
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
            or value
    end
end

function FF_UpdateSettings(settings, message)

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

ChatFrame1:AddMessage('// FeralFire v0.3 loaded')
ChatFrame2:AddMessage('// FeralFire v0.3 loaded')

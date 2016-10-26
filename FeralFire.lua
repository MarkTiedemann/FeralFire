
-- IDEA: When shapeshifting into Cat Form, automatically click Track Humanoids
-- IDEA: Implement priority queue instead of 'if ... else ...'
-- IDEA: Feature 'Mend': Undo shapeshifting, cast Healing Touch, shapeshift back into Cat Form

-- DEFAULT SETTINGS --

FF = {}

FF.ATTACK_SLOT = 13
FF.PROWLING_SLOT = 14
FF.FAERIE_FIRE_SLOT = 15

FF.USE_TRACK_HUMANOIDS = true

FF.USE_AUTO_TARGETTING = true

FF.USE_FAERIE_FIRE = true
FF.FAERIE_FIRE_RANK = 2

FF.USE_RAKE = true
FF.RAKE_COSTS = 35

FF.BACKSTAB_MOVE = 'Pounce' -- or 'Ravage'

FF.DEFAULT_SPECIAL_ATTACK = 'Claw' -- or 'Shred'
FF.DEFAULT_SPECIAL_ATTACK_COSTS = 40

FF.USE_RIP = true
FF.RIP_COSTS = 30
FF.RIP_THRESHOLD = 3

FF.USE_FEROCIOUS_BITE = false
FF.FEROCIOUS_BITE_COSTS = 35
FF.FEROCIOUS_BITE_THRESHOLD = 4

-- CONSTANTS --

PROWLING_ICON = 'Interface\\Icons\\Spell_Nature_Invisibilty'

RAKE_ICON = 'Interface\\Icons\\Ability_Druid_Disembowel'
RIP_ICON = 'Interface\\Icons\\Ability_GhoulFrenzy'
FAERIE_FIRE_ICON = 'Interface\\Icons\\Spell_Nature_FaerieFire'

-- FUNCTIONS --

function FF_IsProwling()
    return GetActionTexture(FF.PROWLING_SLOT) == PROWLING_ICON
end

function FF_IsAutoAttacking()
    return IsCurrentAction(FF.ATTACK_SLOT)
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

function FF_Attack()

    local energy = UnitMana('player')
    local comboPoints = GetComboPoints('player')
    local cast = CastSpellByName

    if not GetUnitName('target') then
        -- Ensure targetting
        if FF.USE_AUTO_TARGETTING then
            TargetNearestEnemy()
            -- Ensure tracking
            if FF.USE_TRACK_HUMANOIDS then
                return cast('Track Humanoids')
            end
        end
    end

    -- 1 - If prowling, use backstab move
    if FF_IsProwling() then
        cast(FF.BACKSTAB_MOVE)

    -- 2 - Ensure Faerie Fire
    elseif FF.USE_FAERIE_FIRE
        and GetActionCooldown(FF.FAERIE_FIRE_SLOT) == 0
            and not FF_IsDebuffActive(FAERIE_FIRE_ICON) then
                cast('Faerie Fire (Feral)(Rank ' .. FF.FAERIE_FIRE_RANK .. ')')
                -- If Faerie Fire was resisted, attack anyways
                if not FF_IsDebuffActive(FAERIE_FIRE_ICON) and not FF_IsAutoAttacking() then
                    cast('Attack')
                end

    -- 3 - Ensure Rake
    elseif FF.USE_RAKE
        and energy >= FF.RAKE_COSTS
            -- If you have enough Combo Points for Rip, don't use Rake
            and comboPoints < FF.RIP_THRESHOLD
                and not FF_IsDebuffActive(RAKE_ICON) then
                    cast('Rake')
                    -- If Rake was resisted, attack anyways
                    if not FF_IsDebuffActive(RAKE_ICON) and not FF_IsAutoAttacking() then
                        cast('Attack')
                    end

    -- 4 - Ensure Rip
    elseif FF.USE_RIP
        and comboPoints >= FF.RIP_THRESHOLD
            and energy >= FF.RIP_COSTS
                and not FF_IsDebuffActive(RIP_ICON) then
                    cast('Rip')

    -- 5 - Ensure Ferocious Bite
    elseif FF.USE_FEROCIOUS_BITE
        and comboPoints >= FF.FEROCIOUS_BITE_THRESHOLD
            and energy >= FF.FEROCIOUS_BITE_COSTS then
                cast('Ferocious Bite')

    -- 6 - If enough energy, do default attack
    elseif energy >= FF.DEFAULT_SPECIAL_ATTACK_COSTS then
        cast(FF.DEFAULT_SPECIAL_ATTACK)

    -- 7 - Else just attack
    elseif not FF_IsAutoAttacking() then
        cast('Attack')
    end

end

-- SLASH COMMAND --

function FF_FindValue(str, key)
    local keyLength = string.len(key)
    local startIndex = strfind(str, key)
    if startIndex == nil then
        return nil
    else
        local endIndex = strfind(str, ' ', startIndex)
            or string.len(str) + 1
        return strsub(str, startIndex + keyLength + 1, endIndex - 1)
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

function FF_UpdateSettings(msg)
    for key, value in pairs(FF) do
        local newValue = FF_FindValue(msg, string.lower(key))
        if newValue then
            FF[key] = FF_ConvertValue(newValue)
        end
    end
end

function FF_InitSlashCmd()
    SLASH_FERALFIRE1, SLASH_FERALFIRE2 = '/ff', '/feralfire'
    function SlashCmdList.FERALFIRE(msg)
        FF_UpdateSettings(msg)
        FF_Attack()
    end
end

FF_InitSlashCmd()
DEFAULT_CHAT_FRAME:AddMessage('Feral ready to spit fire!')


-- TODO: When shapeshifting into Cat Form, automatically click Track Humanoids
-- TODO: Implement overwriting the default settings via slash commands

-- DEFAULT SETTINGS --

FF_ATTACK_SLOT = 13
FF_PROWLING_SLOT = 14
FF_FAERIE_FIRE_SLOT = 15

FF_USE_FAERIE_FIRE = true
FF_FAERIE_FIRE_RANK = 2

FF_USE_RAKE = true
FF_RAKE_COSTS = 35

FF_BACKSTAB_MOVE = 'Pounce' -- or 'Ravage'

FF_DEFAULT_SPECIAL_ATTACK = 'Claw' -- or 'Shred'
FF_DEFAULT_SPECIAL_ATTACK_COSTS = 40

FF_USE_RIP = true
FF_RIP_COSTS = 30
FF_RIP_THRESHOLD = 3

FF_FEROCIOUS_BITE_COSTS = 35
FF_FEROCIOUS_BITE_THRESHOLD = 4

-- CONSTANTS --

PROWLING_ICON = 'Interface\\Icons\\Spell_Nature_Invisibilty'

RAKE_ICON = 'Interface\\Icons\\Ability_Druid_Disembowel'
RIP_ICON = 'Interface\\Icons\\Ability_GhoulFrenzy'
FAERIE_FIRE_ICON = 'Interface\\Icons\\Spell_Nature_FaerieFire'

-- FUNCTIONS --

function FF_IsProwling()
    return GetActionTexture(FF_PROWLING_SLOT) == PROWLING_ICON
end

function FF_IsAutoAttacking()
    return IsCurrentAction(FF_ATTACK_SLOT)
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

    -- 0 - Ensure target
    if not GetUnitName('target') then
        TargetNearestEnemy()
    end

    -- 1 - If prowling, use backstab move
    if FF_IsProwling() then
        cast(FF_BACKSTAB_MOVE)

    -- 2 - Ensure Faerie Fire
    elseif FF_USE_FAERIE_FIRE
        and GetActionCooldown(FF_FAERIE_FIRE_SLOT) == 0
            and not FF_IsDebuffActive(FAERIE_FIRE_ICON) then
                cast('Faerie Fire (Feral)(Rank ' .. FF_FAERIE_FIRE_RANK .. ')')
                -- If Faerie Fire was resisted, attack anyways
                if not FF_IsDebuffActive(FAERIE_FIRE_ICON) and not FF_IsAutoAttacking() then
                    cast('Attack')
                end

    -- 3 - Ensure Rake
    elseif FF_USE_RAKE
        and energy >= FF_RAKE_COSTS
            and not FF_IsDebuffActive(RAKE_DEBUFF) then
                cast('Rake')
                -- If Rake was resisted, attack anyways
                if not FF_IsDebuffActive(RAKE_ICON) and not FF_IsAutoAttacking() then
                    cast('Attack')
                end

    -- 4 - Ensure Rip
    elseif FF_USE_RIP
        and comboPoints >= FF_RIP_THRESHOLD
            and energy >= FF_RIP_COSTS
                and not FF_IsDebuffActive(RIP_ICON) then
                    cast('Rip')

    -- 5 - Ensure Ferocious Bite
    elseif comboPoints >= FF_FEROCIOUS_BITE_THRESHOLD
            and energy >= FF_FEROCIOUS_BITE_COSTS then
                cast('Ferocious Bite')

    -- 6 - If enough energy, do default attack
    elseif energy >= FF_DEFAULT_SPECIAL_ATTACK_COSTS then
        cast(FF_DEFAULT_SPECIAL_ATTACK)

    -- 7 - Else just attack
    elseif not FF_IsAutoAttacking() then
        cast('Attack')
    end

end

-- INIT SLASH COMMAND --

SLASH_FERALFIRE1, SLASH_FERALFIRE2 = '/ff', '/feralfire'

function SlashCmdList.FERALFIRE(msg)
    FF_Attack()
end

DEFAULT_CHAT_FRAME:AddMessage('Feral ready to spit fire!')

--consts
GCD_LAG = 0.3
GCD = 1.5
DEBUFF_RENEW_THRESH = 2
FRENZY_EXPIRATION = 42
POWER_CAP = 100

FRENZY = 'Бешенство'
BARBED = 'Разрывающий выстрел'
WRATH = 'Звериный гнев'
CHIMAERA = 'Выстрел химеры'
CROW = 'Стая воронов'
ASPECT = 'Дух дикой природы'
COBRA = 'Выстрел кобры'
KILLC = 'Команда "Взять!"'
MULTISHOT = 'Залп'
PET = 'pet'
PLAYER = 'player'

function canCast(spell_name)    
    local exists = UnitExists("target")
    if (exists) then
        local inRange = (IsSpellInRange(spell_name, "target") == 1) and true or false
        if (inRange) then
            return true;
        end
    end
end

function findAura(unit, aura)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitAura(unit, i);
        --unit caster?
        if (name == aura) then
            return  count, duration, expirationTime
        end
    end
    return false;
end

function stackOvercap(spell)
    currentCharges, maxCharges, _, _, _ = GetSpellCharges(spell)
    if (currentCharges == maxCharges) then
        return true
    end
end

function spellCD(spell)
    local startTime, duration = GetSpellCooldown(spell)
    return startTime > 0 and GetTime()-(startTime+duration) or 0
end

function auraDuration(unit, spell)
    local count, duration, expirationTime = findAura(unit, spell)
    if (count and count > 0) then 
        local duration = expirationTime - GetTime()
        return duration
    else
        return 0
    end
end

function frenzyExpires()
    local frenzyDuration = auraDuration(PET, FRENZY)
    local expires = (frenzyDuration > 0 and frenzyDuration < FRENZY_EXPIRATION) and true or false
    return expires
end

function barbedTwoStacksSoon()
    local currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetSpellCharges(BARBED)
    local cdFinishAt = cooldownStart + cooldownDuration
    local cdEndSoon = (cooldownStart + cooldownDuration - GetTime() < FRENZY_EXPIRATION )  and true or false
    if (currentCharges == 1 and GetTime() > - GCD*1.5) then
        return true
    end
end

function powerOvercap()
    if (UnitPower(PLAYER) >= POWER_CAP) then
        return true
    end
end


--final cast bools
function castKillCommand()
    if (canCast(KILLC)) then
        return (spellCD(KILLC) < GCD) and true or false
    end 
end

function castChimaera()
    if (canCast(CHIMAERA) and not powerOvercap() and spellCD(CHIMAERA) < GCD_LAG) then
        return true
    end
end

function castBarbed()
    local cd = spellCD(BARBED)
    if (canCast(BARBED) and cd < GCD) then
        
        if (frenzyExpires()) then
            return true
        end

        --check if wrath on cd to utilize cd reduction?
        if (stackOvercap(BARBED)) then
            return true
        end
 
        local moreImportantCastInQueue = false
        if (castChimaera() or castKillCommand() or castWrath() or castAspect()) then
            moreImportantCastInQueue = true
        end

        --and not castWrath()
        if (barbedTwoStacksSoon() and not moreImportantCastInQueue) then
            return true
        end

        local frenzyDuration = auraDuration(PET, FRENZY)
        local wrathDuration = auraDuration(PLAYER, WRATH)
        if (frenzyDuration == 0 and wrathDuration > 0) then
            return true
        end

    end
end

function castCrow()
    if (canCast(CROW) and spellCD(CROW) < GCD) then
        return true
    end
end

function castWrath()
    if (canCast(WRATH) and spellCD(WRATH) < GCD) then
        return true
    end
end

function castAspect()
    if (canCast(ASPECT) and spellCD(ASPECT) < GCD) then
        return true
    end
end

function castCobra()
    if (canCast(COBRA)) then   
        local wrath_cd = spellCD(WRATH)
        local killc_cd = spellCD(KILLC)
        local crow_cd = spellCD(CROW)

        local power = UnitPower("player")

        local killc_approaches = (killc_cd < 3) and true or false
        local wrath_approaches = (wrath_cd < 15) and true or false
        local crow_approaches = (crow_cd < 10) and true or false

        local power_overcap = (power > 90) and true or false

        local moreImportantCastInQueue = false
        if (killc_approaches or wrath_approaches or crow_approaches) then
            moreImportantCastInQueue = true
        end

        if (power_overcap or moreImportantCastInQueue) then 
            return true
        end 
    end
end

function castMultishot()
    local count, duration, expirationTime = findAura("player", "Удар зверя")
    
    if (canCast(MULTISHOT)) then 
        if (not count) then
            return true
        end
        
        if (expirationTime - GetTime() < GCD_LAG ) then
            return true
        end
    end

end

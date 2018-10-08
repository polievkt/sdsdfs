--v1
--consts
GCD_LAG = 0.1
GCD = 1.34
DEBUFF_RENEW_THRESH = 2
FRENZY_EXPIRATION = 1.8
POWER_CAP = 90

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
TARGET = 'target'

function canCast()    
    local exists = UnitExists(TARGET)
    if (exists) then
            return true;
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

function barbedOvercap(spell)
    currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetSpellCharges(spell)
    if (currentCharges == maxCharges) then
        return true
    end

    if (currentCharges == 1 and (cooldownStart + cooldownDuration) - GetTime() < GCD ) then
        return true
    end

end

function spellCD(spell)
    local startTime, duration = GetSpellCooldown(spell)
    return startTime > 0 and (startTime+duration - GetTime()) or 0
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




function frenzyShouldBeRefreshedNextCast()

    local frenzyDuration = auraDuration(PET, FRENZY)
    local cd = spellCD(BARBED)

    --frenzy will expire soon
    if (frenzyDuration < 2) then
        --if there is a chance for successfull cast until its really gone
        if (frenzyDuration > cd + 0.2) then
            return true
        end
    end
end

function killcShouldBeNextCast()
    local cd = spellCD(KILLC)
    local realCD = cd - getGCDCD()
    --print(realCD)
    if (realCD < 0.5 ) then
        return true
    end

end

function getTHP()
    local hp = UnitHealth(TARGET)
    local hpMax = UnitHealthMax(TARGET)
    if (hp and hpMax) then
        return hp/hpMax
    else
        return 0
    end
end

function getGCDCD()
    return spellCD(COBRA)
end

--final cast bools
function castKillCommand()
    --allow window for barbed
    if (not frenzyShouldBeRefreshedNextCast() and canCast()) then
        local cd = spellCD(KILLC)
        --can immediately - why not?
        if (cd <= 0.2) then
            return true
        end

        if(killcShouldBeNextCast()) then
            return true
        end            
    end
end

function castBarbed()

    local cd = spellCD(BARBED)
    local realCD = cd - getGCDCD()

    --if barbed can be next spell
    if (canCast() and cd < 1.5) then

        local frenzyDuration = auraDuration(PET, FRENZY)

        if (frenzyShouldBeRefreshedNextCast()) then
            return true
        end

        --check if wrath on cd to utilize cd reduction?
        if (barbedOvercap(BARBED)) then
            return true
        end

        --no frenzy and wrath active
        local wrathDuration = auraDuration(PLAYER, WRATH)
        if (frenzyDuration == 0) then
            if (wrathDuration > 0) then
                return true
            end
        end
    end
end


function castChimaera()
    if (canCast() and not powerOvercap()) then

        local cd = spellCD(CHIMAERA)
        local realCD = cd - getGCDCD()

        if (not frenzyShouldBeRefreshedNextCast() and not killcShouldBeNextCast() and realCD <= 0.2 ) then
            return true
        end
    end
end

function castCrow()
    local thp = getTHP()

    local cd = spellCD(CROW)
    local realCD = cd - getGCDCD()

    if (canCast() and realCD < 0.2 and thp > 0.20) then
        return true
    end
end

function castWrath()
    local cd = spellCD(WRATH)
    local realCD = cd - getGCDCD()

    if (canCast() and realCD < 0.2) then
        return true
    end
end

function castAspect()
    local cd = spellCD(ASPECT)
    local realCD = cd - getGCDCD()

    if (canCast() and realCD < 0.2) then
        return true
    end

end

function castCobra()
    local wrathDuration = auraDuration(PLAYER, WRATH)
    local power = UnitPower(PLAYER)
    local power_overcap = (power >= 80) and true or false
    local wrathActive = wrathDuration > 0 and true or false   
    local killc_cd = spellCD(KILLC)
    local wrath_cd = spellCD(WRATH)

    if (canCast() and not frenzyShouldBeRefreshedNextCast() and power_overcap ) then
        return true
    end  

    if (canCast() and not frenzyShouldBeRefreshedNextCast() and not killcShouldBeNextCast()) then
        
        if (wrathActive or power_overcap) then


            if (killc_cd > 1.5 and power > 35) then
                return true
            end

        else

            --до гнева далеко
            local killc_approaches = (killc_cd < 1.3) and true or false
            local wrath_approaches = (wrath_cd < 10) and true or false

            if (not killc_approaches and not wrath_approaches) then
                return true
            end

        end
    end

end

function castMultishot()
    local power = UnitPower(PLAYER)
    local cd = spellCD(MULTISHOT)

    if (canCast()) then 
        local count, duration, expirationTime = findAura("player", "Удар зверя")

        if (not count) then
            return true
        end
        
        if (expirationTime - GetTime() < 1 ) then
            return true
        end
    end

end

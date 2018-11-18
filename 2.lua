--v17
--consts
GCD_LAG = 0.1
GCD = 1.24
DEBUFF_RENEW_THRESH = 2
FRENZY_EXPIRATION = 1.75
POWER_CAP = 85

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
    
    if (currentCharges == 1 and (cooldownStart + cooldownDuration) - GetTime() < GCD*1.5  ) then
        return true
    end
    
end

--remaining cd
function spellCD(spell)
    local startTime, duration = GetSpellCooldown(spell)
    if (startTime) then
        return startTime > 0 and (startTime+duration - GetTime()) or 0
    else 
        return 0
    end
    
end

--remaining duration
function auraDuration(unit, spell)
    local count, duration, expirationTime = findAura(unit, spell)
    if (count and count > 0) then 
        local result = expirationTime - GetTime()
        return result
    else
        return 0
    end
end

function frenzyShouldBeRefreshedNextCast()
    
    local frenzyDuration = auraDuration(PET, FRENZY)
    local cd = spellCD(BARBED)
    
    --frenzy will expire soon
    if (frenzyDuration > 0 and frenzyDuration < FRENZY_EXPIRATION) then
        --if there is a chance for successfull cast until its really gone
        if (frenzyDuration > cd + GCD_LAG) then
            return true
        end
    end
end

function killcShouldBeNextCast()
    local cd = spellCD(KILLC)
    local realCD = cd - getGCDCD()
    --print(realCD)
    if (realCD < GCD) then
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
    if (canCast()) then
        if(killcShouldBeNextCast()) then
            return true
        end            
    end
end

FRENZY_UP_AT = 0
function logFrenzy()
    local frenzyIsUp = auraDuration(PET, FRENZY) > 0 and true or false
    
    if (frenzyIsUp) then
        if (FRENZY_UP_AT == 0) then
            --frenzy just got up
            FRENZY_UP_AT = GetTime()
            print("Frenzy up at", FRENZY_UP_AT)
        else
            --frenzy already up
        end
        
    else
        if (FRENZY_UP_AT == 0) then
            --frenzy down and was down
        else
            --frenzy down and was up, just came down
            print("Frenzy down in", GetTime() - FRENZY_UP_AT)
            print("Frenzy down @", GetTime())
            FRENZY_UP_AT = 0
        end
    end
    
    
end


function castBarbed()
    --logFrenzy()
    local cd = spellCD(BARBED)
    local realCD = cd - getGCDCD()
    
    --if barbed can be next spell
    if (canCast()) then
        
        if (frenzyShouldBeRefreshedNextCast()) then
            return true
        end
        
        local frenzyDuration = auraDuration(PET, FRENZY)
        --check if wrath on cd to utilize cd reduction?
        if (barbedOvercap(BARBED) and not killcShouldBeNextCast()) then
            return true
        end
        
        --no frenzy and wrath active
        local wrathDuration = auraDuration(PLAYER, WRATH)
        if (frenzyDuration == 0) then
            if (wrathDuration > 0 and realCD < GCD_LAG) then
                return true
            end
        end
    end
end


function castChimaera()
    if (canCast() and not  (UnitPower(PLAYER) >= POWER_CAP)) then
        
        local cd = spellCD(CHIMAERA)
        local realCD = cd - getGCDCD()
        
        if (not frenzyShouldBeRefreshedNextCast() and not killcShouldBeNextCast() and realCD <= GCD_LAG ) then
            return true
        end
    end
end

function castCrow()
    local thp = getTHP()
    
    local cd = spellCD(CROW)
    local realCD = cd - getGCDCD()
    
    if (canCast() and realCD < GCD_LAG and thp > 0.20) then
        return true
    end
end

function castWrath()
    local cd = spellCD(WRATH)
    local realCD = cd - getGCDCD()
    
    if (canCast() and realCD < GCD_LAG) then
        return true
    end
end

function castAspect()
    local cd = spellCD(ASPECT)
    local realCD = cd - getGCDCD()
    
    if (canCast() and realCD < GCD_LAG) then
        return true
    end
    
end

function castCobra()
    local wrathDuration = auraDuration(PLAYER, WRATH)
    local power = UnitPower(PLAYER)
    local power_overcap = (power >= POWER_CAP) and true or false
    local wrathActive = wrathDuration > 0 and true or false   
    local killc_cd = spellCD(KILLC)
    local wrath_cd = spellCD(WRATH)
    
    if (canCast() and not frenzyShouldBeRefreshedNextCast() and not killcShouldBeNextCast()) then
        
        if (power_overcap) then
            return true
        end
        
        if (wrathActive ) then
            
            if (killc_cd > 1.5 and power > 35) then
                return true
            end
            
        else
            
            --до гнева далеко
            local killc_approaches = (killc_cd < 1.5) and true or false
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
        
        if (expirationTime - GetTime() < GCD ) then
            return true
        end
    end
    
end


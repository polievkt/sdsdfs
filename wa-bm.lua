--v17
--consts
GCD_LAG = 0.1
GCD = 1.24
DEBUFF_RENEW_THRESH = 2
FRENZY_EXPIRATION = 1.8
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

--####
--surv
--####
--v1

--sting_const
STING = 'Укус змеи'
VIPER_PROC = 'Яд гадюки'
CLIP = 'Подрезать крылья'
FIREWORKS = 'Фейерверк'
EAGLE = 'Дух орла'
FEROMON_BOMB = 'Феромоновая бомба'
UNSTABLE_BOMB = 'Нестабильная бомба'
SHRAPNEL_BOMB = 'Шрапнельная бомба'
COORDINATED = 'Согласованная атака'
POWER_COST_LAG = 3
STING_EXPIRATION = 3
CLIP_EXPIRATION = 3
SURV_POWER_CAP = 100 - (15 + POWER_COST_LAG)
FEROMON_BOMB_ENABLED = 0
UNSTABLE_BOMB_ENABLED = 1
SHRAPNEL_BOMB_ENABLED = 2

function debuffDuration(unit, spell)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitDebuff(unit, i);

        if (name == spell and expirationTime) then 
            local result = expirationTime - GetTime()
            return result
        end
    end
    return 0
end

function buffDuration(unit, spell)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(unit, i);

        if (name == spell and expirationTime) then 
            local result = expirationTime - GetTime()
            return result
        end
    end
    return 0
end

function inMelee(unit)
    if (IsSpellInRange(CLIP, unit) == 1) then
        return true
    end 
end

function targetInMelee()
    if (inMelee(TARGET)) then
        return true
    end 
end

--cast bools
function castSting()
    local sting_cost = 20 - POWER_COST_LAG
    local power = UnitPower(PLAYER)
    if (canCast() and power >= sting_cost) then
        local sting_debuff_duration = debuffDuration(TARGET, STING)
        --print(sting_debuff_duration)
        local sting_expires = (sting_debuff_duration < STING_EXPIRATION) and true or false
        
        local viper_proc_duration = buffDuration(PLAYER, VIPER_PROC)
        local sting_cd = spellCD(STING)
        local viper_proc_up = viper_proc_duration > sting_cd

        --print(sting_expires, viper_proc_up)
        if (sting_expires or viper_proc_up) then
            return true
        end
    end
end

function castClip()
    local clip_cost = 30 - POWER_COST_LAG
    local power = UnitPower(PLAYER)

    if (canCast() and power >= clip_cost and targetInMelee()) then
        local clip_duration = debuffDuration(TARGET, CLIP)
        local clip_expires = clip_duration < CLIP_EXPIRATION and true or false
        if (clip_expires) then
            return true
        end
    end
end

function castKillc()
    local killc_cd = spellCD(KILLC)
    local gcd = spellCD(FIREWORKS)
    local real_cd = killc_cd - gcd
    local power = UnitPower(PLAYER)
    
    if (real_cd < GCD_LAG and power < SURV_POWER_CAP and canCast()) then
        return true
    end
end

function castGoose()
    local goose_cost = 30 - POWER_COST_LAG
    local power = UnitPower(PLAYER)

    if (power >= goose_cost and canCast()) then
        local eagle_up =  buffDuration(PLAYER, EAGLE) > 0 and true or false
        if (targetInMelee() or eagle_up) then
            return true
        end
    end
end

function evalBomb()

    local f_start, f_duration, feromon_enabled = GetSpellCooldown(FEROMON_BOMB)
    local u_start, u_duration, unstable_enabled = GetSpellCooldown(UNSTABLE_BOMB)
    local s_start, s_duration, shrapnel_enabled = GetSpellCooldown(SHRAPNEL_BOMB)

    if (feromon_enabled) then return FEROMON_BOMB end
    if (unstable_enabled) then return UNSTABLE_BOMB end
    if (shrapnel_enabled) then return SHRAPNEL_BOMB end

end

function castBomb()
    local current_bomb = evalBomb()
    local currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetSpellCharges(current_bomb)
    local power = UnitPower(PLAYER)
    if ((currentCharges > 0 or  cooldownStart+cooldownDuration - GetTime() < GCD_LAG) and canCast()) then

        if (currentCharges > 1) then 
            return true
        end

        --bomb ready
        if (current_bomb == SHRAPNEL_BOMB and power > 60) then
            return true
        end

        local sting_debuff_duration = debuffDuration(TARGET, STING)
        local sting_expires = (sting_debuff_duration > 0 and sting_debuff_duration < STING_EXPIRATION*2) and true or false
        if (current_bomb == UNSTABLE_BOMB and sting_expires) then
            return true
        end

        if (current_bomb == FEROMON_BOMB and power < 30) then 
            return true
        end
    end

end

function castCoordinated()

    local coord_cd = spellCD(COORDINATED)
    local gcd = spellCD(FIREWORKS)
    local real_cd = coord_cd - gcd

    if (canCast() and real_cd <= GCD_LAG) then 
        return true
    end

end

function castCrow2()

    local cd = spellCD(CROW)
    local realCD = cd - spellCD(FIREWORKS)
    --print(realCD)

    if (canCast() and realCD < GCD_LAG ) then
        return true
    end
end

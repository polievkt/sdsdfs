---cast bools
TARGET = "target"
PLAYER = "player"
GARROTE = "Гаррота"
MUTILATE = "Расправа"
STEALTH = "Незаметность"
SUBTLEFUGE = "Увертка"
VANISH = "Исчезновение"
RUPTURE = "Рваная рана"
EXSANGUINATE = "Пускание крови"
ENVENOM = "Отравление"
ELABORATE = "Коварный план"
FIAL = "Алый фиал"
GCD = UnitPowerType("player") == 3 and (WA_GetUnitBuff("player",13750) and .8 or 1) or max(1.5/(1 + .01 * UnitSpellHaste("player")), WA_GetUnitBuff("player", 194249) and .67 or .75)
ENERGY_CAP = 150

--remaining cd
function spellCD(spell)
    local startTime, duration = GetSpellCooldown(spell)
    if (startTime) then
        return startTime > 0 and (startTime+duration - GetTime()) or 0
    else 
        return 0
    end
    
end

function elaborateDown()
    local duration = buffDuration(PLAYER, ELABORATE) > 0 and false or true
    return duration
end

function envenomDown()
    local duration = buffDuration(PLAYER, ENVENOM) > 0 and false or true
    return duration
end

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

function realCD(spell)
    local spell_cd = spellCD(spell)
    local gcd_cd = spellCD(MUTILATE)
    return spell_cd - gcd_cd
end

function comboPoints()
    return UnitPower(PLAYER, 4)
end

function comboPointsMax()
    return UnitPowerMax(PLAYER, 4)
end

function stealthUp()
    if (buffDuration(PLAYER, STEALTH) > 0) then return true end
    if (buffDuration(PLAYER, SUBTLEFUGE) > 0) then return true end
    if (buffDuration(PLAYER, VANISH) > 0) then return true end
end

function castGarrote()
    local points = comboPoints()
    local points_max = comboPointsMax()
    local points_deficit = points_max - points
    local cd = realCD(GARROTE)
    local dur = debuffDuration(TARGET, GARROTE)

    --overcap
    if (points_deficit == 0) then return false end

    --cd
    if (cd > 0) then return false end

    --already applied and will last long enought to waste duration
    if (dur > 6) then return false end

    --not applied or will end soon
    if (dur < 2) then return true end

end

function castRupture()
    local points = comboPoints()
    local points_max = comboPointsMax()
    local dur = debuffDuration(TARGET, RUPTURE)
    local no_elaborate = elaborateDown()
    local en = UnitPower(PLAYER, 3)
    local overcap = en >= ENERGY_CAP and true or false

    --no points
    if (points == 0) then return false end

    --already applied and will last long enought 
    if (dur > 7) then return false end

    --safe to reapply
    if (dur < 6 and points >= 4 and (no_elaborate or overcap) ) then return true end

    --will fall off soon - need to reapply fast
    if (dur < 1.5) then return true end

end

function castExsanguinate()

    local cd = realCD(EXSANGUINATE)
    local g_dur = debuffDuration(TARGET, GARROTE)
    local r_dur = debuffDuration(TARGET, RUPTURE)

    if (g_dur > 9 and r_dur > 20 and cd == 0) then return true end

end

function castEnvenom()
    local points = comboPoints()
    local points_max = comboPointsMax()
    local no_elaborate = elaborateDown()
    local no_envenom = envenomDown()
    local en = UnitPower(PLAYER, 3)
    local overcap = en >= ENERGY_CAP and true or false

    --other dump
    if (castRupture()) then return false end
    if (points_max-points > 1) then return false end
    
    if (overcap) then return true end
    --windows
    if (no_elaborate and no_envenom) then return true end

end


function castCrimson()
    local points = comboPoints()
    local points_max = comboPointsMax()
    local learned = GetTalentInfo(7, 3, 1)
    
    if (learned == false) then return false end

    --other dump
    if (castRupture()) then return false end
    if (points_max-points<=1) then return true end
end

function castMutilate()
    local points = comboPoints()
    local points_max = comboPointsMax()

    if (points_max-points>1) then return true end
end

function castVeer()
    local points = comboPoints()
    local points_max = comboPointsMax()

    if (points_max-points>1) then return true end
end

function castStorm()
    local points = comboPoints()
    local points_max = comboPointsMax()

    if (points_max-points>=1) then return true end
end


function castDispel()
    local d2 = spellCD("Волшебный поток")
    
    local dispel_ready = false
    if (d2 == 0) then
        dispel_ready = true
    end
    
    local smth_to_dispel = false
    
    for i = 0, 40 do
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, 
        nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, nameplateShowAll, timeMod, value1, value2, value3
        = UnitBuff(TARGET, i)

        if (isStealable ) then
            smth_to_dispel = true
        end
    end
    
    if (dispel_ready and smth_to_dispel) then
        return true
    end
    
end

function castFial()
    local cd = realCD(FIAL)
    local hp = UnitHealth(PLAYER)/UnitHealthMax(PLAYER)
    if (cd == 0 and hp < 0.7) then return true end
end



--shuriken toss
--super rapture over all
--don't override exg dots and other dots





https://yandex.ru/search/?text=%D0%B2%D0%B5%D0%BD%D0%BE%D0%BC%20%D1%84%D0%B8%D0%BB%D1%8C%D0%BC%202018&&lr=213
https://yandex.ru/search/?text=%D0%BE%D1%82%D0%BF%D1%83%D1%81%D0%BA%20%D0%B2%20%D0%BD%D0%B0%D1%80%D1%83%D1%87%D0%BD%D0%B8%D0%BA%D0%B0%D1%85%20%D1%84%D0%B8%D0%BB%D1%8C%D0%BC%202007&&lr=213
https://yandex.ru/search/?text=%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D0%B2%D1%8C%D1%8E%20%D1%81%20%D0%B1%D0%BE%D0%B3%D0%BE%D0%BC&&lr=213
бони и клайд сериал
чокнутая
семья по быстрому
грозовой перевал
ангел в америке

--setglobal("test", 1)
--print(test) -- 1 is printed
   

function calcTTL()
    local unitId = "target"
    local windowSize = 10 -- in seconds, 0 to disable
    
    local guid = UnitGUID(unitId)
    
    if (guid == nil) then
        return 0
    end

    local _, _, _, _, _, npcId, _ = strsplit("-",guid)
    local _, _, difficulty, _, _, _, _, _, _ = GetInstanceInfo()
    
    
    -- initialize
    if _G["__ttd"] == nil then _G["__ttd"] = {} end
    local ttd = _G["__ttd"]
    local display_string = ""
    local result = 100

    -- check state of unit
    if UnitIsDead(unitId) 
    or UnitHealth(unitId) == UnitHealthMax(unitId)
    then -- unit is dead or not damaged, record no data
        ttd[guid] = nil
        if windowSize > 0 then return 100
        else return 100 end
    elseif ttd[guid] == nil then -- unit is getting damage, but no data exists, create data
        ttd[guid] = {
            start = GetTime(),
            data = {}
        }
    elseif windowSize > 0 then -- only log data if sliding window is active
        ttd[guid]['data'][GetTime()] = UnitHealth(unitId)
        
        -- sliding window dps data
        local t_0 = GetTime()
        local hp_0 = UnitHealth(unitId)
        
        for time, health in pairs(ttd[guid]['data']) do
            if GetTime() - time > windowSize 
            then ttd[guid]['data'][time] = nil
            else
                if time <= t_0 
                then 
                    t_0 = time
                    hp_0 = health
                end
            end
        end
        
        -- sliding window dps
        local delta_hp = hp_0 - UnitHealth(unitId)
        local delta_t = GetTime() - t_0
        local dps = delta_hp / (delta_t)
        local sliding_time_to_die = UnitHealth(unitId) / dps
        
        --print("TTD10s = " .. sliding_time_to_die)
        
        if sliding_time_to_die == (1/0) 
        or sliding_time_to_die ~= sliding_time_to_die 
        or sliding_time_to_die < 0 
        then 
            display_string = "  ∞  "
            result = 100
        elseif sliding_time_to_die > (99 * 60  + 59) then
            display_string = "--:--" 
            result = 100
        else
            display_string = 
            format("%d:%0.2d", sliding_time_to_die / 60, sliding_time_to_die % 60)
            result = sliding_time_to_die
        end
        
        display_string = display_string  .. " | "
        
    end
    
    
    -- average dps since combat start
    local total_hp_loss = UnitHealthMax(unitId) - UnitHealth(unitId)
    local total_time = GetTime() - ttd[guid]['start']
    local average_dps =  total_hp_loss / total_time
    local average_time_to_die = UnitHealth(unitId) / average_dps
    
    --print("TTDAvg = " .. average_time_to_die)
    
    if average_time_to_die == (1/0) 
    or average_time_to_die ~= average_time_to_die 
    or average_time_to_die < 0 
    then 
        display_string = display_string .. "  ∞  "     
    elseif average_time_to_die > (99 * 60  + 59) then
        display_string = display_string .. "--:--" 
    else
        display_string =  display_string .. 
        format("%d:%0.2d", average_time_to_die / 60, average_time_to_die % 60)
    end
    
    --print("im here, will return", sliding_time_to_die)
    return result
end


---
--- MOCKS
---

function ResetMocks()
    PLAYER_POWER = {}
    -- energy
    PLAYER_POWER[3] = 0
    -- combo
    PLAYER_POWER[4] = 0
    TIME = os.time()
    PLAYER_BUFFS = {}
end

function UnitPower(_, ID)
    return PLAYER_POWER[ID]
end

function UnitBuff(unit, i)
    if not (unit == "PLAYER") then
        error("UNIT NOT PLAYER")
    end

    for k,v in pairs(PLAYER_BUFFS) do
        if (k == i) then
            local name = v[1]
            local duration = v[5]
            local expirationTime = v[6]
            return name, _, 1, _, duration, expirationTime, _, _, _, _ 
        end
    end

    return false
end

function buildBuff(name, duration, expirationTime)
    return {name, _, 1, _, duration, expirationTime, _, _, _, _ }
end

function GetTime()
    if (TIME == nil) then
        TIME = os.time()
        return GetTime()
    else 
        return TIME
    end
end

--
-- END OF MOCKS
--





--spells
local DICE = "Бросок костей"

--buffs
local BEARING = "Истинный азимут"
local PRECISION = "Беспощадная точность"
local SKULL = "Череп с костями"
local MELEE = "Великая битва"
local BROADSIDE = "Бортовой залп"
local THREASURE = "Зарытое сокровище"

local DICE_BUFFS = {BEARING, PRECISION, SKULL, MELEE, BROADSIDE, THREASURE}

local COST = {
    [DICE] = 25
}

local MIN_COMBO = 4

local PLAYER = "PLAYER"

function contains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end

function playerBuffs()
    local buffs = {}
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(PLAYER, i);

        if (name) then 
            table.insert(buffs, name)
        end
    end
    return buffs
end

function buffActualDuration(unit, spell)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(PLAYER, i);
        
        if (name == spell and expirationTime) then 
            local result = expirationTime - GetTime()
            return result
        end
    end
    return 0
end

function buffExpirationTime(unit, spell)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(unit, i);
        
        if (name == spell and expirationTime) then 
            return expirationTime
        end
    end

    return 0
end

function buffInitialDuration(unit, spell)
    for i = 0, 40 do
        local name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(unit, i);
        
        if (name == spell and duration) then 
            return duration
        end
    end

    return 0
end

function diceUp()
    local buffs = playerBuffs()
    local up = false

    for _, v in pairs(DICE_BUFFS) do
        if contains(buffs, v) then
            up = true
        end
    end
    
    return up
end

function rerollDice()
    if not (diceUp()) then 
        return false
    end

    local melee_dur = buffActualDuration(PLAYER, MELEE)
    local precision_dur = buffActualDuration(PLAYER, PRECISION)

    if (precision_dur == 0 and melee_dur == 0) then
        return true
    end
    return false
end

function pandemicDiceReady()
    local retval = false

    for _, buff in pairs(DICE_BUFFS) do
        local dur = buffInitialDuration(PLAYER, buff)
        local exp = buffExpirationTime(PLAYER, buff)
        local remain = exp - GetTime()

        if (dur > 0) then
            local pct = remain / dur
            if (pct < 0.3) then
                return true
            end
        end 
    end
    return retval
end

function comboPoints()
    return UnitPower(PLAYER, 4)
end

function energy()
    return UnitPower(PLAYER, 3)
end

function doDice()
    if comboPoints() < MIN_COMBO then
        return false
    end

    if energy() < COST[DICE] then 
        return false 
    end

    if diceUp() then
        if (rerollDice() and pandemicDiceReady()) then
            return true
        end

        return false
    else
        return true
    end

    return false
end



---
--- TESTS
---

function test_contains()
    local t = {}
    assert(not contains(t, "FOOBAR"))
    t[1] = "FOOBAR"
    assert(contains(t, "FOOBAR"))
end

function test_buildBuff()
    ResetMocks()

    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    name, _, count, _, duration, expirationTime, _, _, _, _  = UnitBuff(PLAYER, 1)

    assert(name == "FOOBAR")
    assert(count == 1)
    assert(duration == 10)

end

function test_playerBuffs()
    ResetMocks()
    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    
    assert(contains(playerBuffs(), "FOOBAR"))

end

function test_buffActualDuration()
    ResetMocks()
    assert(buffActualDuration(PLAYER, "FOOBAR") == 0)

    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(buffActualDuration(PLAYER, "FOOBAR") == 9)
end

function test_buffInitialDuration()
    ResetMocks()
    assert(buffInitialDuration(PLAYER, "FOOBAR") == 0)

    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(buffInitialDuration(PLAYER, "FOOBAR") == 10)
end

function test_buffExpirationTime()
    ResetMocks()
    assert(buffExpirationTime(PLAYER, "FOOBAR") == 0)

    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(buffExpirationTime(PLAYER, "FOOBAR") == TIME+9)
end

function test_diceUp()
    ResetMocks()
    -- no buffs
    assert(not diceUp())

    -- not dice buff 
    local buff = buildBuff("FOOBAR", 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(not diceUp())

    -- dice buff
    local buff = buildBuff(THREASURE, 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(diceUp())

    local buff = buildBuff(PRECISION, 10, TIME)
    table.insert(PLAYER_BUFFS, buff)
    assert(diceUp())
end

function test_rerollDice()
    ResetMocks()
    --nothing to reroll
    assert(not rerollDice())
    --dice buff but reroll
    local buff = buildBuff(THREASURE, 10, TIME)
    table.insert(PLAYER_BUFFS, buff)
    assert(rerollDice())
    -- don't reroll, got melee
    local buff = buildBuff(PRECISION, 10, TIME+100)
    table.insert(PLAYER_BUFFS, buff)
    assert(not rerollDice())
end

function test_pandemicDiceReady()
    ResetMocks()
    assert(not pandemicDiceReady())
    --will end sooner than 0.3
    local buff = buildBuff(THREASURE, 10, TIME+2)
    table.insert(PLAYER_BUFFS, buff)
    assert(pandemicDiceReady())
    --will end later than 0.3
    ResetMocks()
    local buff = buildBuff(THREASURE, 10, TIME+4)
    table.insert(PLAYER_BUFFS, buff)
    assert(not pandemicDiceReady())
    --assert(false)
end

function test_doDice()
    -- Fresh: should not be active
    ResetMocks()
    assert(not doDice())
    
    -- Got energy
    PLAYER_POWER[3] = 120
    assert(not doDice())
    
    -- Got combo
    PLAYER_POWER[4] = 4
    assert(doDice())
    
    -- Got dice up, long duration, no reroll
    ResetMocks()
    PLAYER_POWER[3] = 120
    PLAYER_POWER[4] = 4
    local buff = buildBuff(THREASURE, 10, TIME+9)
    table.insert(PLAYER_BUFFS, buff)
    assert(not doDice())

    -- Short duration, can fish
    ResetMocks()
    PLAYER_POWER[3] = 120
    PLAYER_POWER[4] = 4
    local buff = buildBuff(THREASURE, 10, TIME+2)
    table.insert(PLAYER_BUFFS, buff)
    assert(doDice())

    -- Short duration but usefull buffs
    ResetMocks()
    PLAYER_POWER[3] = 120
    PLAYER_POWER[4] = 4
    local buff = buildBuff(MELEE, 10, TIME+2)
    table.insert(PLAYER_BUFFS, buff)
    assert(not doDice())

end

test_contains()
test_playerBuffs()
test_buildBuff()
test_buffActualDuration()
test_buffInitialDuration()
test_buffExpirationTime()
test_diceUp()
test_rerollDice()
test_pandemicDiceReady()
test_doDice()


--TODO:
--1. keep an eye for precision requirement @ pistol
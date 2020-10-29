-- https://forum.zenbot.gg/index.php?/profile/16-probably_retarded/
-- Load internal zenbot modules to communicate with the API
local orb = module.internal("orb")
local ts = module.internal("ts")
local pred = module.internal("pred")
local damage = module.internal("damage")

-- Tiamat slot variable, it could be in any of the 6 item slots
-- we'll need to know this later for tiamat AA resets
local tiamat

-- Variables for storing spells info, this could be used for: prediction, you can also store
-- things like skill names, mana costs, etc. here
local Q, W, E, R

Q = {}
W = {}
E = {}
R = {}

W.data = {range = 850} -- Prediction input data
E.data = {range = 650, delay = 0, radius = 160, speed = 900, aoe = true} -- Trynda's E is an AOE spell, it's radius is 160, you can cast it at max 650 range and it deals AoE damage

-- Make a menu, check docs for more informations about this
local menu = menu(header.id, 'Obama Tryndamere')
menu:set('texture', player.squareSprite)

menu:header("mnu", "please, disable tiamat")
menu:header("mnu", "in activator combo")

menu:menu("combo", "Combo")
menu.combo:boolean("wComboUse", "Use W", true)
menu.combo:boolean("wComboWaitForE", "Use if E on CD", true)
menu.combo:boolean("eComboUse", "Use E", true)
menu.combo:slider("eComboDistance", "If enemy is further than [x]", 300, 300,
                  600, 5)
menu.combo:boolean("eDontUnderTower", "Don't E under enemy tower")

menu:menu("laneclear", "Lane/jungle clear")
menu.laneclear:menu('menuEclear', 'E')
menu.laneclear.menuEclear:boolean("eLaneUse", "Use in LaneClear", true)
menu.laneclear.menuEclear:slider("eLaneUseCreeps",
                                 "Use when will hit [x] creeps", 3, 1, 6, 1)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("eKs", "Use E", true)

menu:menu("autouse", "Auto-use")
menu.autouse:boolean("qAutoUse", "Use Q when low health", true)
menu.autouse:boolean("qAutoUseUltCd", "Use Q only when R is on cooldown")
menu.autouse:slider("qAutoSlider", "Use Q when %HP < [x]", 10, 100, 1)
menu.autouse:slider("qAutoFurySlider", "Use Q when fury > [x]", 10, 100, 0)
menu.autouse:boolean("rLowHp", "Autouse R", true)
menu.autouse:slider("rHpSLider", "Use when %hp < [x]", 10, 100, 1)

menu:menu("D", "Drawings", "\xef\x87\xbc")
menu.D:menu("DW", "(W) Mocking Shout")
menu.D.DW:set("texture", player:spellSlot(1).sprite)
menu.D.DW:boolean("drawWrange", "Draw range", true)
menu.D.DW:color("wDrawColor", "Color", 0, 255, 0, 150)

menu.D:menu("DE", "(E) Spinning Slash")
menu.D.DE:set("texture", player:spellSlot(2).sprite)
menu.D.DE:boolean("drawErange", "Draw range", true)
menu.D.DE:color("eDrawColor", "Color", 0, 255, 0, 150)

-- Function for calculating if spell of a passed index can
-- kill given target, if you want to change this up for
-- other characters, you will have to recalculate the damage
-- @param target target of the spell
-- @param spellIndex index of the spell, 0-3, 0 being Q and 3 being R
-- @return boolean depending if spell can kill a player
function canExecute(target, spellIndex)
    if (spellIndex == 2) then
        local e_damage = -- you subtract 1 from spell level to get the correct damage level, because lv1 is just base spell damage
        (80 + (30 * (player:spellSlot(2).level - 1))) +
            (player.totalBonusAbilityPower * 0.8) + -- tryndamere's E scales with 80% AP
            (player.totalBonusAttackDamage * 1.3) -- tryndamere's E scales with 130% AD
        if (target.health >= damage.calc(player, target, e_damage, 0, 0)) then
            return false
        else
            return true
        end
    end
end

-- Function returns whether a spell is true
-- it's just a cheat code for faster coding
-- @param spellIndex spell's slot, 0-3, 0 being Q and 3 being R
-- @return true/false whether spell is off cooldown
local function isSpellReady(spellIndex)
    if (player:spellSlot(spellIndex).state == 0) then return true end
    return false
end

-- Another cheat code for faster drawing range circles
-- absolutely unnecessary as well
-- @param range radius of the spell from player character center
-- @color color just color lol
local function drawRangeCircle(range, color)
    graphics.draw_circle(player.pos, range, 5, color)
end

-- Function called by draw_world callback, there it's used
-- to draw range of skills
local function drawEvent()
    if menu.D.DW.drawWrange:get() then -- check if user has enabled drawing W range in the menu
        drawRangeCircle(W.data.range, menu.D.DW.wDrawColor:get()) -- call the function created above, pass range from the table and color from imgui colorpicker
    end
    if menu.D.DE.drawErange:get() then
        drawRangeCircle(E.data.range, menu.D.DE.eDrawColor:get())
    end
end
cb.add(cb.draw_world, drawEvent) -- Callback from Zenbot's API

-- cb.tick is called very frequently ingame, so this is a good
-- place to look if player is using Orbwalker - as in, holding
-- combo, laneclear etc. buttons
local function mode()
    if orb.core.mode() == OrbwalkingMode.Combo then -- Condition, yet again thanks to zenbots API
        Combo() -- Call combo function, the entire function could also be implemented here, but for clarity and cleaniness it's good practice to leave it as is
    elseif orb.core.mode() == OrbwalkingMode.LaneClear then
        LaneClear()
    end
end
cb.add(cb.tick, mode)

-- [[ Modes ]]

-- Combo() will be getting called every other tick if player is using Combo orbwalker mode
function Combo()
    for target in ts.get_targets() do -- Loop through targets from target selector, first one is the one you are looking for
        if (target) then -- a check to make sure that that object really exists

            --[[

            this is where really the most basic logic of your combo happens,
            you can decide spells order, what conditions have to be met in
            order to cast spells and much more

            ]]

            if menu.combo.eComboUse:get() and isSpellReady(2) and -- checking whether player has 'Use E in Combo' option activated, and whether spell of index 3 (E) is ready
                (target:dist() <= menu.combo.eComboDistance:get()) then -- checking if target is within E distance
                if menu.combo.eDontUnderTower:get() and
                    target.pos:isUnderEnemyTurret() then -- don't attack if target is under enemy tower and has that option enabled
                    return
                else
                    player:castSpell("pos", SpellSlot.E, target) -- cast of the spell, first argument is 'pos'
                    -- 'pos' is simply casting spell to a given position, there are some other modes of casting spells:
                    -- 'obj' is when the spell is simply point&click, so normally hover over the character, no skillshots involved eg: Cho'gaths R or Malzahar's R
                    -- 'self' is for self buffs, an example is Kayle's W ability
                    -- second is SpellSlot.E, which is self explanatory, it's just for zenbot to know that you want to cast E :)
                    -- the last one is target - for readability this could be exchanged with *target.pos*
                end
            end

            if menu.combo.wComboUse:get() and isSpellReady(1) then
                if (player:isInAutoAttackRange(target)) then -- another useful built-in function, it will check whether an object X is within auto attack range of object Y
                    -- in that case, if our *target* is within AA range of player

                    player:castSpell("self", SpellSlot.W) -- other type of a cast than with E, this is pretty much a "click&it happens"
                    -- we want to cast W immediately if player is within AA range of an enemy to reduce their AD
                end

                if (menu.combo.wComboWaitForE:get() and not isSpellReady(2)) then
                    if not target:isFacing(player.pos) and target:dist() >= 325 then
                        -- another 'simple' logic math things, this is: if target is not facing Tryndamere, and is further than 325 units away
                        -- W will be cast, because it slows enemies - very simple things
                        player:castSpell("self", SpellSlot.W)
                    end
                else
                    if not target:isFacing(player.pos) and isSpellReady(1) and
                        target:dist() >= 325 then
                        player:castSpell("self", SpellSlot.W)
                    end
                end
            end
        end
    end
end

function LaneClear()

    -- We don't want the script to use spells when Skill farming is disabled (default key is M)
    if not orb.farm.is_spell_clear_active() then return end -- so if laneclear is inactive, just abandon doing anything else

    if (menu.laneclear.menuEclear.eLaneUse:get() and isSpellReady(2)) then
        for minion in
            objManager.minions { -- Hopefully whoever reads this, has a basic grasp of loops, objManager is another zenbot function, it lists all enemies into a table that 'for' iterates through
                exclude_team = player.team, -- you can use some interesting filters here, exclude your own team so you only get neutral/enemy minions/monsters
                dist = E.data.range, -- set the maximum distance to not fill the table up too much with unwanted results
                valid_target = true
            } do

            -- prediction function              making use of our previous skill data tables, second argument is the object that we want to predict position of
            local output = pred.linear.get_prediction(E.data, minion)

            -- prediction returns nothing when it fails when trying to find a path for a spell to hit
            -- so it has to be checked to avoid possible errors
            if output and minion.isNeutral and isSpellReady(2) then -- also because this is for clearing the jungle, 'if the minion is neutral' is all it takes to spin on him
                player:castSpell("pos", 2, minion)
            end

            if output and #output.aoeObjects + 1 > -- because we want to hit more than one minion depending on user settings ('#' before variable just counts length of the table)
                menu.laneclear.menuEclear.eLaneUseCreeps:get() and
                isSpellReady(2) then
                player:castSpell("pos", 2, output.endPos) -- same as ever
            end
        end
    end
end

-- As explained previously, cb.tick gets called very often therefore
-- it's a good place to check if someone can be executed/KSed
function killSteal()
    if isSpellReady(2) and menu.killsteal.eKs:get() then
        for enemy in
            objManager.heroes { -- again objManager, this time it loops through heroes
                team = TEAM_ENEMY, -- filter: that are only from enemy team
                dist = E.data.range, -- within E range
                valid_target = true -- are an actual valid target
            } do
            if canExecute(enemy, 2) and not enemy.isInvulnerable and -- usage of the canExecute function, along with a few additional checks
                not enemy.willReviveOnDeath and isSpellReady(2) and enemy.canDie then -- that the targeted enemy can really be killed and isn't protected by things like Kindred R
                player:castSpell('pos', 2, enemy)
            end
        end
    end
end
cb.add(cb.tick, killSteal)

-- There are things that will be checked against each tick
function autoSpells()
    -- automatically use Ultimate before death
    if player.canDie and isSpellReady(3) and menu.autouse.rLowHp:get() then -- if player isn't protected by things like Zilean R, Kindred R
        if (player.health / player.maxHealth * 100. <= -- also some basic math to check whether current HP% is lower than the one provided in the menu
            menu.autouse.rHpSLider:get()) or damage.predict(player, 1) < 100 then -- damage.predict is for incoming damage in the next 1 second, if it will take the player to lower than 100 hp, just cast R
            player:castSpell('self', 3) -- 'self' cast
        end
    end

    if isSpellReady(0) and menu.autouse.qAutoUse:get() and -- automatical Q casting, based on amount of fury
        (player.health / player.maxHealth * 100. <=
            menu.autouse.qAutoSlider:get()) and
        (player.mana >= menu.autouse.qAutoFurySlider:get()) then
        if (menu.autouse.qAutoUseUltCd:get() and not isSpellReady(3)) then
            player:castSpell('self', 0)
        end
        if not menu.autouse.qAutoUseUltCd:get() then
            player:castSpell('self', 0)
        end
    end
end
cb.add(cb.tick, autoSpells)

-- Usage of the previous function, calling it every other _fast_ tick
-- is not very important, because no one ever quicksells/quickbuys tiamts
-- within milliseconds
local function updateTiamat()
    local inv = {} -- a new table to store everything from player's /inventory/
    for i = 6, 12, 1 do
        local t = player:spellSlot(i)
        if t then inv[#inv + 1] = t end -- save item to slot
    end
    if inv then -- if there were ANY items found at all
        for i = 1, #inv, 1 do -- loop through that new table
            local item = inv[i]
            if item and item.name:find("Cleave") then -- if there's an item that has 'Cleave' in it (internal item names can differ from what you see in shop)
                tiamat = item -- set tiamat to a variable we created earlier
                break
            end
        end
    end

end
cb.add(cb.slow_tick, updateTiamat)

-- Last function, it's called by a self-explanatory callback after_attack
-- you can just choose what will happen after an auto attack
local function aaReset(target)
    if tiamat and orb.core.mode() == OrbwalkingMode.Combo or orb.core.mode() ==
        OrbwalkingMode.LaneClear and tiamat.state == SpellState.Ready and target then
        if (orb.core.mode() == OrbwalkingMode.LaneClear and target.isNeutral) then
            player:castSpell("self", tiamat.slot) -- Cast tiamat on 'self'
        elseif (orb.core.mode() == OrbwalkingMode.Combo) then
            player:castSpell("self", tiamat.slot)
        end
    end
end
cb.add(cb.after_attack, aaReset)

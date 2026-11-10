-- WoodScraps in-game test (pzt). Installed only into the test env (pzt.conf TEST_FILES).
-- Each case empties the inventory, adds items, checks HandcraftLogic:canPerformCurrentRecipe() and,
-- for cases that should work, crafts through the inventory context-menu path (ISInventoryPaneContextMenu.OnNewCraft)
-- and checks the resulting item counts.
WoodScrapsTest = WoodScrapsTest or {}
local T = WoodScrapsTest
T.pass, T.fail = 0, 0
-- ids per WoodScraps_SplinterN list in WoodScraps_recipes.txt (tools/gen_recipes.py prints them)
T.listSize = { WoodScraps_Splinter1 = 18, WoodScraps_Splinter2 = 5, WoodScraps_Splinter5 = 6,
    WoodScraps_Splinter7 = 8, WoodScraps_Splinter10 = 7 }

local function log(m) print("[WoodScrapsTest] " .. m) end
local function ok(cond, m)
    if cond then T.pass = T.pass + 1; log("OK " .. m)
    else T.fail = T.fail + 1; PZTest.fail("[WoodScrapsTest] " .. m) end
end

local function inv() return getPlayer():getInventory() end
local function count(t) return inv():getCountTypeRecurse(t) end
local function clear()
    local p = getPlayer()
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    inv():removeAllItems()
end
local function add(t, n)
    local last
    for _ = 1, (n or 1) do last = inv():AddItem(t) end
    return last
end

local function canDo(recipeName, item)
    local recipe = getScriptManager():getCraftRecipe(recipeName)
    if not recipe then return false, "no recipe" end
    local p = getPlayer()
    local logic = HandcraftLogic.new(p, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(p, 2))
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(p))
    logic:setRecipeFromContextClick(recipe, item)
    return logic:canPerformCurrentRecipe(), recipe
end

-- splitting needs no skill: every case below the press cases runs at Woodwork 0
function T.wood(level) getPlayer():setPerkLevelDebug(Perks.Woodwork, level) end

-- case: {name, setup() -> context item, recipe, expect = true/false, check = {type = count}}
local cases = {
    { "press at Woodwork 4: not allowed", function() T.wood(4); add("Base.Hammer"); return add("Base.Splinters", 15) end,
      "WoodScraps_PressPlank", false },
    { "press 15 splinters + hammer -> plank", function() T.wood(5); add("Base.Hammer"); return add("Base.Splinters", 15) end,
      "WoodScraps_PressPlank", true, { ["Base.Plank"] = 1, ["Base.Splinters"] = 0, ["Base.Hammer"] = 1 } },
    { "press with mallet", function() add("Base.WoodenMallet"); return add("Base.Splinters", 15) end,
      "WoodScraps_PressPlank", true, { ["Base.Plank"] = 1 } },
    { "press 14 splinters: not allowed", function() add("Base.Hammer"); return add("Base.Splinters", 14) end,
      "WoodScraps_PressPlank", false },
    { "press without hammer: not allowed", function() return add("Base.Splinters", 15) end,
      "WoodScraps_PressPlank", false },
    { "twigs by hand -> 1 splinter", function() T.wood(0); return add("Base.Twigs") end,
      "WoodScraps_BreakTwigs", true, { ["Base.Splinters"] = 1, ["Base.Twigs"] = 0 } },
    { "twigs bundle -> 12 splinters", function() return add("Base.TwigsBundle") end,
      "WoodScraps_BreakTwigsBundle", true, { ["Base.Splinters"] = 12, ["Base.TwigsBundle"] = 0 } },
    { "wooden fork + knife -> 1", function() add("Base.KitchenKnife"); return add("Base.WoodenFork") end,
      "WoodScraps_Splinter1", true, { ["Base.Splinters"] = 1, ["Base.WoodenFork"] = 0, ["Base.KitchenKnife"] = 1 } },
    { "smoking pipe + knife -> 1", function() add("Base.KitchenKnife"); return add("Base.SmokingPipe") end,
      "WoodScraps_Splinter1", true, { ["Base.Splinters"] = 1, ["Base.SmokingPipe"] = 0 } },
    { "scrap wood + axe -> 5", function() add("Base.Axe"); return add("Base.UnusableWood") end,
      "WoodScraps_Splinter5", true, { ["Base.Splinters"] = 5, ["Base.UnusableWood"] = 0 } },
    { "broken plank + saw -> 5", function() add("Base.Saw"); return add("Base.Plank_Broken") end,
      "WoodScraps_Splinter5", true, { ["Base.Splinters"] = 5, ["Base.Plank_Broken"] = 0 } },
    { "baseball bat + knife -> 10", function() add("Base.KitchenKnife"); return add("Base.BaseballBat") end,
      "WoodScraps_Splinter10", true, { ["Base.Splinters"] = 10, ["Base.BaseballBat"] = 0 } },
    { "baseball bat without tool: not allowed", function() return add("Base.BaseballBat") end,
      "WoodScraps_Splinter10", false },
    { "medium handle -> 2 (cap)", function() add("Base.KitchenKnife"); return add("Base.Handle") end,
      "WoodScraps_Splinter2", true, { ["Base.Splinters"] = 2, ["Base.Handle"] = 0 } },
}

-- every item named in the mod's recipes must exist (a typo or a removed vanilla id drops silently)
local function checkScripts()
    local names = { "WoodScraps_BreakTwigs", "WoodScraps_BreakTwigsBundle", "WoodScraps_PressPlank",
        "WoodScraps_Splinter1", "WoodScraps_Splinter2", "WoodScraps_Splinter5", "WoodScraps_Splinter7", "WoodScraps_Splinter10" }
    for _, n in ipairs(names) do
        local r = getScriptManager():getCraftRecipe(n)
        ok(r ~= nil, "recipe loaded " .. n)
        if r then
            ok(r:getTranslationName() ~= n, "translated " .. n .. " = " .. tostring(r:getTranslationName()))
            -- the first input is the wood list; its size must match the script (unknown ids are dropped)
            local items = r:getInputs():get(0):getPossibleInputItems()
            local want = T.listSize[n] or 1
            ok(items:size() == want, n .. " wood inputs " .. items:size() .. " (want " .. want .. ")")
        end
    end
end

T.i, T.phase, T.wait = 0, "next", 0

local function verify(c)
    for t, n in pairs(c[5] or {}) do
        ok(count(t) == n, c[1] .. ": " .. t .. " = " .. count(t) .. " (want " .. n .. ")")
    end
end

function WoodScrapsTest.start()
    if T.started then PZTest.fail("WoodScrapsTest already ran in this game; pzt stop, then run again"); return end
    T.started = true
    getPlayer():setGodMod(true)
    checkScripts()
    log("start")
end

function WoodScrapsTest.tick()
    if T.phase == "next" then
        T.i = T.i + 1
        local c = cases[T.i]
        if not c then T.phase = "done"; return end
        clear()
        local item = c[2]()
        local can = canDo(c[3], item)
        ok(can == c[4], c[1] .. ": canPerform = " .. tostring(can))
        if can and c[4] then
            ISInventoryPaneContextMenu.OnNewCraft(item, getScriptManager():getCraftRecipe(c[3]), getPlayer():getPlayerNum(), false)
            T.phase, T.wait = "crafting", 0
        end
    elseif T.phase == "crafting" then
        T.wait = T.wait + 1
        local queue = ISTimedActionQueue.getTimedActionQueue(getPlayer())
        local busy = queue and queue.queue and #queue.queue > 0
        if T.wait == 10 and busy then
            log("slow: paused=" .. tostring(isGamePaused()) .. " speed=" .. tostring(getGameSpeed())
                .. " action=" .. tostring(queue.queue[1] and queue.queue[1].Type) .. " frame=" .. tostring(getTimestampMs()))
            PZTest.shot("slow" .. T.i)
        end
        if not busy then
            verify(cases[T.i]); T.phase = "next"
        elseif T.wait > 60 then
            ok(false, cases[T.i][1] .. ": craft did not finish"); ISTimedActionQueue.clear(getPlayer()); T.phase = "next"
        end
    end
end

-- keeps the harness script running until the test is done (each poll is one tick of the test)
function WoodScrapsTest.poll()
    if T.phase == "done" then
        PZTest.log("WoodScrapsTest pass " .. T.pass .. " fail " .. T.fail)
        return
    end
    WoodScrapsTest.tick()
    PZTest.step("wait 30")
    PZTest.step("lua WoodScrapsTest.poll()")
end

-- ProbablyEngine Rotation Packager
-- NO CARRIER's Marksman Hunter Rotation

local function dynamicEval(condition, spell)
  if not condition then return false end
  return ProbablyEngine.dsl.parse(condition, spell or '')
end

local onLoad = function()
  ProbablyEngine.toggle.create('aspect', 'Interface\\Icons\\ability_mount_jungletiger', 'Auto Aspect', 'Automatically switch aspect when moving and not in combat')
  ProbablyEngine.toggle.create('md', 'Interface\\Icons\\ability_hunter_misdirection', 'Auto Misdirect', 'Automatially Misdirect when necessary')
  ProbablyEngine.toggle.create('dpstest', 'Interface\\Icons\\inv_misc_pocketwatch_01', 'DPS Test', 'Stop combat after 5 minutes in order to do a controlled DPS test')
  ProbablyEngine.toggle.create('autotarget', 'Interface\\Icons\\ability_hunter_snipershot', 'Auto Target', 'Automatically target the nearest enemy when target dies or does not exist')

  NOC.BaseStatsTableInit()

  C_Timer.NewTicker(0.25, (
      function()
        if ProbablyEngine.config.read('button_states', 'MasterToggle', false) then
          NOC.BaseStatsTableUpdate()
        end
      end),
  nil)
end

local ooc = {
  -- Out of combat
  { "pause","player.buff(5384)" }, -- Pause for Feign Death

  { "2641", { "pet.exists", "talent(7,3)" }}, -- Dismiss Pet
  { "982", { "pet.dead", "!talent(7,3)" }}, -- Revive Pet
  { "136", { "pet.health <= 90", "pet.exists", "!pet.dead", "!pet.buff(136)", "!talent(7,3)" }}, -- Mend Pet

  { "Aspect of the Cheetah", { "!player.buff(Aspect of the Cheetah)", "toggle.aspect" }},

  -- Keep trap launcher set
  { "77769", "!player.buff(77769)" },

  { "82939", "modifier.lalt", "ground" }, -- Explosive Trap
  { "82941", "modifier.lalt", "ground" }, -- Ice Trap
}

local aoe = {
  { "Glaive Toss", "modifier.enemies >= 3" },
  { "Powershot", "player.timetomax > 2.5" },
  { "Barrage" },
}

local careful_aim = {
  -- AoE
  { aoe, { "toggle.multitarget", "modifier.enemies >= 2" }},
  -- ST
  { "Aimed Shot" },
  --{ "Focusing Shot", { "!player.moving", function() return ((50 + dynamicEval("player.spell(152245).regen")) < dynamicEval("player.focus.deficit")) end }},
  { "Focusing Shot", { "!player.moving", "player.focus.deficit > 55" }},
  { "Steady Shot" },
}

local combat = {
  -- Combat
  { "pause", "modifier.lshift" },
  { "pause","player.buff(5384)" }, -- Pause for Feign Death

  { "/cancelaura Aspect of the Cheetah", { "!player.glyph(Aspect of the Cheetah)", "player.buff(Aspect of the Cheetah)" }},

  { "/stopcasting\n/stopattack\n/cleartarget\n/stopattack\n/cleartarget\n/petpassive", { "player.time >= 300", "toggle.dpstest" }},

  -- AutoTarget
  { "/targetenemy [noexists]", { "toggle.autotarget", "!target.exists" } },
  { "/targetenemy [dead]", { "toggle.autotarget", "target.exists", "target.dead" } },

  -- Pet
  {{
    { "883", { "!pet.dead", "!pet.exists" }}, -- Call Pet 1
    { "55709", "pet.dead" }, -- Heart of the Phoenix (55709)
    { "982", "pet.dead" }, -- Revive Pet
  }, "!talent(7,3)" },

  { "82939", "modifier.lalt", "ground" }, -- Explosive Trap
  { "82941", "modifier.lalt", "ground" }, -- Ice Trap

  { "109248" , "modifier.lcontrol", "ground" }, -- Binding Shot

  -- Stop flamethrower in Brackenspore
  { "/click ExtraActionButton1", { "player.buff(163322)" }},
  -- Feign Death for Infesting Spores when >= 6
  { "5384", "player.debuff(163242).count >= 6" },
  -- TODO: Add Feign Death for Iron Maiden's mechanic

  -- Interrupt(s)
  { "147362", "target.interruptAt(50)" }, -- Counter Shot at 50% cast time left
  { "19577", "target.interruptAt(30)" }, -- Intimidation at 30% cast time left
  { "19386", "target.interruptAt(30)" }, -- Wyrven Sting at 30% cast time left

  -- Survival
  { "109304", "player.health < 50" }, -- Exhiliration
  { "Deterrence", "player.health < 10" }, -- Deterrence as a last resort
  { "#109223", "player.health < 40" }, -- Healing Tonic
  { "#5512", "player.health < 40" }, -- Healthstone

  { "#109223", "player.health < 40" }, -- Healing Tonic
  { "136", { "pet.health <= 75", "pet.exists", "!pet.dead", "!pet.buff(136)", "!talent(7,3)" }}, -- Mend Pet

  -- Misdirect to focus target or pet when threat is above a certain threshhold
  {{
   { "34477", { "focus.exists", "!player.buff(35079)", "target.threat > 60" }, "focus" },
   { "34477", { "pet.exists", "!pet.dead", "!player.buff(35079)", "!focus.exists", "target.threat > 85", "!talent(7,3)" }, "pet" },
  }, "toggle.md", },

  -- Master's Call when stuck
  {{
    { "53271", "player.state.stun" },
    { "53271", "player.state.root" },
    { "53271", { "player.state.snare", "!player.debuff(Dazed)" }},
    { "53271", "player.state.disorient" },
  }, { "!talent(7,3)", "pet.exists" }},

  -- Wrap the entire block in an 'immuneEvents' check
  {{
    -- Cooldowns
    {{
      { "Stampede", "player.proc.any" },
      { "Stampede", "player.hashero" },
      { "A Murder of Crows" },
      { "Rapid Fire" },
      { "Lifeblood" },
      { "Berserking" },
      { "Blood Fury" },
      { "#trinket1" },
      { "#trinket2" },
    }, "modifier.cooldowns" },

    { "Tranquilizing Shot", { "target.dispellable(Tranquilizing Shot)", "!target.cc" }, "target" },

    -- Shared
    { "Kill Shot" },
    { "Chimaera Shot" },

    -- Careful Aim
    { careful_aim, "target.health >= 80" },
    { careful_aim, "player.buff(Rapid Fire)" },

    {{
      { "A Murder of Crows", "target.health.actual < 200000" },

      --{ "Dire Beast", { function() return ((dynamicEval("player.spell(120679).regen") + dynamicEval("player.spell(19434).regen")) < dynamicEval("player.focus.deficit")) end }},
      { "Dire Beast", "player.timetomax > 3" },

      { "Glaive Toss" },
      { "Powershot", "player.timetomax > 2.5" },
      { "Barrage" }, -- Do we really want this in ST? May want to put on a toggle

      { "Steady Shot", "player.timetomax > player.spell(Rapid Fire).cooldown" },
      { "Focusing Shot", { "player.focus < 75", "!player.moving", "player.timetomax > player.spell(Rapid Fire).cooldown" }},
      { "Steady Shot", {"lastcast(Steady Shot)", "player.buff(Steady Focus).duration < 7", "player.focus < 60"}},
      --{ "Steady Shot", { "lastcast(Steady Shot)", "player.buff(Steady Focus).duration < 5", function() return ((14 + dynamicEval("player.spell(56641).regen")) <= dynamicEval("player.focus.deficit")) end, }},

      { "Multi-Shot", { "toggle.multitarget", "modifier.enemies >= 7" }},

      { "Aimed Shot", "talent(7,2)" },
      { "Aimed Shot", "player.focus >= 70" },
      { "Aimed Shot", { "player.buff(34720)", "player.focus > 50" }},

      --{ "Focusing Shot", { "!player.moving", function() return ((50 + (dynamicEval("player.spell(152245).regen")) - 10) < dynamicEval("player.focus.deficit")) end }},
      { "Focusing Shot", { "player.focus.deficit > 55", "!player.moving" }},
      { "Steady Shot" },
    }, { "target.health < 80", "!player.buff(Rapid Fire)" }},
  }, "@NOC.isValidTarget('target')" },
}

ProbablyEngine.rotation.register_custom(254, "NOC Marksman Hunter", combat, ooc, onLoad)

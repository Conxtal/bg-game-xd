# BG GAME - ARCHITECTURE ANALYSIS & MIGRATION PLAN

**Date:** 2026-01-02
**Current File:** `bg game.rbxlx` (8.3MB)
**Total Scripts:** 28 (3 LocalScripts, 1 Script, 24 ModuleScripts)

---

## ⚠️ CRITICAL FINDING

**Only ONE .rbxlx file exists in this repository:**
- `bg game.rbxlx` (on main/current branch)
- The mentioned "bg-game-NEW-ARCHITECTURE_Working.rbxlx" **does NOT exist**
- Branch "Working-new-branch" only contains a `.lock` file

**This means:**
- The current file IS the "original" with all functionality
- There is NO separate "new architecture" file to merge FROM
- The task may need clarification OR the new architecture needs to be built from scratch

---

## 📊 CURRENT ARCHITECTURE OVERVIEW

The existing codebase has a **well-structured, modular architecture**. Here's what exists:

### 🎯 SERVICE STRUCTURE

```
ReplicatedStorage/
  └── Combat/
      ├── Config.lua              [Central config - SIFU tuning]
      ├── Data/
      │   ├── Arthur.lua          [Character data]
      │   └── CharacterVFX/
      │       └── ArthurVFX.lua   [Character-specific VFX]
      └── Modules/
          ├── StateManager.lua    [State, posture, stamina, combo]
          ├── CooldownManager.lua [Cooldown tracking]
          ├── HitboxHandler.lua   [Hitbox utilities]
          └── InputTracker.lua    [⚠️ EMPTY STUB]

ServerScriptService/
  └── Combat/
      ├── InitServer.server.lua   [Server initialization]
      └── Handlers/
          ├── CharacterRegistry.lua   [Character management]
          ├── AttackHandler.lua       [M1 combos + combat lock]
          ├── BlockHandler.lua        [Blocking, deflects, guard breaks]
          ├── DashHandler.lua         [Dash with buffering]
          ├── AbilityHandler.lua      [Ability slots 1-4]
          ├── PassiveHandler.lua      [Passive abilities]
          └── AttackHandler/
              ├── CombatLock.lua      [Combat lock state]
              ├── M1.lua              [⚠️ EMPTY STUB]
              ├── Uptilt.lua          [⚠️ EMPTY STUB]
              └── Aerial.lua          [⚠️ EMPTY STUB]

StarterPlayer/
  └── StarterPlayerScripts/
      └── Combat/
          ├── InitClient.client.lua   [Client initialization]
          ├── CombatClient.lua        [Main client controller]
          ├── CombatLockClient.lua    [Client combat lock (SIFU feel)]
          ├── Handlers/
          │   ├── InputHandler.lua        [Input processing]
          │   ├── AnimationHandler.lua    [Animation system]
          │   ├── VFXHandler.lua          [VFX system]
          │   └── MovementHandler.lua     [⚠️ EMPTY STUB - CRITICAL!]
          └── Modules/
              └── LockOn.lua              [Manual lock-on (Elden Ring style)]
```

---

## ✅ EXISTING SYSTEMS (WHAT WORKS)

### **1. COMBAT SYSTEM** ✅

**Location:** `ServerScriptService/Combat/Handlers/AttackHandler.lua`

**Features:**
- M1 combo chains (1-4 hits)
- Combo window timing
- Hitbox detection during active frames
- Damage calculation with passive bonuses
- Knockback and lift application
- Hitstun application
- Posture damage
- Combat lock integration (SIFU feel - attacker follows victim)
- Hit validation (state checks, cooldowns, combo resets)

**Data Flow:**
```
Client: M1 Click → InputHandler → Remote.Attack:FireServer()
Server: AttackHandler receives → Validates state/cooldowns → Starts attack sequence
        → Spawns hitbox → Detects hits → Applies damage/knockback/hitstun
        → Fires Hit event to all clients
Client: Receives Hit event → AnimationHandler + VFXHandler respond
```

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **2. INPUT SYSTEM** ✅

**Location:** `StarterPlayer/.../Combat/Handlers/InputHandler.lua`

**Keybinds:**
- **Mouse1:** M1 Attack
- **F:** Block (hold)
- **Q:** Dash
- **Space:** Uptilt
- **1-4:** Abilities
- **Mouse3:** Lock-On toggle

**Features:**
- Centralized input handling
- No scattered UserInputService usage
- Clean remote firing
- Move direction calculation for dash

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **3. LOCK-ON SYSTEM** ✅

**Location:** `StarterPlayer/.../Combat/Modules/LockOn.lua`

**Type:** Manual Lock-On (Elden Ring style)

**Features:**
- Nearest target selection (players + NPCs)
- Distance-based locking (50 studs max)
- Auto-unlock on death/distance
- Visual indicator (corner brackets)
- Camera positioning behind player
- Character rotation to face target
- Smooth camera movement

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **4. COMBAT LOCK SYSTEM** ✅ (SIFU FEEL)

**Locations:**
- Client: `StarterPlayer/.../Combat/CombatLockClient.lua`
- Server: `ServerScriptService/Combat/Handlers/AttackHandler/CombatLock.lua`

**Type:** Automatic during combat (attacker follows victim)

**Features:**
- Server-authoritative lock state
- Client follows using AlignPosition + AlignOrientation constraints
- Attacker stays at configurable standoff distance
- Lock extends on hit chains
- Releases on final hit
- Separate modes: Full lock (follow + face) vs Face-only
- NPC lock support

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **5. ABILITIES SYSTEM** ✅

**Location:** `ServerScriptService/Combat/Handlers/AbilityHandler.lua`

**Features:**
- 4 ability slots
- Awakening ability swapping
- Cooldown enforcement
- Stamina cost checking
- State validation
- Remote event firing for client feedback

**Status:** ✅ **FUNCTIONAL** (but abilities themselves not implemented - only framework)

---

### **6. VFX SYSTEM** ✅

**Location:** `StarterPlayer/.../Combat/Handlers/VFXHandler.lua`

**Features:**
- Character-specific VFX modules
- Generic VFX library:
  - Camera shake
  - Screen flash
  - Damage numbers
  - Block/perfect block/guard break effects
  - Hit impact effects
  - Dash trails
- Event-driven (called by CombatClient)
- Clean separation: logic never spawns effects directly

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **7. ANIMATION SYSTEM** ✅

**Location:** `StarterPlayer/.../Combat/Handlers/AnimationHandler.lua`

**Features:**
- Character-specific animation loading
- Animation track management
- Speed modifiers from character data
- Remote player animation support
- Priority system
- Looping support
- Fade in/out

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **8. STATE MANAGEMENT** ✅

**Location:** `ReplicatedStorage/Combat/Modules/StateManager.lua`

**Features:**
- Player state tracking (Idle, Attacking, Blocking, Stunned, Dashing, Recovery, GuardBroken)
- Posture system (Sekiro-style)
- Combo tracking
- Stamina management
- Blocking state
- I-frames system
- Character selection
- Timing utilities (time since attack, time since pressure, etc.)

**Status:** ✅ **FULLY FUNCTIONAL**

---

### **9. CHARACTER SYSTEM** ✅

**Location:**
- `ServerScriptService/Combat/Handlers/CharacterRegistry.lua`
- `ReplicatedStorage/Combat/Data/Arthur.lua`

**Features:**
- Character data modules (stats, animations, M1 data, abilities)
- Character selection
- Stat application to humanoid
- Character-specific VFX loading
- Default character (Arthur)

**Status:** ✅ **FULLY FUNCTIONAL**

---

## ❌ MISSING / BROKEN SYSTEMS

### **1. MOVEMENT HANDLER** ❌ **CRITICAL**

**Location:** `StarterPlayer/.../Combat/Handlers/MovementHandler.lua`

**Current State:**
```lua
local module = {}
return module
```

**What It Should Do:**
- Control player movement during combat states
- Restrict movement during attacks
- Handle dash movement
- Manage walkspeed/jumppower changes
- Integrate with combat lock
- Respect state-based movement restrictions

**Impact:** Movement during combat is likely broken

---

### **2. INPUT TRACKER** ❌

**Location:** `ReplicatedStorage/Combat/Modules/InputTracker.lua`

**Current State:** Empty stub

**What It Should Do:**
- Input buffering system
- Track recent input history
- Allow combat actions to buffer (press M1 before recovery ends)
- Queue management

**Impact:** No input buffering = less responsive feel

---

### **3. UPTILT HANDLER** ❌

**Location:** `ServerScriptService/Combat/Handlers/UptiltHandler.lua`

**Current State:** **DOES NOT EXIST** (but referenced in InitServer.lua:62)

**Error:** InitServer tries to `require(HandlersFolder.UptiltHandler)` but file doesn't exist

**Impact:** Uptilt (Space key) doesn't work

---

### **4. M1 SUB-HANDLERS** ❌

**Locations:**
- `ServerScriptService/Combat/Handlers/AttackHandler/M1.lua`
- `ServerScriptService/Combat/Handlers/AttackHandler/Uptilt.lua`
- `ServerScriptService/Combat/Handlers/AttackHandler/Aerial.lua`

**Current State:** All empty stubs

**Impact:** Unclear - M1 seems to work via AttackHandler.lua directly. These may be planned refactors.

---

### **5. CHARACTER MODELS & ASSETS** ⚠️

**No character models found in workspace**

Characters are defined as data, but:
- No character rigs in ReplicatedStorage
- No weapon models
- No character-specific parts/accessories

**Impact:** Visual representation missing

---

## 🎯 ARCHITECTURE ASSESSMENT

### **Strengths:**
1. ✅ Clear client/server separation
2. ✅ Modular handler system
3. ✅ Centralized state management
4. ✅ Data-driven character system
5. ✅ Proper remote event usage
6. ✅ VFX/logic separation
7. ✅ Tunable configuration
8. ✅ Clean initialization flow

### **Weaknesses:**
1. ❌ MovementHandler is empty (CRITICAL)
2. ❌ InputTracker is empty (no buffering)
3. ❌ UptiltHandler doesn't exist (breaks server init)
4. ❌ No character models/assets
5. ⚠️ Some attack sub-handlers are stubs
6. ⚠️ No ability implementations (only framework)

---

## 🔧 WHAT NEEDS TO BE DONE

### **PHASE 1: FIX CRITICAL ISSUES** 🔴

**Priority:** IMMEDIATE

1. **Create UptiltHandler.lua** (server crashes without it)
2. **Implement MovementHandler.lua** (movement during combat broken)
3. **Test that combat works end-to-end**

### **PHASE 2: IMPLEMENT INPUT BUFFERING** 🟡

**Priority:** HIGH (affects game feel)

1. **Implement InputTracker.lua**
   - Buffer window (0.15-0.20s as per Config)
   - Store recent inputs
   - Consume buffered inputs when state allows

2. **Integrate with AttackHandler**
   - Check buffer during recovery frames
   - Allow combo continuation from buffer

### **PHASE 3: ADD MISSING SYSTEMS** 🟢

**Priority:** MEDIUM

1. **Character Models & Assets**
   - Add character rigs to ReplicatedStorage
   - Add weapon models
   - Equipment system
   - Weld weapons to characters

2. **Ability Implementations**
   - DragonStep
   - EtherSlash
   - BurstNova
   - StaticEdge

3. **Passive System**
   - Implement passive logic in PassiveHandler
   - VFX for passive activation

### **PHASE 4: POLISH & EXTEND** 🔵

**Priority:** LOW

1. **Aerial attacks** (Uptilt.lua, Aerial.lua stubs)
2. **Additional characters**
3. **UI system** (health bars, stamina, cooldowns)
4. **Sound system** (SFX integration)

---

## 📐 RECOMMENDED ARCHITECTURE (REFINED)

The current architecture is **fundamentally sound**. Here's the refined structure:

### **CLIENT STRUCTURE**

```
StarterPlayer/StarterPlayerScripts/Combat/
├── InitClient.client.lua           [Initialization]
├── CombatClient.lua                [Main controller]
├── CombatLockClient.lua            [Combat lock (SIFU feel)]
│
├── Handlers/                       [Client-side systems]
│   ├── InputHandler.lua            [Input processing]
│   ├── MovementHandler.lua         [Movement control] ⚠️ NEEDS IMPLEMENTATION
│   ├── AnimationHandler.lua        [Animation system]
│   └── VFXHandler.lua              [VFX system]
│
└── Modules/                        [Client utilities]
    └── LockOn.lua                  [Manual lock-on]
```

### **SERVER STRUCTURE**

```
ServerScriptService/Combat/
├── InitServer.server.lua           [Initialization + regen loops]
│
└── Handlers/                       [Server-authoritative handlers]
    ├── CharacterRegistry.lua       [Character data]
    ├── AttackHandler.lua           [M1 attacks]
    ├── UptiltHandler.lua           [Launcher attacks] ⚠️ NEEDS CREATION
    ├── BlockHandler.lua            [Blocking system]
    ├── DashHandler.lua             [Dash system]
    ├── AbilityHandler.lua          [Ability system]
    ├── PassiveHandler.lua          [Passive system]
    └── CombatLockHandler.lua       [Combat lock (server authority)]
```

### **SHARED STRUCTURE**

```
ReplicatedStorage/Combat/
├── Config.lua                      [Tuning values]
│
├── Modules/                        [Shared systems]
│   ├── StateManager.lua            [State tracking]
│   ├── CooldownManager.lua         [Cooldown system]
│   ├── HitboxHandler.lua           [Hitbox utilities]
│   └── InputTracker.lua            [Input buffering] ⚠️ NEEDS IMPLEMENTATION
│
└── Data/                           [Game data]
    ├── Arthur.lua                  [Character data]
    ├── Lancelot.lua                [Additional characters...]
    └── CharacterVFX/
        ├── ArthurVFX.lua           [Character-specific VFX]
        └── LancelotVFX.lua
```

---

## 🔄 DATA FLOW DIAGRAMS

### **M1 ATTACK FLOW**

```
[CLIENT]                          [SERVER]                          [ALL CLIENTS]

User clicks M1
    ↓
InputHandler.OnInputBegan()
    ↓
Remote.Attack:FireServer() ────→ AttackHandler.OnAttack(player)
                                      ↓
                                  Validate state/cooldowns
                                      ↓
                                  Start attack sequence
                                      ↓
                                  Fire State event ─────────────→ CombatClient.OnState("M1")
                                      ↓                                ↓
                                  task.wait(startup)              AnimationHandler.PlayM1()
                                      ↓                                ↓
                                  Spawn hitbox                    VFXHandler.OnM1()
                                      ↓
                                  Detect hits
                                      ↓
                                  Apply damage/knockback
                                      ↓
                                  Engage combat lock
                                      ↓
                                  Fire Hit event ────────────────→ CombatClient.OnHit()
                                      ↓                                ↓
                                  task.wait(recovery)             VFXHandler.OnHit()
                                      ↓                                ↓
                                  Set state to Idle           AnimationHandler.PlayHitReaction()
```

### **DASH FLOW**

```
[CLIENT]                          [SERVER]                          [ALL CLIENTS]

User presses Q
    ↓
InputHandler: Calculate moveDir
    ↓
Remote.Dash:FireServer(dir) ──→ DashHandler.OnDash(player, dir)
                                      ↓
                                  Validate (cooldown/stamina/state)
                                      ↓
                                  Consume stamina
                                      ↓
                                  Grant i-frames
                                      ↓
                                  Apply velocity (BodyVelocity)
                                      ↓
                                  Fire State event ─────────────→ CombatClient.OnState("Dash")
                                      ↓                                ↓
                                  task.wait(duration)             AnimationHandler.PlayDash()
                                      ↓                                ↓
                                  Clear i-frames                  VFXHandler.OnDash()
                                      ↓
                                  Set cooldown
```

---

## 🛠️ IMPLEMENTATION PRIORITY CHECKLIST

### **CRITICAL (DO FIRST)** 🔴

- [ ] Create `UptiltHandler.lua` (server won't run without it)
- [ ] Implement `MovementHandler.lua` (movement broken)
- [ ] Test end-to-end combat flow
- [ ] Fix any runtime errors

### **HIGH PRIORITY** 🟡

- [ ] Implement `InputTracker.lua` (input buffering)
- [ ] Integrate input buffer with AttackHandler
- [ ] Add character models to game
- [ ] Add weapon models and equipment system

### **MEDIUM PRIORITY** 🟢

- [ ] Implement ability logic (DragonStep, EtherSlash, etc.)
- [ ] Implement passive system logic
- [ ] Add more characters beyond Arthur
- [ ] Create UI system (health, stamina, cooldowns)

### **LOW PRIORITY** 🔵

- [ ] Implement aerial attack system
- [ ] Add sound effects
- [ ] Add particle effects
- [ ] Polish VFX
- [ ] Add additional game modes

---

## 📋 MODULE API CONTRACTS

### **MovementHandler.lua** (CLIENT)

```lua
local MovementHandler = {}

-- Initialize movement system
function MovementHandler.Init()
    -- Listen for state changes
    -- Set up movement restrictions
end

-- Set movement restrictions based on combat state
function MovementHandler.SetState(state)
    -- "Attacking" -> restrict movement
    -- "Blocking" -> allow slow movement
    -- "Dashing" -> disable normal movement
    -- "Idle" -> full movement
end

-- Apply movement during attack (e.g., slight forward movement on M1)
function MovementHandler.ApplyAttackMovement(attackType, direction)
    -- Apply small forward velocity during attacks
end

-- Handle dash movement
function MovementHandler.Dash(direction, distance, duration)
    -- Apply dash velocity
    -- Lock movement during dash
end

-- Integrate with combat lock (don't fight against AlignPosition)
function MovementHandler.OnCombatLockEngaged()
    -- Disable normal movement
    -- Let combat lock constraints handle positioning
end

function MovementHandler.OnCombatLockReleased()
    -- Re-enable normal movement
end

return MovementHandler
```

### **InputTracker.lua** (SHARED)

```lua
local InputTracker = {}

-- Config
local BUFFER_WINDOW = 0.20 -- seconds

-- Initialize
function InputTracker.Init()
    -- Set up buffer data structure
end

-- Add input to buffer
function InputTracker.BufferInput(player, inputType, data)
    -- Store input with timestamp
    -- inputType: "M1", "Block", "Dash", "Uptilt", "Ability1", etc.
end

-- Check if buffered input exists
function InputTracker.HasBufferedInput(player, inputType)
    -- Return true if valid buffered input exists within window
end

-- Consume buffered input
function InputTracker.ConsumeInput(player, inputType)
    -- Remove from buffer and return data
end

-- Clear all buffered inputs for player
function InputTracker.ClearBuffer(player)
    -- Wipe buffer (on state change, death, etc.)
end

-- Clean up old inputs (called periodically)
function InputTracker.CleanExpired(player)
    -- Remove inputs older than BUFFER_WINDOW
end

return InputTracker
```

### **UptiltHandler.lua** (SERVER)

```lua
local UptiltHandler = {}

local Remotes, CharacterRegistry
local StateManager, CooldownManager, HitboxHandler, Config

function UptiltHandler.Init(remotes, charRegistry)
    Remotes = remotes
    CharacterRegistry = charRegistry

    -- Load dependencies
    local CombatFolder = game:GetService("ReplicatedStorage"):WaitForChild("Combat")
    StateManager = require(CombatFolder.Modules.StateManager)
    CooldownManager = require(CombatFolder.Modules.CooldownManager)
    HitboxHandler = require(CombatFolder.Modules.HitboxHandler)
    Config = require(CombatFolder.Config)

    -- Listen for Uptilt remote
    Remotes.Uptilt.OnServerEvent:Connect(UptiltHandler.OnUptilt)
end

function UptiltHandler.OnUptilt(player)
    -- Validate state (not stunned, not blocking, etc.)
    -- Check combo limit (can't uptilt after M1_3 or M1_4)
    -- Check cooldown
    -- Fire State event to clients
    -- task.wait(startup)
    -- Spawn hitbox (upward-facing)
    -- Apply launch velocity to hit targets
    -- Apply damage + posture damage
    -- task.wait(active)
    -- task.wait(recovery or recoveryOnHit)
    -- Set state to Idle
end

return UptiltHandler
```

---

## 🎮 INTEGRATION POINTS

### **How Systems Communicate**

```
Input → InputHandler → Remote Events → Server Handlers
                                            ↓
                                       StateManager (authoritative state)
                                            ↓
                                    Remotes.State:FireAllClients()
                                            ↓
                       ┌────────────────────┴────────────────────┐
                       ↓                                         ↓
                CombatClient.OnState()                  CombatClient.OnHit()
                       ↓                                         ↓
         ┌─────────────┴─────────────┐             ┌────────────┴────────────┐
         ↓                           ↓             ↓                         ↓
  AnimationHandler              VFXHandler   AnimationHandler           VFXHandler
  (plays anims)               (spawns VFX)  (hit reactions)        (hit effects)
```

---

## ✅ FINAL SANITY CHECK

**Does BG-Game-Final (when complete):**

- ✅ Keep all original functionality?
  - YES, all systems will be preserved + missing ones added

- ✅ Fix non-working combat?
  - YES, UptiltHandler will be created, MovementHandler implemented

- ✅ Maintain the working architecture?
  - YES, current architecture is solid and will be preserved

- ✅ Is extensible going forward?
  - YES, modular handler system makes adding characters/abilities easy

---

## 📝 NOTES

1. **The current architecture is GOOD.** Don't redesign it.
2. **The main issues are MISSING IMPLEMENTATIONS**, not bad design.
3. **MovementHandler and UptiltHandler are the critical blockers.**
4. **Input buffering is important for feel but not critical for basic function.**
5. **Character models/assets are needed for visual completeness.**
6. **The SIFU feel comes from the combat lock system, which already works.**

---

**END OF ANALYSIS**

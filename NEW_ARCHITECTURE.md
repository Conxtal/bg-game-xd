# NEW ARCHITECTURE - Complete Rebuild

## Philosophy

**Explicit over Implicit**
**Modular over Monolithic**
**Contract-based over Ad-hoc**
**Authoritative Server, Responsive Client**

---

## 1. STATE MACHINE (Core Foundation)

### Exclusive States

**Primary States** (only ONE active):
- `Grounded` - normal movement, can attack/block/dash
- `Airborne` - in air, reduced control, can air-attack
- `Stunned` - frozen, no input
- `Ragdoll` - physics-based stun

**Sub-States** (modifiers):
- `Combat` - in active combat (combo/lock active)
- `Blocking` - holding block
- `Dashing` - invulnerable dash

### State Contract

```lua
State = {
    Enter = function(player, data) end,
    Update = function(player, dt) end,
    Exit = function(player) end,

    -- Transition rules
    CanTransitionTo = {
        [OtherState] = function(player) return boolean end
    }
}
```

### StateService

**Responsibilities:**
- Enforce exclusive states
- Handle transitions with validation
- Call enter/exit hooks
- Manage sub-states

**API:**
```lua
StateService.Transition(player, newState, data)
StateService.GetState(player) -> State
StateService.IsInState(player, state) -> boolean
StateService.HasSubState(player, subState) -> boolean
StateService.AddSubState(player, subState)
StateService.RemoveSubState(player, subState)
```

---

## 2. STATE DEFINITIONS

### GroundedState

**Enter:**
- Reset air jumps
- Restore WalkSpeed
- Clear aerial flags

**Update:**
- Check if still on ground (raycasts)
- Handle combo timeout
- Regen stamina/posture

**Exit:**
- Nothing special

**Can Transition To:**
- Airborne (if off ground)
- Stunned (if hit)
- Ragdoll (if launched hard)
- Dashing (if input + stamina)

**Sub-States Allowed:**
- Combat
- Blocking

### AirborneState (NEW)

**Enter:**
- Set air control multiplier
- Enable aerial move list
- Track launch source

**Update:**
- Apply gravity modifications
- Check ground raycast
- Handle aerial combo timeout

**Exit:**
- Landing cleanup

**Can Transition To:**
- Grounded (if landed)
- Stunned (if hit in air)
- Ragdoll (if hit hard)

**Sub-States Allowed:**
- Combat (aerial combat)

### StunnedState

**Enter:**
- Disable input
- Set stun duration
- Play hit reaction

**Update:**
- Countdown stun timer

**Exit:**
- Re-enable input
- Transition to Grounded or Airborne (based on position)

**Can Transition To:**
- Grounded (after stun)
- Airborne (after stun in air)
- Ragdoll (if hit during stun)

### DashState

**Enter:**
- Apply dash velocity
- Enable i-frames
- Start dash timer

**Update:**
- Maintain dash direction
- Countdown dash duration

**Exit:**
- Remove i-frames
- Transition based on ground state

**Can Transition To:**
- Grounded (after dash on ground)
- Airborne (after dash in air)

---

## 3. COMBAT SYSTEM

### CombatService (Server Authority)

**Responsibilities:**
- Validate attack requests
- Perform hitbox detection
- Calculate damage with all modifiers
- Apply knockback/hitstun/posture
- Trigger combat lock
- Manage combo state

**NO VFX, NO ANIMATIONS** - only data/authority

**API:**
```lua
CombatService.ProcessM1(player)
CombatService.ProcessUptilt(player)
CombatService.ProcessAerialAttack(player, attackType)
CombatService.ProcessAbility(player, slot)
```

### HitboxService

**Responsibilities:**
- Abstract hitbox creation
- Shape casting (box, sphere, raycast)
- Filter management
- Multi-frame detection

**API:**
```lua
HitboxService.CreateBox(origin, size, direction, filter)
HitboxService.CreateSphere(origin, radius, filter)
HitboxService.DetectMultiFrame(hitbox, duration) -> hits
```

### DamageService

**Responsibilities:**
- Calculate final damage with ALL modifiers
- Apply damage to victim
- Handle defense stats
- Track damage sources

**Modifiers:**
- Base damage
- Character stat multiplier
- Passive bonuses
- Awakening multiplier
- Victim defense

**API:**
```lua
DamageService.Calculate(attacker, victim, baseDamage) -> finalDamage
DamageService.Apply(victim, damage, source)
```

### StunService

**Responsibilities:**
- Apply hitstun
- Apply block stun
- Manage stun duration
- Handle stun state transitions

**Types:**
- `Hit` - normal hit stun
- `Block` - reduced stun on block
- `Counter` - extended stun on counter hit
- `Launch` - aerial launch stun

**API:**
```lua
StunService.ApplyHitstun(victim, duration, stunType)
StunService.IsStunned(player) -> boolean
StunService.GetStunRemaining(player) -> number
```

### IFrameService (NEW)

**Responsibilities:**
- Grant invulnerability
- Track i-frame duration
- Validate hits during i-frames

**API:**
```lua
IFrameService.Grant(player, duration)
IFrameService.Has(player) -> boolean
IFrameService.GetRemaining(player) -> number
```

### HitstopService (NEW)

**Responsibilities:**
- Freeze attacker on hit
- Freeze victim on hit
- Brief pause for impact feel

**API:**
```lua
HitstopService.Apply(attacker, victim, duration)
```

---

## 4. AERIAL COMBAT SYSTEM (NEW)

### Flow

**Uptilt Launch:**
1. Ground attacker hits uptilt
2. Victim enters `Airborne` state
3. Victim launched upward (velocity applied)
4. Attacker transitions to `Airborne` + `Combat` sub-state
5. **Combat Lock** engages (attacker follows victim)

**Aerial Combat:**
- Attacker can use aerial M1s (different moveset)
- Victim can air-dodge (if not stunned)
- Gravity reduced during aerial combat
- Combo continues in air

**Exit:**
- Downslam finisher (sends both to ground)
- Miss/dodge (both fall naturally)
- Timeout (combat lock ends, natural fall)

### AerialCombatData (in Character file)

```lua
AerialCombat = {
    M1 = {
        -- Aerial M1 chains
    },
    Finisher = {
        -- Downslam finisher
    },
    GravityMultiplier = 0.3, -- reduced gravity
    LockDuration = 2.0, -- how long combat lock lasts
}
```

---

## 5. MOVEMENT SYSTEM

### MovementService

**Responsibilities:**
- Coordinate all movement
- Handle WalkSpeed modifications
- Handle jump modifications

**API:**
```lua
MovementService.SetWalkSpeed(player, speed)
MovementService.SetJumpPower(player, power)
MovementService.ApplyVelocity(player, velocity)
```

### DashService

**Responsibilities:**
- Execute dash
- Handle direction
- Grant i-frames
- Set cooldown

**Flow:**
1. Validate (state, cooldown, stamina)
2. Consume stamina
3. Transition to `DashState`
4. Grant i-frames
5. Apply velocity
6. Start timer
7. On end: transition back

---

## 6. LOCK SYSTEM

### TargetLockService

**Responsibilities:**
- Tab toggle lock
- Find nearest target
- Maintain lock distance
- Camera management

**Client-only** (visual aid)

### CombatLockService

**Responsibilities:**
- Lock attacker to victim on hit
- Follow victim at standoff
- Face victim
- Duration management
- Aerial follow support

**Server sends command, client executes**

**API:**
```lua
-- Server
CombatLockService.LockToTarget(attacker, victim, duration)
CombatLockService.Unlock(player)

-- Client
CombatLockClient.ExecuteLock(victimChar, duration, isAerial)
CombatLockClient.Release()
```

---

## 7. ANIMATION SYSTEM

### AnimationService

**Responsibilities:**
- Load animations per character
- Cache loaded tracks
- Play with priority/fade/speed
- Stop animations
- Cleanup on character removal

**API:**
```lua
AnimationService.Load(character, animName) -> Track
AnimationService.Play(character, animName, options) -> Track
AnimationService.Stop(character, animName)
AnimationService.StopAll(character)
```

### AnimationLibrary

**Character animation registry**
- Loads from character data
- Returns animation objects

---

## 8. INPUT SYSTEM

### InputService

**Responsibilities:**
- Capture all input
- Route to InputBuffer
- Handle keybind changes

**NOT** responsible for game logic

### InputBuffer (NEW)

**Responsibilities:**
- Queue inputs during recovery
- Execute buffered input when ready
- Priority system (some inputs override others)

**Example:**
- Player presses M1 during recovery
- Input buffered
- Recovery ends
- M1 executes automatically

**API:**
```lua
InputBuffer.Queue(player, action, data)
InputBuffer.Execute(player) -- called when state allows
InputBuffer.Clear(player, action)
```

---

## 9. CHARACTER SYSTEM

### CharacterService

**Responsibilities:**
- Load character data
- Get character stats
- Handle character selection

**API:**
```lua
CharacterService.Load(characterName) -> CharData
CharacterService.Get(player) -> CharData
CharacterService.SetCharacter(player, charName)
```

### PassiveService (Extensible)

**Responsibilities:**
- Handle passive ability logic
- Support multiple passive types
- Per-character passive modules

**Registry Pattern:**
```lua
PassiveService.Register("EtherResonance", PassiveModule)
PassiveService.Trigger(player, event, data)
```

### AbilityService

**Responsibilities:**
- Execute ability by slot
- Handle cooldowns
- Validate requirements

**API:**
```lua
AbilityService.Execute(player, slot)
AbilityService.IsReady(player, slot) -> boolean
```

---

## 10. VFX SYSTEM

### VFXService (Coordinator)

**Responsibilities:**
- Route VFX requests to character modules
- Coordinate timing with animations
- Cleanup VFX

**NOT** responsible for VFX creation - just routing

**API:**
```lua
VFXService.Play(character, vfxName, data)
VFXService.Stop(character, vfxName)
```

### Character VFX Modules

**Per-character VFX implementations**
- `ArthurVFX`
- `IchigoVFX` (future)
- etc.

---

## 11. UTILITY MODULES

### Signal

**Custom event system**
- Better than BindableEvents
- Cleanup support

### Maid

**Resource cleanup**
- Connections
- Instances
- Tables

### TableUtil

**Deep copy, merge, etc.**

### MathUtil

**Lerp, clamp, etc.**

---

## 12. MODULE LOADERS

### Combat Loader

```lua
-- ReplicatedStorage/Combat/init.lua
local Combat = {}

Combat.CombatService = require(script.CombatService)
Combat.HitboxService = require(script.HitboxService)
Combat.DamageService = require(script.DamageService)
Combat.StunService = require(script.StunService)
Combat.IFrameService = require(script.IFrameService)
Combat.HitstopService = require(script.HitstopService)

return Combat
```

**Usage:**
```lua
local Combat = require(ReplicatedStorage.Combat)
Combat.CombatService.Init(dependencies)
```

### States Loader

```lua
local States = {}

States.StateService = require(script.StateService)
States.Grounded = require(script.GroundedState)
States.Airborne = require(script.AirborneState)
States.Stunned = require(script.StunnedState)
States.Dash = require(script.DashState)

return States
```

---

## 13. DEPENDENCY INJECTION

**No random require() calls inside modules**

**Example:**
```lua
-- Bad
local StateService = require(game.ReplicatedStorage.States.StateService)

-- Good
local CombatService = {}

function CombatService.Init(dependencies)
    CombatService.StateService = dependencies.StateService
    CombatService.DamageService = dependencies.DamageService
    -- etc.
end
```

---

## 14. CLIENT/SERVER SPLIT

### Server Owns
- State
- Hit detection
- Damage calculation
- Validation
- Authority

### Client Owns
- Input
- Camera
- VFX
- Animations
- Prediction (optional)

### Communication
- Server → Client: State updates, hit events
- Client → Server: Input requests only

**NO TRUST IN CLIENT**

---

## 15. FOLDER STRUCTURE

```
ReplicatedStorage/
├─ Combat/
│  ├─ init.lua (loader)
│  ├─ CombatService.lua
│  ├─ HitboxService.lua
│  ├─ DamageService.lua
│  ├─ StunService.lua
│  ├─ IFrameService.lua
│  └─ HitstopService.lua
├─ States/
│  ├─ init.lua (loader)
│  ├─ StateService.lua
│  ├─ GroundedState.lua
│  ├─ AirborneState.lua
│  ├─ StunnedState.lua
│  └─ DashState.lua
├─ Movement/
│  ├─ init.lua (loader)
│  ├─ MovementService.lua
│  └─ DashService.lua
├─ Lock/
│  ├─ init.lua (loader)
│  ├─ TargetLockService.lua
│  └─ CombatLockService.lua
├─ Animation/
│  ├─ init.lua (loader)
│  ├─ AnimationService.lua
│  └─ AnimationLibrary.lua
├─ Input/
│  ├─ init.lua (loader)
│  ├─ InputService.lua
│  └─ InputBuffer.lua
├─ Character/
│  ├─ init.lua (loader)
│  ├─ CharacterService.lua
│  ├─ PassiveService.lua
│  ├─ AbilityService.lua
│  └─ Data/
│     └─ Arthur.lua
├─ VFX/
│  ├─ init.lua (loader)
│  ├─ VFXService.lua
│  └─ Characters/
│     └─ ArthurVFX.lua
├─ Utils/
│  ├─ Signal.lua
│  ├─ Maid.lua
│  ├─ TableUtil.lua
│  └─ MathUtil.lua
└─ Config.lua

ServerScriptService/
├─ Init.server.lua
└─ (no other scripts - uses loaders)

StarterPlayer/StarterPlayerScripts/
├─ InitClient.client.lua
└─ (no other scripts - uses loaders)
```

---

## 16. INITIALIZATION SEQUENCE

### Server

```lua
-- 1. Load all modules
local Combat = require(ReplicatedStorage.Combat)
local States = require(ReplicatedStorage.States)
local Movement = require(ReplicatedStorage.Movement)
-- etc.

-- 2. Initialize with dependencies
States.StateService.Init()

Combat.IFrameService.Init()
Combat.StunService.Init({
    StateService = States.StateService
})
Combat.DamageService.Init({
    StateService = States.StateService
})
Combat.HitstopService.Init()
Combat.HitboxService.Init()
Combat.CombatService.Init({
    StateService = States.StateService,
    HitboxService = Combat.HitboxService,
    DamageService = Combat.DamageService,
    StunService = Combat.StunService,
    IFrameService = Combat.IFrameService,
    HitstopService = Combat.HitstopService
})

-- etc.
```

### Client

```lua
-- Similar pattern with client-side modules
```

---

## 17. STATE DIAGRAM

```
        [Grounded] ←──────────────┐
            │  ↑                  │
      M1    │  │ Land             │
      Uptilt│  │                  │
      Dash  │  │                  │
            ↓  │                  │
        [Combat]                  │
            │                     │
      Uptilt│                     │
       Hit  │                     │
            ↓                     │
        [Airborne] ───────────────┘
            │  ↑
      M1    │  │
      (air) │  │
            ↓  │
    [Aerial Combat]
            │
      Finish│
            ↓
        [Grounded]

    [Dash] can interrupt most states
    [Stunned] can be entered from any state (on hit)
    [Ragdoll] rare, heavy launches only
```

---

## IMPLEMENTATION ORDER

1. ✅ Utils (Signal, Maid, TableUtil, MathUtil)
2. ✅ StateService + State modules
3. ✅ HitboxService
4. ✅ DamageService
5. ✅ StunService
6. ✅ IFrameService
7. ✅ HitstopService
8. ✅ CombatService
9. ✅ MovementService + DashService
10. ✅ AnimationService
11. ✅ VFXService
12. ✅ InputService + InputBuffer
13. ✅ TargetLockService
14. ✅ CombatLockService
15. ✅ CharacterService
16. ✅ PassiveService
17. ✅ AbilityService
18. ✅ Server Init
19. ✅ Client Init
20. ✅ Testing
21. ✅ .rbxlx creation

---

## SUCCESS CRITERIA

- ✅ M1 combos work
- ✅ Uptilt → aerial combat works
- ✅ Aerial follow-up combos work
- ✅ Downslam finisher works
- ✅ Dash works with i-frames
- ✅ Block works with posture/guard break
- ✅ Combat lock works (ground + aerial)
- ✅ Target lock works
- ✅ Input buffering works
- ✅ Hitstop feels good
- ✅ State machine enforces rules
- ✅ No state spam
- ✅ Clean code (max 40 lines per function)
- ✅ Extensible for new characters
- ✅ Zero circular dependencies

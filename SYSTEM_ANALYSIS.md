# COMPLETE SYSTEM ANALYSIS - Original Codebase

## Total: 27 Scripts, ~4,500 lines of code

---

## 1. STATE SYSTEM

**StateManager** (327 lines) - `ReplicatedStorage/Combat/Modules/StateManager`

### States
- IDLE
- ATTACKING
- BLOCKING
- STUNNED
- DASHING
- RECOVERY
- AIRBORNE
- GUARD_BROKEN

### Data Tracked Per Player
- character (name)
- state (current state)
- combo (current combo count)
- lastAttack (timestamp)
- stamina (current stamina)
- lastStamUse (timestamp)
- **posture** (Sekiro-style guard meter)
- maxPosture
- lastPostureDamage
- isGuardBroken
- blocking
- blockStart
- iframes
- iframeEnd
- awakened

### Functions
- Setup/Remove/Get player data
- State setters/getters
- Posture management (Add/Get/Reset/IsGuardBroken)
- Stamina management
- Combo tracking (Get/Set/Reset/TimeSinceAttack)
- Character selection (Get/SetCharacter)

**Issues Found:**
- No proper state machine (no enter/exit hooks)
- State can be set directly without validation
- No exclusive state enforcement

---

## 2. COMBAT SYSTEM

### AttackHandler (326 lines) - M1 Combo System

**Flow:**
1. Request throttling (0.05s)
2. State validation (not stunned/blocking/dashing/guard broken)
3. Cooldown check
4. Combo logic (reset if window expired)
5. Set cooldown for full attack duration
6. Fire state update to all clients
7. Wait startup time
8. Active hitbox detection (multi-frame)
9. Process hits with damage/knockback/posture
10. Wait recovery
11. Reset combo after combo window expires

**Features:**
- Combo buffering
- Passive damage multipliers
- Awakening multipliers
- Posture damage on block
- Perfect block/deflect detection
- Guard break mechanics
- Knockback/lift application
- Hitstun
- **Combat Lock** integration (locks to first hit target)

**Missing:**
- No hitstop
- No true vs fake stun distinction
- No aerial combat state handling

### BlockHandler (167 lines)

**Features:**
- Perfect block window (first 0.18s)
- Posture drain on block
- Guard break at 100 posture
- Deflect stun on perfect block
- Pushback application

### DashHandler (172 lines)

**Features:**
- Direction-based dash (forward/back/left/right)
- I-frames during dash
- Cooldown system
- Stamina cost
- Can cancel combos

**Issues:**
- I-frames implemented via HealthChanged workaround (not clean)
- No proper state transition

### AbilityHandler (90 lines)

**Features:**
- 4 ability slots
- Awakening abilities (different set)
- Cooldown per slot
- Stamina cost
- Basic execution (needs expansion)

### PassiveHandler (269 lines)

**Arthur's Ether Resonance:**
- Stacks on hit (max 8)
- Per-stack bonuses (damage, attack speed)
- Buff at max stacks (duration, cooldown)
- Stack decay system
- Awakening stack rate multiplier

**Issues:**
- Only handles Arthur's passive
- Not extensible for other characters

---

## 3. CLIENT SYSTEMS

### CombatClient (188 lines)

**Responsibilities:**
- Initialize handlers (Input, Animation, VFX)
- Setup remotes
- Listen for server events (State, Hit, Notification)
- Coordinate client-side systems

### InputHandler (120 lines)

**Keybinds:**
- MouseButton1: Attack
- F: Block
- Q: Dash
- Space: Uptilt
- 1-4: Abilities

**Features:**
- Input began/ended handling
- Block hold/release
- Direct remote firing

**Issues:**
- No input buffering
- No priority system

### AnimationHandler (288 lines)

**Features:**
- Per-character animation loading
- Animation caching
- Speed adjustment
- State-based animation (M1, Uptilt, Block, Dash, Hit reactions)
- Cleanup on character removal

**Issues:**
- Complex nested logic
- Hard to follow animation flow

### VFXHandler (473 lines)

**Features:**
- Character-specific VFX modules
- M1 hit effects
- Dash trails
- Block shield
- Uptilt slashes
- State-based VFX coordination

**Issues:**
- Very large, doing too much
- Hard-coded VFX logic mixed with coordination

---

## 4. LOCK-ON SYSTEMS

### LockOn (316 lines) - Target Lock

**Features:**
- Tab toggle
- Find nearest target
- Camera lock to target
- Distance validation
- Target switching

### CombatLockClient (361 lines) - SIFU-style Combat Lock

**Features:**
- Locks to hit target during combo
- AlignOrientation (face opponent)
- AlignPosition (follow at standoff distance)
- Smooth follow with constraints
- Duration-based or manual unlock
- Face-only mode (no follow)
- NPC support

**Tunables:**
- STANDOFF_DISTANCE (5 studs)
- FOLLOW_RESPONSIVENESS (80)
- ORIENT_RESPONSIVENESS (70)
- MAX_FORCE (300000)

**Server-side (CombatLock in AttackHandler):**
- Auto-lock on first hit
- Send lock command to client
- Duration management
- Unlock conditions

---

## 5. CHARACTER SYSTEM

### CharacterRegistry (264 lines)

**Features:**
- Load character modules from folder
- Character selection per player
- Get character data
- Validation

### Arthur (342 lines) - Character Data

**Complete Stats:**
- Base stats (damage, knockback, speed, health, walkspeed, jumppower)
- Posture max
- **Passive:** Ether Resonance (stacking system)
- **M1:** 4-hit combo with individual hit data (startup/active/recovery/damage/knockback/posture)
- **Uptilt:** Launch data (startup/active/recovery/damage/velocity/hitstun)
- **Dash:** Distance/duration/cooldown/iframes/stamina cost
- **Block:** Damage reduction, perfect window, guard break stun
- **Awakening:** Asura Ascension (duration/cooldown/multipliers)
- **Animations:** Asset IDs for all actions
- **Animation Speeds:** Speed multipliers
- **Abilities:** 4 base + 4 awakening
- **AbilityData:** Full data for each ability

---

## 6. SHARED SYSTEMS

### Config (164 lines)

**Contains:**
- Stamina settings
- Player defaults
- Combat settings (cooldowns, posture values)
- Hitbox settings

### CooldownManager (61 lines)

**Features:**
- Set/Get/Clear cooldowns
- IsReady check
- GetRemaining time
- Per-player tracking

### HitboxHandler (127 lines)

**Features:**
- BoxCast with OverlapParams
- Character/Player resolution
- Multi-frame hit detection
- Filter list support

---

## 7. SERVER INITIALIZATION

### InitServer (228 lines)

**Responsibilities:**
- Create remotes folder
- Create all remote events
- Initialize handlers
- Player setup (state, passive)
- Player cleanup
- Posture/stamina regen loop (Heartbeat)

---

## CRITICAL ISSUES FOUND

### 1. No Proper State Machine
- States set directly with no validation
- No enter/exit hooks
- No exclusive state enforcement
- State spam possible

### 2. No Aerial Combat System
- Uptilt launches but no aerial state
- No aerial follow-up attacks
- No downslam/finisher from air

### 3. Mixed Responsibilities
- VFXHandler doing too much
- AttackHandler handling combat lock
- No clear separation of concerns

### 4. No Hitstop
- Missing impactful hit freeze

### 5. Weak I-frames
- Dash i-frames use HealthChanged workaround
- No proper invulnerability system

### 6. No Input Buffering
- Inputs can be lost during recovery
- No queue system

### 7. Limited Extensibility
- PassiveHandler only handles Arthur
- Hard to add new characters with different systems

---

## ARCHITECTURE TO BUILD

### Core Principles
1. **Explicit State Machine** with enter/update/exit
2. **Domain Separation** (Combat, Movement, Animation, VFX, Input)
3. **Module Loaders** per domain
4. **Dependency Injection** (no random requires)
5. **Client/Server Split** (authority vs presentation)
6. **Contract-based** (clear interfaces)

### Domains
```
Combat/
  ├─ CombatService (server authority)
  ├─ CombatClient (client coordinator)
  ├─ HitboxService
  ├─ DamageService
  ├─ StunService
  ├─ IFrameService
  ├─ HitstopService (NEW)

States/
  ├─ StateService (state machine)
  ├─ GroundedState
  ├─ AirborneState (NEW)
  ├─ CombatState
  ├─ DashState
  ├─ BlockState
  ├─ StunnedState

Movement/
  ├─ MovementService
  ├─ DashService
  ├─ AerialMovement (NEW)

Lock/
  ├─ TargetLockService
  ├─ CombatLockService

Animation/
  ├─ AnimationService
  ├─ AnimationLibrary

Input/
  ├─ InputService
  ├─ InputBuffer (NEW)

Character/
  ├─ CharacterService
  ├─ PassiveService (extensible)
  ├─ AbilityService

VFX/
  ├─ VFXService (coordinator)
  ├─ Character VFX modules

Utils/
  ├─ Signal
  ├─ Maid
  ├─ TableUtil
  ├─ MathUtil
```

---

## NEXT STEPS

1. Design state machine with proper enter/exit
2. Design aerial combat system
3. Design hitstop system
4. Design input buffer
5. Create module loaders per domain
6. Implement all systems
7. Create final .rbxlx

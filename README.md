# BG Game - Combat System

A SIFU-style combat game for Roblox featuring fast, grounded, punishable combat mechanics.

## Features

- **M1 Combo System**: 4-hit combo chains with timing windows
- **Blocking & Deflects**: Posture-based defense system (Sekiro-inspired)
- **Dashing**: Quick dodges with i-frames
- **Uptilt Attacks**: Launcher moves for aerial combos
- **Ability System**: 4 ability slots per character
- **Passive Abilities**: Character-specific passive buffs
- **Target Lock**: Camera lock-on system
- **Combat Lock**: SIFU-style movement lock during combat
- **Character System**: Expandable character roster (currently Arthur)
- **VFX System**: Visual effects for all combat actions

## Project Structure

```
src/
├── shared/                 # ReplicatedStorage (shared modules)
│   ├── Config.lua         # Central configuration
│   ├── State.lua          # Player state management
│   ├── Cooldown.lua       # Cooldown tracking
│   ├── Hitbox.lua         # Hitbox utilities
│   ├── characters/
│   │   ├── Arthur.lua     # Arthur character data
│   │   └── Registry.lua   # Character registry
│   └── vfx/
│       └── ArthurVFX.lua  # Arthur VFX definitions
│
├── client/                # StarterPlayerScripts
│   ├── Init.client.lua    # Client entry point
│   ├── Client.lua         # Main client controller
│   ├── Input.lua          # Input handler
│   ├── Animation.lua      # Animation handler
│   ├── VFX.lua            # VFX handler
│   └── Lock.lua           # Target lock & combat lock
│
└── server/                # ServerScriptService
    ├── Init.server.lua    # Server entry point
    ├── Attack.lua         # M1 attack handler
    ├── Block.lua          # Block handler
    ├── Dash.lua           # Dash handler
    ├── Ability.lua        # Ability handler
    └── Passive.lua        # Passive ability handler
```

## Installation

1. Place files from `src/shared/` into `ReplicatedStorage`
2. Place files from `src/client/` into `StarterPlayer/StarterPlayerScripts`
3. Place files from `src/server/` into `ServerScriptService`

## Controls

- **Left Click**: M1 Attack
- **F**: Block/Deflect
- **Q**: Dash
- **Space**: Uptilt
- **1-4**: Abilities
- **Tab**: Toggle target lock

## Architecture Changes

### Simplified from Original

**Before**: 27 scripts with complex nested structure
**After**: 16 clean, focused scripts

**Key improvements:**
- Merged `LockOn` + `CombatLockClient` → `Lock.lua`
- Removed empty stubs (`MovementHandler`, `InputTracker`, etc.)
- Flatter folder structure
- Clearer separation of concerns
- Simplified module dependencies

### Core Systems

**State Management** (`State.lua`)
- Player combat state (Idle, Attacking, Blocking, etc.)
- Character selection
- Stamina tracking
- Posture tracking

**Combat Flow**
1. Client sends input → `Input.lua`
2. Server validates → `Attack/Block/Dash/Ability.lua`
3. Server updates state → `State.lua`
4. Server sends events → Clients
5. Clients play VFX/animations → `VFX.lua`, `Animation.lua`

**Character System**
- Data-driven character definitions
- Easy to add new characters
- Character-specific VFX modules
- Passive ability system

## Adding New Characters

1. Create `src/shared/characters/NewCharacter.lua` following Arthur's structure
2. Create `src/shared/vfx/NewCharacterVFX.lua` for VFX
3. Register in `Registry.Init()`
4. Done!

## Configuration

Edit `src/shared/Config.lua` to tune:
- Stamina regen rates
- Combat timings
- Posture system values
- Player movement speeds

## Combat Stats (Arthur)

**Base Stats**
- Health: 100
- Walk Speed: 16
- Jump Power: 50

**M1 Combo**
- 4-hit chain
- 0.5s combo window
- 0.35s hitstun

**Dash**
- Distance: 16 studs
- I-frames: 0.07s
- Cooldown: 0.3s
- Stamina cost: 15

**Block**
- 75% damage reduction
- Perfect parry window: 0.18s
- Guard break at 100 posture

## License

This is a refactored version of the original BG Game codebase.

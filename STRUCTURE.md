# Codebase Structure Guide

## Module Dependency Graph

```
Server:
Init.server.lua
├── Attack.lua → (Config, State, Cooldown, Hitbox, Registry)
├── Block.lua → (Config, State, Registry)
├── Dash.lua → (Config, State, Cooldown, Registry)
├── Ability.lua → (State, Cooldown, Hitbox, Registry)
└── Passive.lua → (State, Registry)

Client:
Init.client.lua
├── Client.lua → (State, Cooldown, Registry, Input, Animation, VFX)
├── Input.lua → (no dependencies)
├── Animation.lua → (Registry)
├── VFX.lua → (ArthurVFX)
└── Lock.lua → (no dependencies)

Shared:
├── Config.lua
├── State.lua → (Config)
├── Cooldown.lua
├── Hitbox.lua
├── Registry.lua → (Arthur)
└── ArthurVFX.lua
```

## File Responsibilities

### Shared Modules (ReplicatedStorage)

**Config.lua**
- Central configuration for all combat values
- Stamina, posture, cooldowns, player defaults
- Single source of truth for tuning

**State.lua**
- Player state management (Idle, Attacking, Blocking, etc.)
- Character selection per player
- Stamina and posture tracking
- Data cleanup on player leave

**Cooldown.lua**
- Centralized cooldown tracking
- Check if action is ready
- Set cooldown durations
- Get remaining time

**Hitbox.lua**
- Hitbox detection utilities
- BoxCast and Sphere detection
- Character/Player lookup helpers

**Registry.lua**
- Character data registry
- Auto-loads character modules
- Get character data by name

**Arthur.lua**
- Complete character data for Arthur
- Stats, abilities, animations, timings
- Data-only, no logic

**ArthurVFX.lua**
- VFX functions for Arthur
- Hit effects, dash trails, block shields
- Called by client VFX handler

### Client Scripts (StarterPlayerScripts)

**Init.client.lua**
- Entry point for client
- Waits for remotes
- Initializes Client and Lock modules

**Client.lua**
- Main client controller
- Sets up remotes
- Coordinates Input, Animation, VFX handlers
- Listens for server events

**Input.lua**
- Handles all player input
- Keybind definitions
- Fires remotes to server

**Animation.lua**
- Loads and plays animations
- Manages animation tracks
- Gets animations from character data

**VFX.lua**
- Plays visual effects
- Loads character VFX modules
- Routes VFX calls to appropriate handler

**Lock.lua**
- Target lock (Tab key)
- Combat lock (auto during combat)
- Camera control
- Character orientation

### Server Scripts (ServerScriptService)

**Init.server.lua**
- Entry point for server
- Creates remote events
- Initializes handlers
- Player setup/cleanup
- Stamina/posture regen loop

**Attack.lua**
- M1 combo handler
- Hitbox creation
- Damage calculation
- Knockback/hitstun
- Combo tracking

**Block.lua**
- Block state management
- Parry window tracking
- Guard break detection

**Dash.lua**
- Dash execution
- Stamina consumption
- I-frame implementation
- Cooldown management

**Ability.lua**
- Ability slot handler (1-4)
- Stamina checks
- Cooldown management
- Basic hitbox execution

**Passive.lua**
- Passive ability tracking
- Stack management (Arthur's Ether Resonance)
- Buff activation

## Data Flow Examples

### M1 Attack Flow

```
1. Player clicks → Input.lua
2. Input.lua → Remotes.Attack:FireServer()
3. Server → Attack.lua:OnAttack()
4. Attack.lua:
   - Validates state
   - Checks cooldown
   - Creates hitbox
   - Processes hits
   - Updates state
5. Server → Remotes.Hit:FireAllClients()
6. Clients → VFX.PlayHitEffect()
           → Animation.PlayHit()
```

### Blocking Flow

```
1. Player holds F → Input.lua
2. Input.lua → Remotes.Block:FireServer(true)
3. Server → Block.lua:StartBlock()
4. Block.lua:
   - Sets blocking state
   - Enables parry window
5. Server → Remotes.State:FireClient()
6. Client → Updates local state
```

### Dash Flow

```
1. Player presses Q → Input.lua
2. Input.lua → Remotes.Dash:FireServer()
3. Server → Dash.lua:OnDash()
4. Dash.lua:
   - Checks stamina
   - Applies velocity
   - Activates i-frames
   - Sets cooldown
5. No client event needed (physics replicated)
```

## Adding New Features

### New Character

1. Create `src/shared/characters/NewChar.lua`
2. Copy Arthur's structure, modify values
3. Create `src/shared/vfx/NewCharVFX.lua`
4. Add to Registry.Init()

### New Ability

1. Add to character's `Abilities` array
2. Add data to character's `AbilityData` table
3. Implement logic in `Ability.lua:OnAbility()`
4. Add VFX to character VFX module

### New Combat Action

1. Add remote in `Init.server.lua`
2. Create handler module in `src/server/`
3. Add input binding in `Input.lua`
4. Add VFX in character VFX module

## Optimization Tips

- Hitbox detection is server-authoritative
- VFX plays locally for performance
- Animations replicate automatically via Humanoid
- State changes broadcast selectively
- Cooldowns tracked server-side only

## Common Issues

**"Remotes not found"**
- Server Init.server.lua must run first
- Client waits up to 10 seconds

**"Animations not playing"**
- Check animation IDs in character data
- Ensure Animator exists under Humanoid

**"Hitbox not hitting"**
- Verify HumanoidRootPart exists
- Check hitbox size/offset in character data
- Enable Hitbox.Debug for visualization

**"VFX not showing"**
- Check VFX module is loaded
- Verify function names match character data
- Look for errors in VFX module

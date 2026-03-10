# Fe-Runner Core Rulebook - Gameplay Mechanics Analysis

> Source: Fe-Runner Core Rulebook (v Pre-Alpha 8/10/2024, 160 pages)
> Purpose: Document gameplay flows and tracking requirements to evaluate how well the DartRPG companion app supports them.

---

## 1. Campaign Setup Flow ("Preparing to Jack In")

The recommended setup order (p.40):

1. **Choose Your Truths** (p.40-47) - Select or roll on 8 truth categories that define the world:
   - Net Dependency, Previous Tech, Modern Tech, Iron Vows, Digital Crimes, Magic, Artificial Intelligence, Viruses/Worms/Botnets
   - Each has 3 options (roll d100) plus a Quest Starter per option
   - **App tracking needed**: Store selected truths per game/campaign

2. **Setup Factions** (p.48-49) - Create at least 2 corporate + 2 government factions:
   - 3 types: Corporate, Government, Underground
   - Each faction needs: name, type, goals, primary product, origin story
   - Factions have relationships with each other
   - **App tracking needed**: Faction names, types, relationships, projects (clocks)

3. **Create Your Character** (p.49-51) - See Character Creation section below

4. **Setup Initial Network** (p.52) - Create 3 known nodes in the core segment:
   - For each: determine Segment, Node Type (via oracle), Node Popularity, Name
   - Link factions to nodes if relevant
   - **App tracking needed**: Node/location records with segment, type, popularity, faction links

5. **Set the Scene** (p.54) - Determine starting location, inciting incident, first quest

---

## 2. Character Creation Flow

### Steps (p.49-51):

1. **Give your character a handle** (online name) - optionally also a real name
2. **Select two Path assets** - from the paths table (d100, 50 options like Admin, Anarchist, Cryptologist, VX Author, etc.)
3. **Create a background vow** - long-term goal that drives the character
4. **Set your stats** - Distribute 3,2,2,1,1 across:
   - **Edge** (agility/reactions)
   - **Heart** (social/persuasion)
   - **Iron** (grit/endurance)
   - **Shadow** (stealth/deception)
   - **Wits** (problem-solving/intelligence)
5. **Set initial meters**:
   - Momentum: +2 (Max: +10, Reset: +2)
   - Health: +5
   - Spirit: +5
   - Supply: +5
6. **Create your backstory** (p.50-51) - can roll on backstory table (d100)
7. **Choose 3 assets + Rig asset** (total 4 assets to start):
   - Base Rig (free, not purchased with XP)
   - Enhancements (rig modules)
   - Paths (character life path)
   - Daemons (companion apps)

### Character Tracking Summary:
- Handle + real name
- 5 stats (Edge, Heart, Iron, Shadow, Wits)
- 3 condition meters (Health, Spirit, Supply) - each 0-5
- Momentum (current, max, reset) - range -6 to +10
- Impacts (checkboxes): Misfortunes (Wounded, Shaken, Unregulated), Lasting Effects (Permanently Harmed, Traumatized), Burdens (Doomed, Tormented, Indebted), Current Rig (Overheated, Infected)
- Assets (3 chosen + Base Rig) - each has 3 abilities, can be upgraded
- Background vow
- Legacy tracks: Quests, Bonds, Discoveries (each 10 boxes with XP counters)
- Experience points (earned via legacy tracks, spent on assets)

---

## 3. Core Dice Mechanics

### Action Rolls (p.7)
- Roll 1d6 (action die) + 2d10 (challenge dice)
- Action Score = action die + stat + adds (max 10)
- Compare action score to EACH challenge die individually:
  - **Strong Hit**: Beat both challenge dice
  - **Weak Hit**: Beat only one challenge die
  - **Miss**: Beat neither challenge die
- Ties go to the challenge dice (action score must BEAT, not equal)

### Matches (p.8)
- When both challenge dice show the same value = a **match**
- Adds narrative significance (twist, complication, or enhanced result)
- Some moves/assets have specific match outcomes

### Momentum (p.8-9)
- Range: -6 to +10
- Gained through move outcomes ("Take +X momentum")
- Lost via Lose Momentum move (-1, -2, or -3)
- **Burning Momentum**: After an action roll, replace action score with current momentum to improve result; then reset momentum to reset value
- **Negative Momentum**: If momentum is negative and matches action die value, action die is canceled
- Reset value defaults to +2, reduced by impacts (+1 with one impact, 0 with more than one)

### Progress Tracks (p.9-10)
- 10 boxes, filled based on challenge rank
- Ranks (boxes per mark): Troublesome (3), Dangerous (2), Formidable (1), Extreme (2 ticks), Epic (1 tick)
- 4 ticks = 1 box
- **Progress Rolls**: Count filled boxes as score, roll only challenge dice, compare (no momentum burn allowed)

### Legacy Tracks (p.10-11)
- 3 tracks: Quests, Bonds, Discoveries
- No rank - always 4 ticks per box
- When a box fills, make Earn Experience move (2 XP per box)
- Experience counters under each legacy box (2 per box)
- Completed tracks (10th box): Mark "10" bubble, clear and restart, earn at reduced rate (1 XP per box)

---

## 4. Session/Gameplay Loop

### Begin a Session (p.124)
When starting a session:
- Review/adjust flagged content (Set a Flag)
- Review or recap last session
- **Advance any campaign clocks** (roll to determine if they advance)
- Set the scene by envisioning character's current situation
- Optionally spotlight a new danger/opportunity/insight via flashback table
- All players take +1 momentum

### Core Gameplay Loop
The game is narrative-driven. The basic loop is:

1. **Narrate the fiction** - Describe what's happening, what you're doing
2. **Trigger a move when the situation is risky** - If not risky, just narrate
3. **Resolve the move** - Roll dice, interpret results
4. **Apply mechanical outcomes** - Adjust momentum, health, progress, etc.
5. **Narrate the outcome** - Describe what happens based on the result
6. **Repeat**

### Take a Break (p.125)
After resolving a progress move or completing an intense scenario:
- Reflect on what happened
- Choose: Continue (add +1 to next non-progress move) OR Stop for now (End a Session)

### End a Session (p.125)
- Reflect on events, identify missed opportunities
- If you strengthened ties to a connection: Develop Your Relationship
- If you moved forward on a quest: Reach a Milestone
- Note focus for next session, take +1 momentum

---

## 5. Move Categories and Key Moves

### Session Moves (p.124-125)
- **Begin a Session** - Setup, advance clocks, set scene
- **Set a Flag** - Content safety tool
- **Change Your Fate** - Adjust flagged content (Refrain, Refocus, Replace, Redirect, Reshape)
- **Take a Break** - Pause after intense moments
- **End a Session** - Wrap up, catch-up progress

### Adventure Moves (p.126-127)
- **Face Danger** - Core move for risky actions (roll +stat based on approach)
- **Secure an Advantage** - Prepare, assess, gain leverage
- **Gather Information** - Investigate, research, analyze evidence (roll +wits)
- **Compel** - Persuade or coerce someone (roll +heart/iron/shadow based on approach)
- **Aid Your Ally** - Help an ally (they get the benefits)

### Quest Moves (p.128-129)
- **Swear an Iron Vow** - Create a quest with a rank and progress track (roll +heart)
- **Reach a Milestone** - Mark progress on a quest when you achieve something significant
- **Fulfill Your Vow** - Progress roll to complete a quest; awards legacy track progress
- **Forsake Your Vow** - Abandon a quest (consequences follow)

### Connection Moves (p.130-131)
- **Make a Connection** - Start a new relationship (roll +heart)
- **Develop Your Relationship** - Mark progress on a connection
- **Test Your Relationship** - When relationship is tested (roll +heart)
- **Forge a Bond** - Progress roll to deepen a connection; awards bonds legacy track progress

### Combat Moves (p.132-134)
- **Enter the Fray** - Initiate combat, set objective and rank
- **Gain Ground** - Take action in a fight when in control
- **React Under Fire** - Respond to danger when in a bad spot
- **Strike** - Attack at close quarters (when in control)
- **Clash** - Fight back when in a bad spot
- **Take Decisive Action** - Progress roll to end a fight
- **Automate Attack** - Quick-resolve an entire encounter in one roll

### Exploration Moves (p.135-139) - **Fe-Runner Specific**
- **Infiltrate Segment** - Progress roll to enter a network segment
- **Map Route** - Plan a route to a new segment (creates a progress track with rank based on segment)
  - Core: Troublesome/Dangerous
  - Corporate: Dangerous/Formidable
  - Government: Formidable/Extreme
- **Gain Entry** - Break into a system node (roll +shadow/heart/wits)
- **Explore the System** - Navigate within a node's inner system (roll +edge/shadow/wits)
- **Locate Your Objective** - Progress roll to find what you're looking for
- **Find an Opportunity** - Discover something helpful while exploring
- **Reveal a Danger** - Encounter a risky situation within a system
- **Disconnect** - Leave a system/network (roll +edge/iron/shadow)

### Artifact Moves (p.140)
- **Develop an Artifact** - Create a special tool/virus/bot (roll +wits)
- **Utilize an Artifact** - Use an artifact's special feature (roll +stat based on approach)
- **Reverse Engineer an Artifact** - Learn an artifact's secrets (roll +wits)

### Suffer Moves (p.141-143)
- **Lose Momentum** - Suffer -1/-2/-3 momentum
- **Endure Harm** - Suffer health loss (-1/-2/-3); at 0 health, risk Wounded/Permanently Harmed
- **Endure Stress** - Suffer spirit loss (-1/-2/-3); at 0 spirit, risk Shaken/Traumatized
- **Companion Takes a Hit** - Companion suffers health loss
- **Sacrifice Power** - Suffer supply loss (-1/-2/-3); at 0 supply, mark Unregulated
- **Withstand Damage** - Rig suffers health loss; at 0, risk Overheated/Infected

### Recover Moves (p.144-146)
- **Sojourn** - Rest and recover when disconnected (roll +heart)
- **Heal** - Receive medical care when disconnected
- **Hearten** - Socialize and find peace (roll +heart)
- **Repair** - Fix rig or equipment (roll +wits); point-buy system for repairs
- **Recharge** - Restore power supply to rig

### Threshold Moves (p.147-148) - Last resort / death-spiral
- **Face Death** - When death is imminent (roll +heart)
- **Face Desolation** - When brought to brink of despair (roll +heart)
- **Overcome Destruction** - When rig is destroyed (progress roll on bonds legacy)

### Legacy Moves (p.149-150)
- **Earn Experience** - Fill a legacy box, take 2 XP
- **Advance** - Spend XP (3 for new asset, 2 to upgrade)
- **Continue a Legacy** - When character retires/dies, create a new character inheriting some legacy

### Fate Moves (p.151-152)
- **Ask the Oracle** - Resolve questions using yes/no table or oracle tables
- **Pay the Price** - Suffer consequences of failure (choose or roll d100)

---

## 6. Network Navigation & Location Tracking

### Network Structure
The net has 4 segments (p.19-20):
1. **The Core** - Public entry point, accessible to all. No Infiltrate Segment needed to access.
2. **Corporate Segment (CorpNet)** - Secure corporate networks. Connected to Core.
3. **Government Segment (GovNet)** - Military/government networks. Harder access.
4. **Underground Segment (DarkNet)** - Encrypted, decentralized. Accessed laterally from GovNet.

### Nodes (p.26)
- Servers/areas within each segment
- Can be clustered into groups (cities, regions)
- Have: name, segment, type (from oracle tables), popularity
- Players track discovered nodes and map network routes between them

### Navigation Flow
1. **Within same segment**: Use **Gain Entry** to access a node
2. **Crossing segments**: Use **Map Route** to create a progress track, then **Infiltrate Segment** when ready
3. **Inside a node**: Use **Explore the System** to navigate inner areas, **Find an Opportunity** / **Reveal a Danger** for discoveries
4. **Reaching objective**: Use **Locate Your Objective** (progress roll)
5. **Leaving**: Use **Disconnect** to exit safely

### Route Mapping (p.27-29)
- Players should track discovered nodes on their mapped routes
- Relay nodes/waypoints are nodes under player control ("Owned")
- Routes can branch within same segment
- Disconnecting loses route progress; reconnecting requires re-mapping
- Visual example uses Obsidian with folders per segment and a graph view

### What Players Track for Locations:
- Node name, segment, type, popularity
- Whether it's a relay/owned node
- Route progress tracks (with rank based on segment difficulty)
- System exploration progress tracks (when inside a node)
- Nodes of interest and notes about them

---

## 7. Quest/Vow Tracking

### Swear an Iron Vow (p.128)
- Write the vow
- Assign a rank (Troublesome through Epic)
- Creates a progress track
- Background vow is the character's initial long-term quest

### Quest Progress
- Mark progress via **Reach a Milestone** when:
  - Overcoming a critical obstacle
  - Gaining meaningful insight
  - Completing a perilous expedition
  - Acquiring a crucial item
  - Earning vital support
  - Defeating a notable foe
- Progress amount = boxes per rank of the vow

### Completing Quests
- **Fulfill Your Vow** (progress roll) when you think you've done enough
- Strong hit: Vow fulfilled, mark reward on quest legacy track
- Weak hit: More to do OR take reduced legacy reward
- Miss: Unexpected complication; choose to give up (Forsake) or recommit (raise rank)

### What the App Needs to Track:
- Active vows/quests with name, rank, progress track (10 boxes)
- Background vow (special - always present)
- Completed quests (for legacy track rewards)
- Forsaken quests

---

## 8. Clock Mechanics

### Campaign Clocks (p.54-55)
- Represent faction agendas, world events, looming dangers
- Can be 6-segment bar or 8-segment pie
- Positive, negative, or neutral
- **Advancing**: During Begin a Session, decide if clock should advance. Use Ask the Oracle yes/no table with appropriate odds.
- **Completing**: When filled, event triggers. Envision impact on setting.
- **Stopping**: Remove when event is resolved or no longer relevant.

### Tension Clocks (p.55-56)
- Represent immediate threats/deadlines within a scene
- 4-10 segments based on urgency
- **Advancing**: Fill a segment when you Pay the Price, encounter complications, dramatic failures, or on a match
- **Completing**: Threat materializes. Harrowing problem for character.
- **Stopping**: Remove when threat is escaped or resolved.

### Trace Clocks (p.56-57) - **Fe-Runner Specific**
- Special tension clocks for when someone is tracing your location
- Number of segments based on how many relays/waypoints you have
- Follows your mapped route back to you
- Each filled segment burns a relay node
- When complete: Violent disconnect, suffer moves, lose all mapped routes
- Can be stopped by disconnecting or eliminating the trace source

### What the App Needs to Track:
- Clock name, type (campaign/tension/trace)
- Number of segments
- Current fill level
- Associated context (faction, scene, etc.)
- Positive/negative/neutral (for campaign clocks)

---

## 9. Digital Encounters (Combat Flow)

### Encounter Flow (p.31-32):

**Initial Phase:**
1. Envision what the digital encounter looks like
2. Identify relationship (helpful or harmful?)
3. Determine awareness (who detected whom first?)
4. Determine reactions (what do both sides do first?)

**Approach Phase:**
- Quick resolution: Use Face Danger or Secure an Advantage (single roll)
- OR proceed to full Engagement Phase

**Engagement Phase:**
1. Set objective and rank (creates progress track)
2. Optionally set a tension clock for opponent's goal
3. **Enter the Fray** to begin
4. Loop: Envision actions, make combat moves (Strike, Clash, Gain Ground, React Under Fire)
5. Manage advantage (in control vs bad spot)
6. **Take Decisive Action** (progress roll) to resolve

**Finishing Phase:**
- End the fight, deal with results

**Automate Attack** (p.134): Skip the full combat, resolve in one roll for routine encounters.

### Malicious Entities (p.34-35)
- Not creatures but programs (viruses, bots, worms, AI)
- Generated via oracles: Scale, Basic Form, First Look, Behavior, Revealed Aspect
- Each has a difficulty rank and progress bar
- Sample entities: Sheller (Formidable), Leech (Dangerous), Glitch Gremlin (Formidable)

---

## 10. Connections/NPCs & Social Mechanics

### Connections (p.130-131)
- NPCs you form relationships with
- Each has: name, role, rank (determines progress track size)
- Progress tracked via **Develop Your Relationship**
- **Forge a Bond** (progress roll) to deepen into a lasting bond
- Bonds advance the Bonds legacy track

### Hanging Out (p.32)
- Downtime social activity
- Build relationships and bonds
- Use Hanging Out Oracle for activity ideas
- Can do when no threat clock is counting down

### Hubs (p.30)
- Social gathering nodes on the network
- Different types per segment (Supply nodes in CorpNet, Cantinas in GovNet, illegal activity in DarkNet)
- Use Hub Oracle for inspiration

### What the App Needs to Track:
- NPC/Connection name, role, rank
- Relationship progress track
- Bond status (yes/no)
- Notes about the connection

---

## 11. Rig & Equipment Tracking

### Base Rig (p.24)
- Standard core asset for every character
- Has its own Health meter (0-5)
- Can be overheated or infected (impact conditions)
- Has abilities: Overclocking (+1 momentum once per situation), Secure Enclave (store encrypted data)
- Cannot be shared between allies

### Modules (p.24)
- Additional rig assets (e.g., High-end GPU)
- Can be marked as broken to offset rig damage
- Flipped when broken, repaired via Repair move

### Supply = Power (p.24-25)
- Supply meter represents rig power
- At 0: mark UNREGULATED impact
- Must Recharge to restore
- Affects all online activities

### Fe (Currency) (p.25)
- Digital currency - abstract, not tracked in precise amounts
- Used narratively for goals, payments, resources
- No coin-counting mechanic

### What the App Needs to Track:
- Base Rig health meter
- Rig impact status (Overheated, Infected)
- Module assets and their broken/repaired status
- Supply meter

---

## 12. Factions & World Tracking

### Faction Types (p.48):
- **Corporate** - Mega corps, control economy
- **Government** - Enforcers, territorial power
- **Underground** - Shadow groups, hackers, rebels

### Faction Setup:
- Create at least 4 (2 corporate, 2 government)
- Each needs: name, type, influence level, leadership style, goals, quirks
- Relationships between factions (use Faction Relationships oracle)
- Underground factions discovered during play

### Faction Projects (p.33)
- Represented by campaign clocks
- Competing factions can have opposing clocks
- Player can aid or hamper faction objectives

### What the App Needs to Track:
- Faction name, type
- Relationship map/notes
- Faction projects (as campaign clocks)
- Faction notes/details

---

## 13. Journal/Narrative Recording Expectations

The rulebook doesn't prescribe a specific journaling format but implies continuous narrative recording:

- **Backstory** written during character creation (p.50)
- **Inciting incident** described at campaign start (p.54)
- **Session recaps** reviewed at Begin a Session
- **Move outcomes** narrated after each roll
- **Vow descriptions** when swearing Iron Vows
- **Node discoveries** noted when mapping routes
- **Encounter descriptions** during digital encounters
- **Flashbacks** can be scenes from character's perspective

The game's Ironsworn heritage emphasizes narrative-first play where every mechanical outcome should be interpreted through storytelling. The app should support quick note-taking alongside mechanical tracking.

---

## 14. Summary: What a Player Needs to Track

### Per Character:
- Name/handle, backstory
- 5 stats
- 3 condition meters (Health, Spirit, Supply)
- Momentum (current, max, reset)
- 10 impact checkboxes
- Assets (3 + Base Rig, with upgrade status)
- Legacy tracks (Quests, Bonds, Discoveries) with XP

### Per Game/Campaign:
- Selected world truths
- Factions (name, type, relationships, projects)
- Active quests/vows (with progress tracks)
- Connections/NPCs (with progress tracks)
- Network map (nodes by segment, routes, relay nodes)
- Campaign clocks
- Tension clocks (transient, per scene)
- Journal entries / session notes
- Artifacts discovered

### Per Session:
- Active scene context
- Current location (node, segment)
- Active tension clocks
- Combat state (if in encounter)
- Move results and narrative outcomes

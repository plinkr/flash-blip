# FLASH-BLIP

<img width="1800" height="540" alt="banner_flash-blip" src="https://github.com/user-attachments/assets/6f70c19d-98e8-4dd8-8321-8f71d00c383d" />

A fast-paced 2D game built with the LOVE framework. Dodge obstacles, survive as long as you can, and get the highest score.

The game is primarily oriented toward endless mode, where players aim for the highest possible score in an infinite survival challenge.

Levels are fully procedurally generated. The game features 100 unique levels, each built using a deterministic random seed to ensure consistent layouts of points and obstacles across runs. This replaces the previous 10 fixed levels with a scalable, replayable progression system that increases in difficulty and required blips from level 1 to 100.

https://plinkr.itch.io/flash-blip

*Inspired by the work of Kenta Cho*

## Technical Details

The endless mode initializes with random obstacle generation for replayability, drawing from procedural algorithms in [`game.lua`](game/game.lua). The game uses no external assets; all visuals are rendered using simple geometric shapes (e.g., rectangles, circles) via LÖVE's drawing primitives.

Fonts are custom-drawn as pixel-based matrices in [`font.lua`](game/font.lua), allowing for lightweight, code-generated typography without bitmap files.
Reference [`text.lua`](game/text.lua) for how text is rendered and positioned in-game.

Background music is generated procedurally using pure Lua code, via LÖVE's audio APIs and algorithmic composition(reference [`music.lua`](game/music.lua)), no audio assets are required. 


## How to Play

### Objective
Jump to the next point and dodge the obstacles while jumping, don't let the player's square circle reach the bottom of the screen, collect the powerups and try to achieve the highest score. In Arcade mode, you can try to beat all the levels. For detailed in-game explanations, access the HELP menu.

### Controls
- SPACE, RETURN, or left-click to blip/move to the next point.
- C or right-click to ping for powerup collection or phase shift when this powerup is active.
- ESC to pause, show the menu, or quit.
- Use the up and down arrow keys to navigate through menu options, and press Enter or Space to select one.
- R to restart.
- For Android, touch the screen to blip and hold the screen or use two simultaneous touches to ping. You can sweep with two fingers to scroll the levels or the help.

*You can also use a Game Controller.*

### Powerups
There are 6 in total: 3 active that the player activates on pickup, and 3 passive that provide ongoing benefits.

- **Active Powerups**:
  - Star: Grants 10 seconds of invulnerability, allowing safe passage through obstacles.
  - Hourglass: Shrinks and slows the orbiting obstacles around points, slows the player's fall scroll speed, and nearly stops the player below 80% of the screen height, lasting 10 seconds.
  - Phase Shift: Enables a larger faster ping that teleports the player to the next point upon contact with a ping or the next point, ignoring obstacles, lasting 10 seconds.

- **Passive Powerups**:
  - Bolt: Creates a lightning bolt around two-thirds of the way down the screen. When the player touches it, they are instantly teleported safely to the next point, preventing a fall to the bottom. The effect lasts for 30 seconds.
  - Score Multiplier: Multiplies the score by 4x while active, lasting 30 seconds.
  - Spawn Rate Boost: Doubles the rate of random powerup generation, lasting 30 seconds.

Powerups are collected via pinging (right-click, C key, or holding the screen in Android) or blipping over them.

### Difficulty Progression
Difficulty ramps up dynamically based on points scored, increasing obstacle rotation speed, density, and scrolling speed (reference scaling logic in [`game.lua`](game/game.lua) and [`main.lua`](game/main.lua)).

### Levels
The win condition is defined in [`level_definitions.lua`](game/level_definitions.lua) and affected by the level's difficulty, requiring a set number of blips (jumps to next points) to complete the level, endless mode has no win condition, the objective is to get high scores.

## Development Status
The game remains in active development. It now features 100 procedurally generated levels with deterministic random seeds, ensuring consistent layouts for each level across runs. An endless mode is also included, with procedurally generated circles, rotating obstacles, and powerups such as slow motion and teleportation. Scoring mechanics and intuitive menus are in place, and future updates may include an online scoreboard for tracking top scores and competitive progression.

## Installation and Running

### Prerequisites
Install [`LÖVE framework`](https://love2d.org/) (version 11.5 *Mysterious Mysteries* recommended).

### Clone the Repo
```
git clone https://github.com/plinkr/flash-blip.git
```

### Run
```
cd flash-blip/
love game/
```
from the project directory. No additional dependencies or assets needed.

### Releases
Pre-built releases for Linux, Windows, and Web are available in the [`GitHub Releases`](/../../releases) section. These are generated automatically using GitHub Actions for easy distribution without needing to install LÖVE manually.

## Contributing
Contributions are encouraged, particularly from LÖVE2D learners. Open issues for bugs or feature requests, or submit pull requests for improvements while preserving the no-external-assets approach.

## Screenshots

<div align="center">
  <p style="max-width:900px; margin:0 auto;">A few screenshots, click a thumbnail to open the full image.</p>
  <div style="margin-top:12px; overflow-x:auto; white-space:nowrap; padding:8px 4px; -webkit-overflow-scrolling:touch;">
    <a href="https://github.com/user-attachments/assets/269a75b3-9023-44f8-8178-8bd77dc633de" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/269a75b3-9023-44f8-8178-8bd77dc633de" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen10" />
    </a>
    <a href="https://github.com/user-attachments/assets/b3074879-0375-458b-a399-a3553bb64d5a" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/b3074879-0375-458b-a399-a3553bb64d5a" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen1" />
    </a>
    <a href="https://github.com/user-attachments/assets/7339ce10-9aed-43db-a4c8-f767d1471c1e" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/7339ce10-9aed-43db-a4c8-f767d1471c1e" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen2" />
    </a>
    <a href="https://github.com/user-attachments/assets/d64fcf5c-2614-4111-a199-8d2f3d4fb577" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/d64fcf5c-2614-4111-a199-8d2f3d4fb577" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen3" />
    </a>
    <a href="https://github.com/user-attachments/assets/974c3ee3-ef76-4e67-973a-a16381dff637" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/974c3ee3-ef76-4e67-973a-a16381dff637" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen6" />
    </a>
    <a href="https://github.com/user-attachments/assets/a4f72ff3-716b-4ec7-b9fc-482cb5570ead" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/a4f72ff3-716b-4ec7-b9fc-482cb5570ead" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen7" />
    </a>
    <a href="https://github.com/user-attachments/assets/f9d19003-1dd6-4cce-ae05-0a15bd2b6590" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/f9d19003-1dd6-4cce-ae05-0a15bd2b6590" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen8" />
    </a>
    <a href="https://github.com/user-attachments/assets/91302b32-f9a5-4494-a1e5-c87483779282" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/91302b32-f9a5-4494-a1e5-c87483779282" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen9" />
    </a>
    <a href="https://github.com/user-attachments/assets/4447f1a4-e363-49f7-ab39-d987e63229cf" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/4447f1a4-e363-49f7-ab39-d987e63229cf" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen5" />
    </a>
    <a href="https://github.com/user-attachments/assets/ec4d357d-b6aa-4399-8ccf-98d714fbea26" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/ec4d357d-b6aa-4399-8ccf-98d714fbea26" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen4" />
    </a>
  </div>
</div>

## License
MIT License. See the [`LICENSE`](LICENSE) file for details.

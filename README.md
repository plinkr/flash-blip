# FLASH-BLIP

<img width="1075" height="403" alt="banner_flash-blip" src="https://github.com/user-attachments/assets/140d63d6-e2fd-4abf-87cd-c4b646fce86e" />

A fast-paced 2D game built with the LÖVE framework. Dodge obstacles, survive as long as you can, and get the highest score.

The game is primarily oriented toward endless mode, where players aim for the highest possible score in an infinite survival challenge. Structured levels are a work-in-progress, with future plans to implement procedural generation for creating diverse, dynamic levels automatically.

*Inspired by the work of Kenta Cho*

## Technical Details

The endless mode initializes with random obstacle generation for replayability, drawing from procedural algorithms in [`game.lua`](game/game.lua). The game uses no external assets; all visuals are rendered using simple geometric shapes (e.g., rectangles, circles) via LÖVE's drawing primitives.

Fonts are custom-drawn as pixel-based matrices in [`font.lua`](game/font.lua), allowing for lightweight, code-generated typography without bitmap files.
Reference [`text.lua`](game/text.lua) for how text is rendered and positioned in-game.



## How to Play

### Objective
Jump to the next point and dodge the obstacles while jumping, don't let the player's square circle reach the bottom of the screen, collect the powerups and try to achieve the highest score. In Arcade mode, you can try to beat all the levels. For detailed in-game explanations, access the HELP menu.

### Controls
- SPACE, RETURN, or left-click to blip/move to the next point.
- C or right-click to ping for powerup collection or phase shift when this powerup is active.
- ESC to pause, show the menu, or quit.
- Use the up and down arrow keys to navigate through menu options, and press Enter or Space to select one.
- R to restart.

### Powerups
There are 6 in total: 3 active that the player activates on pickup, and 3 passive that provide ongoing benefits.

- **Active Powerups**:
  - Star: Grants 10 seconds of invulnerability, allowing safe passage through obstacles.
  - Hourglass: Shrinks and slows the orbiting obstacles around points, slows the player's fall scroll speed, and nearly stops the player below 80% of the screen height, lasting 10 seconds.
  - Phase Shift: Enables a larger ping that teleports the player to the next point upon contact with a ping or the next point, ignoring obstacles, lasting 10 seconds.

- **Passive Powerups**:
  - Bolt: Creates a lightning bolt at the bottom of the screen; if the player touches it, they are automatically teleported safely to the next point, preventing loss when reaching the screen bottom, lasting 30 seconds.
  - Score Multiplier: Multiplies the score by 4x while active, lasting 15 seconds.
  - Spawn Rate Boost: Doubles the rate of random powerup generation, lasting 30 seconds.

Powerups are collected via pinging (right-click or C key) or blipping over them.

### Difficulty Progression
Difficulty ramps up dynamically based on points scored, increasing obstacle rotation speed, density, and scrolling speed (reference scaling logic in [`game.lua`](game/game.lua) and [`main.lua`](game/main.lua)).

### Levels
The win condition is defined in [`level_definitions.lua`](game/level_definitions.lua) and affected by the level's difficulty, requiring a set number of blips (jumps to next points) to complete the level, endless mode has no win condition, the objective is to get high scores.

## Development Status
The game is still in active development as a work-in-progress. Currently, it features an endless mode with procedurally generated circles and rotating obstacles, a powerup system offering effects like slowing time and teleportation, scoring mechanics, and intuitive menu systems. There are also 10 levels with progressively increasing difficulty. In the future, we might add a scoreboard to track the top scores.

## Installation and Running

### Prerequisites
Install [`LÖVE framework`](https://love2d.org/) (version 11.5 *Mysterious Mysteries*) recommended.

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
    <a href="https://github.com/user-attachments/assets/1593a62a-8590-4551-9f17-ed79b0b1ba39" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/1593a62a-8590-4551-9f17-ed79b0b1ba39" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen1" />
    </a>
    <a href="https://github.com/user-attachments/assets/7dd738dd-45fc-4c48-a4fe-169169548616" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/7dd738dd-45fc-4c48-a4fe-169169548616" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen2" />
    </a>
    <a href="https://github.com/user-attachments/assets/43fbd806-da47-4d60-90bf-e46cb880158a" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/43fbd806-da47-4d60-90bf-e46cb880158a" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen3" />
    </a>
    <a href="https://github.com/user-attachments/assets/d91cb8f8-76d9-49c7-b172-8a73843078a9" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/d91cb8f8-76d9-49c7-b172-8a73843078a9" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen4" />
    </a>
    <a href="https://github.com/user-attachments/assets/4d2b08d9-3f9b-4140-904a-20aa65d193de" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/4d2b08d9-3f9b-4140-904a-20aa65d193de" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen5" />
    </a>
    <a href="https://github.com/user-attachments/assets/298ebb40-e2db-47c1-ba48-a09612d8c4ad" target="_blank" rel="noopener">
      <img src="https://github.com/user-attachments/assets/298ebb40-e2db-47c1-ba48-a09612d8c4ad" width="280" style="display:inline-block; margin-right:8px; border-radius:8px; box-shadow:0 6px 18px rgba(0,0,0,0.12);" alt="screen6" />
    </a>
  </div>
</div>

## License
MIT License. See the [`LICENSE`](LICENSE) file for details.

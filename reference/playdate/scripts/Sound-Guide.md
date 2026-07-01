# Sound.lua Simple Guide (Non-Technical)

This guide explains how sound works in this game in plain language.

## What Sound.lua is doing

Think of `Sound.lua` as one "sound control room" for the whole game.

Before: each scene talked directly to many sound files.
Now: scenes ask `Sound.lua` to play or stop sounds.

Why this helps:
- Easier to stay organized
- Easier to add new sounds
- Easier to keep volume/mode behavior consistent
- Less chance of sound bugs from scattered code

## The main methods (what they mean)

You will mostly use these:

- `Sound.playSFX("name")`
  - Plays a short one-shot sound effect.
  - Example: button click, card swipe.

- `Sound.stopSFX("name")`
  - Stops a specific sound effect.
  - Used for sounds that may be looping or repeating.

- `Sound.playMusic(loopStart, loopEnd)`
  - Starts background music and sets loop points.
  - If music is already playing, it keeps going and updates loop settings.

- `Sound.playAmbience()`
  - Starts ambience (rain in this project).

- `Sound.stopAmbience()`
  - Stops ambience.

- `Sound.setAmbienceVolume(value)`
  - Changes ambience loudness (from 0 to 1).

- `Sound.startCrankLoop()`
  - Starts crank sound loop while player is cranking.

- `Sound.stopCrankLoop()`
  - Stops crank loop.

- `Sound.setSoundMode(mode)`
  - Changes the audio mode:
  - `1` = Music + Rain
  - `2` = Music only
  - `3` = Rain only
  - This mode is saved for next time the player opens the game.

- `Sound.getSoundMode()`
  - Returns current mode (1, 2, or 3).

- `Sound.stopAll()`
  - Emergency stop for everything.

## What you should use in normal scene code

For most scene actions, use only:

- `Sound.playSFX("...")`
- `Sound.stopSFX("...")`

For title/menu/background behavior:

- `Sound.playMusic(...)`
- `Sound.playAmbience()`
- `Sound.setSoundMode(...)`

For crank gameplay:

- `Sound.startCrankLoop()` when crank starts moving
- `Sound.stopCrankLoop()` when crank stops

## How to add a new sound (step-by-step)

### 1) Put the sound file in the sound folder

Put your new file in the project sound assets folder with the other sound files.

### 2) Register it inside `Sound.lua`

In `Sound.init(...)`, add a new line in the `sfx` section.

Example:

```lua
sfx.page_flip = pd.sound.sampleplayer.new("sound/page_flip")
sfx.page_flip:setVolume(0.5)
```

Use a simple name like `page_flip`.

### 3) Call it from a scene

Where you want the sound to play:

```lua
Sound.playSFX("page_flip")
```

That is it.

## Simple copy/paste examples

Play button sound:

```lua
if pd.buttonJustPressed(pd.kButtonA) then
    Sound.playSFX("cards_fast2")
end
```

Start and stop crank loop:

```lua
if crankChange ~= 0 then
    Sound.startCrankLoop()
else
    Sound.stopCrankLoop()
end
```

Switch to rain only mode:

```lua
Sound.setSoundMode(3)
```

## Quick checklist before testing

- New sound file exists in project sound assets
- New sound is added in `Sound.init(...)`
- Scene calls `Sound.playSFX("your_name")`
- Build runs without errors
- You can hear the sound at the right moment in game

## If a sound does not play

Check these in order:

1. Is the file path correct in `Sound.init(...)`?
2. Is the sound name exactly the same in both places?
3. Did you call `Sound.playSFX("name")` in the scene event you expected?
4. Is volume too low?
5. Did build succeed after changes?

If still not working, ask someone to compare your new sound lines with an existing working sound like `cards_fast2`.

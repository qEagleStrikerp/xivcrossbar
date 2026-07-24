# XIVCrossbar (Enhanced Fork)

A Windower 4 addon that emulates Final Fantasy XIV's controller crossbar UI for FFXI.

This is an enhanced fork of [AliekberFFXI's xivcrossbar](https://github.com/AliekberFFXI/xivcrossbar) (originally based on SirEdeonX's xivhotbar) with several additions to the configuration UI, new combat indicators, custom action support, and many quality-of-life improvements.

You might find some of these changes useful, some might not really affect you. Depends on how much you want to customize your experience. These range from things I went "this would be useful," to "I'm tired of copy/pasting this multiple times in the XMLs" to "I wonder if this'll work? (it didn't)".

## Table of Contents

- [Major Upgrades](#major-upgrades)
  - [Spell, Weaponskill, and Job Ability Lockout Bars](#spell-weaponskill-and-job-ability-lockout-bars)
  - [Auto-Attack Swing Timer](#auto-attack-swing-timer)
  - [Custom Actions](#custom-actions)
  - [Quick XB Switch](#quick-xb-switch)
  - [Shared Environment](#shared-environment)
  - [Global and Local Icon Overrides](#global-and-local-icon-overrides)
  - [Readable XML Names](#readable-xml-names)
  - [In-Game Binder Enhancements](#in-game-binder-enhancements)
  - [AHK Companion Improvements](#ahk-companion-improvements)
- [Fixes and Minor Improvements](#fixes-and-minor-improvements)
- [Settings Reference](#settings-reference)
- [Chat Command Reference](#chat-command-reference)
- [Setup](#setup)
  - [Another Version of XivCrossbar](#another-version-of-xivcrossbar)
  - [First Time](#first-time)
- [Notes](#notes)
- [License](#license)
- [Credits](#credits)
- [Development Note](#development-note)

---

## Major Upgrades

### Spell, Weaponskill, and Job Ability Lockout Bars

This is a single visible "cooldown" bar that shows below the crossbar depending on what action you performed:

- **Spell lockout** — bluish-white during the bulk of the lockout, flashes a different color in the final ~15% of the time set. The default duration is 3.0 seconds (roughly the estimated lockout period, but seems to have a very small variance). This is purely to represent the period where you can NOT cast another spell. You can modify the duration to your liking in the setting `SpellLockoutIndicator.Duration`.
- **Weaponskill lockout** — 2.0 seconds, amber. During this period you can't really do anything else, and your auto-attack is also paused.
- **Job Ability lockout** — 2.0 seconds, red for the first 1.0s (full lockout) then green (you can perform another JA, WS or a spell at this point). Auto-attacks are paused for the whole 2 seconds, hence the distinction.

Each bar has its own settings group where you can modify the colors used, and an `Opacity` field. **Setting any indicator's `Opacity` to 0 hides just that bar** but leaves the other ones alone.

Setting Groups: `SpellLockoutIndicator`, `WeaponskillLockoutIndicator`, `JobAbilityLockoutIndicator`.

### Auto-Attack Swing Timer

A... very experimental setting. This was more of a "what happens if I do this?" and is by no means really meant to be taken seriously. But it's fun to watch sometimes. 
This bar sits right above the lockout bars from above, and it estimates your weapon swing delay from a rolling average of the most recent 10 swings. There's still some internal variance, so it's never *quite* exact. Divided in two segments of red/green of the calculated delay and the expected time to swing.

Shown only when engaged (weapon out).

Pauses automatically on:
- Weaponskills and Job Abilities (2-second freeze)
- Disabling debuffs: Sleep, Petrify, Stun, Terror, Charm

Settings: `AutoAttackIndicator`. Disabled by default due to its experimental nature, if you want to toy with it, just set `Opacity` to any value higher than 0. (220 is the default value for the other bars)

### Custom Actions

Editing XMLs not your thing? Got you covered. 
You can create `ex` actions from inside the game. Gearswap commands, other mods, whatever. Anything that you would send to the game with a windower command (`//`). Stored per-character in `CustomActions.xml`. These saved actions are job-agnostic. Any custom action you create will show up on the binder for you to assign to any slot of any job. 

If you do like editing XMLs, you can do that too. Just copy/paste a block and go at it.

Each entry has:
- **Alias** — what's shown when you bind the action to a crossbar
- **Name** — a unique name shown on the action binder, also acts as a unique key (i.e., no duplicates)
- **Command** — the raw Windower command that fires when the slot is pressed (**don't** include `//`)
- **Icon** (optional) — pulled from the active iconpack
- **Linked metadata** (optional) — borrow MP/TP cost, recast, and element from a real spell or job ability so the slot displays cost and recast indicators just like a native action, neat if you're using gearswap commands to act as specific spells/JAs/WSs for whatever reason

Manage custom actions through the in-game binder:
- **Create Custom Action** — wizard that walks you through the process: alias → name → command → icon → linked action → save
- **Edit Custom Action** — single review screen showing all fields, with options to revise text fields via chat command or pick new icon / linked action
- **Delete Custom Action** — picker → confirm

The text fields (alias, name, command) are entered via chat commands during the create or edit flow as prompted by the process:

```
//xcb ca a <alias>
//xcb ca n <name>
//xcb ca c <command>
```

Typing directly into the window (my first attempt) would "bleed" the keybinds to the game. Meaning you would move, sit, start typing in chat as well, etc. It was too confusing/annoying. There were also some other limitations with accepted characters that I didn't want to deal with. 

**Warning on Edit/Delete**: These two actions only modify the information stored in `CustomActions.xml`. So if you already have that action bound to your crossbar, you would need to reassign it (on edit), or manually remove it (on delete).

See [Global and Local Icon Overrides](#global-and-local-icon-overrides) below for more info regarding the icon selection process.

### Quick XB Switch

A new binder action type that creates a one-shot temporary crossbar switch — pressing the slot swaps to another set, and the next non-switch action you fire automatically reverts to the original. If you "chain" multiple of these it will go back to the very first one at the end.

The main difference between this and the original **Switch Crossbars** is just if you want to permanently switch into that set, or for a quick one-off. Useful for cleaner song, roll, whatever grouping without cluttering your "default" with your most common actions.

Shown in the action binder as "Quick XB Switch."

For those who like editing XMLs: `<type>switch</type>` with `<action>` set to the target set's kebab-cased name.

### Shared Environment

A 4th pinned crossbar set (alongside Default, Job-Default, and All-Jobs-Default) that's selectable like a regular set but **never participates in the icon-fallback chain**. Meaning, normally your current crossbar is a combination of the "default" sets with whatever you have in your active set, with the ones lower on the chain taking priority.

This bar sits completely on its own, and the actions shown there are only the ones you set there. Useful for character-wide commands (mounts, trusts, job change addon macros, common items, etc.) that you want available on every job without cluttering your actual sets. 

Stored per-character in `Shared.xml`.

Setting: `UseSharedSet` (default true). If you don't want to use it, just set to false.

### Global and Local Icon Overrides

Two new options in the action binder: **Change Icon** and **Global Icon Set**.

Change Icon allows you to select an action on your bar, and then use an in-game "explorer" to walk through your iconpack and select a new icon for it. This is the same as going to the specific job xml and editing the `<icon>` tag in that action.

Global Icon Set is the same process, but saves the values to `SharedIcons.xml` to persist across sets. Basically, if you like to use a specific image for a given spell, you can use this to avoid messing with the default data. 

The order of priority for solving which icon to show is the individual action (in your job xml), then the shared icons one, and finally whatever is the default in the addon.

You might notice a command window popping up for a flash when navigating through the folders. In order to get the folders/images and list them, this information is obtained through a simple command prompt:

- `dir /b /a:d "<full_path>" 2>nul`
- `dir /b /a:-d "<full_path>\*.png" 2>nul`

The full path is whatever is being accumulated as you go down folders, starting from the iconpack set in settings. The rest of the settings boil down to simply getting the names with no extra data, include/exclude subfolders (as necessary), and so on. The two commands are because folders and images need to be handled separately for rendering/logic reasons.

### Readable XML Names

If you don't mind editing XML files, the original addon used numbers to reference the clusters and icons and yes, you can memorize the order. But why do that when you can instead make them more readable?

- **Hotbars**: `hotbar_l`, `hotbar_r`, `hotbar_rl`, `hotbar_lr`, `hotbar_ll`, `hotbar_rr` (the trigger sequence that activates each)
- **Slots**: `slot_ll`, `slot_ld`, `slot_lr`, `slot_lu` (left cluster — d-pad), `slot_rl`, `slot_rd`, `slot_rr`, `slot_ru` (right cluster — face buttons)

This is a pure boundary translation — internal data structures are unchanged. Just makes editing the XMLs by hand a bit easier. If you are coming from another version of XivCrossbar, you don't need to worry about losing any data, everything will be ported over seamlessly. That being said, it's a one-way street. Make a backup of your data/hotbar folder first, in case you want to go back to another version. 

### In-Game Binder Enhancements

The configuration UI accessible via Minus/Share/Back gained several new top-level entries:

- **Change Icon** — replace the icon of an already-bound slot
- **Global Icon Set** — write a `SharedIcons.xml` entry from a slot's alias
- **Create / Edit / Delete Custom Action** — full management of `CustomActions.xml`
- **Quick XB Switch** — bind a one-shot temp-switch slot

Extras:
- **Trigger paging** — in any selector, L2-then-R2 = next page, R2-then-L2 = previous page
- **Instant Start menu hide** — when manually moving to another set, the window immediately closes when you let go off start
- **Saved offsets respected** — `<OffsetX>` / `<OffsetY>` in settings.xml are honored on reload

### AHK Companion Improvements

Couple of modifications to the AutoHotKey script (`ffxi_input.ahk`). I don't have access to any direct input devices, so I could not do anything with those:

- **Stuck Ctrl safety net** — if you happen to lose focus of the game (popup or whatever) while holding down a trigger, Ctrl would get stuck in Windows as well, which would lead to funny behavior
- **Focus recovery** — tab out of the game often (to the wiki, obviously), just press a face button to get focus back of the game. This press will *not* fire the action bound to it. So if you want to get focus back and open the main menu, you need to press that button twice essentially (obviously only when not in focus)
- **DirectInput script disabled by default** — just to avoid any issues with both scripts running together, if you're using the direct input, you can enable it in the function `start_controller_wrappers` inside `xivcrossbar.lua`.

---

## Fixes and Minor Improvements

- **Pre-Login Check** — if the addon loads before you select your character it would start throwing errors; not anymore!
- **Friendly slot/hotbar names accepted by chat commands** — `//xcb al`, `ic`, `set`, `clear`, `cp`, `mv` also accept the readable identifiers (`ll`, `rd`, `lu`, etc.) in addition to the original numeric form.
- **Hotbar 6 (`rr`) recognition fix** — the `TRIGGERS_TO_CROSSBAR` map had a duplicate-key typo that left `rr` unmapped and caused `lr` to instead target the wrong hotbar.
- **Slot icon initial size** — the `slot_icon` primitives initialized at 30x30 before, which sometimes caused an issue that on reload (or changing jobs) would make icons be smaller and not take the full space
- **Per-hotbar X/Y offset settings** — `HotbarOffsets.AlternatePress` (RL/LR pair) and `HotbarOffsets.DoublePress` (LL/RR pair) for fine-tuning hotbar positioning, place those clusters wherever you want now. The horizontal value is mirrored according to the side.
- **Stable XML diffs** — slot serialization is sorted, so re-saving an unchanged hotbar produces no diff noise.

---

## Settings Reference

If you're coming from another version of XivCrossbar, any new settings available here will just be added to your own, leaving the values that already existed untouched. 
These are the new settings added in this version:

| Setting | Purpose |
|---|---|
| `UseSharedSet` | Show/hide the Shared crossbar in the picker (default `true`) |
| `SpellLockoutIndicator.Duration` | Post-cast lockout in seconds (default `3.0`) |
| `SpellLockoutIndicator.Opacity` | 0–255; set to 0 to hide just the spell bar |
| `SpellLockoutIndicator.PrimaryColor` | RGB during the bulk of the lockout |
| `SpellLockoutIndicator.EndingFlashColor` | RGB during the final ~15% (set equal to PrimaryColor to disable the flash) |
| `WeaponskillLockoutIndicator` | Same shape as Spell, 2.0s amber |
| `JobAbilityLockoutIndicator` | Same shape as Spell, 2.0s red→green at 1.0s |
| `AutoAttackIndicator` | Same shape; controls the swing-timer bar, opacity set to 0 by default |
| `HotbarOffsets.AlternatePress.X` / `.Y` | Position offset for RL/LR hotbars |
| `HotbarOffsets.DoublePress.X` / `.Y` | Position offset for LL/RR hotbars |

---

## Chat Command Reference

All commands accept `//xivcrossbar`, `//xb`, or `//xcb` as the prefix.
The bulk of these can be done by editing the XMLs files manually as well, if you're into that.

### Crossbar set management
| Command | Purpose |
|---|---|
| `new <name>` | Create a new crossbar set (alias: `n`) |
| `rename <old> <new>` | Rename a set (alias: `rn`) |
| `deleteset <name>` | Delete a set and all its bindings (no shorthand to avoid mistakes) |
| `bar <name>` | Switch active set (aliases: `crossbar`, `hotbar`) |

### Slot binding management
| Command | Purpose |
|---|---|
| `set <env> <hb> <slot> ...` | Bind an action to a slot |
| `clear <env> <hb> <slot>` | Clear a slot binding |
| `cp <env> <hb> <slot> <dhb> <dslot>` | Copy a binding (alias: `copy`) |
| `mv <env> <hb> <slot> <dhb> <dslot>` | Move a binding (alias: `move`) |
| `icon <env> <hb> <slot> <icon>` | Set a slot's icon (alias: `ic`) |
| `alias <env> <hb> <slot> <text>` | Set a slot's caption (aliases: `al`, `caption`) |

### Custom Actions (only valid during a Create/Edit flow in the binder)
| Command | Purpose |
|---|---|
| `ca <a\|n\|c> <value>` | Set alias / name / command field (alias: `custom`) |

### Other
| Command | Purpose |
|---|---|
| `reload` | Reload the active hotbar |
| `remap` | Rerun gamepad setup |
| `regenerate` | Rebuild cached resource files |
| `help` | Show full help menu (alias: `?`) |

### Identifiers
- **Hotbars**: `l`, `r`, `rl`, `lr`, `ll`, `rr` (or `1`–`6`) - order in which you hit the triggers
- **Slots**: `ll`, `ld`, `lr`, `lu`, `rl`, `rd`, `rr`, `ru` (or `1`–`8`) - holding L/R trigger, then what direction dpad or face button you press

Reserved set names (cannot be renamed or deleted): `default`, `job-default`, `all-jobs-default`, `shared`.

---

## Setup 

### Another Version of XivCrossbar

1. Backup your xivcrossbar folder just in case (zip it, or move it ouside the windower\addons folder).

2. Download this repo, throw all contents into your new `xivcrossbar` folder inside windower\addons. (A replace all *should* be fine, but better if you start from scratch)

3. Copy over the `data` folder from your previous version. If you had custom images, then copy those as well into the images folder as needed. (not needed if you decided to just replace all)

4. On next load, missing settings will be added to your settings file, and any new xmls (custom actions, shared icons) will be created as well. Your job xmls will update to the new style (hotbar_ll, slot_du, etc) when they get recreated (on modification), but nothing should get lost.


### First Time

1. Install [AutoHotkey](https://www.autohotkey.com/) (v1).

    If you get an error with the `ffxi_input.ahk` when it tries to run, search for AutoHotKey Dash in your start menu, go into launch settings, and set to run all scripts with a specific interpreter, then point to `AutoHotKeyU64.exe` inside Program Files and whatever v1 version you're using. 

2. Enable the **Run** plugin in Windower.

3. In the Gamepad configuration tool for FFXI, make sure to leave `Select / Confirm`, `Cancel`, `Active Window / Window Options`, `Main Menu` and both `Macro Palette` unbound. These will be handled by the AutoHotKey script and the addon. Any other settings (`Autorun`, `Heal / Lock Target`) bind as you wish, just obviously don't re-use the face buttons and triggers.

4. In your `windower\scripts\init.txt` include the following line at the end:
    ```
    lua load xivcrossbar
    ```

5. Follow the in-game setup dialog. This should run automatically on first load, or with `//xivcrossbar setup`. 
   - **XInput controllers**: should work naturally (either if the device is XInput by default or with an emulation layer from software like DS4Windows, etc)
   - **Other DirectInput controllers**: you may need to edit button numbers in `ffxi_directinput.ahk`. Use the [JoystickTest](https://www.autohotkey.com/docs_1.0/scripts/JoystickTest.htm) script to find your button numbers, then change lines like `Joy10::` to `Joy4::` (and corresponding `GetKeyState` lines). And I can not help you here.

6. **Minus / Share / Back** opens and closes the action binder utility.

7. **Plus / Options / Start** brings up the crossbar set selector while held; use the d-pad to switch sets.

8. Once comfortable with button placement, consider switching to compact mode in settings to reclaim screen space.

9. If you want extra clusters in a given set, you can set `hotbar_number` in the settings to 4 or 6. Setting to 4 will enable the clusters by holding both triggers one after the other (R>L = 3, or RL, L>R = 4, or LR). Setting to 6 will also enable the clusters triggered by double-tapping a trigger (L twice = 5, or LL, R twice = 6, or RR).

---

## Notes

- The addon unbinds Ctrl+F1 through Ctrl+F12 because it uses those as gamepad proxies. Alt, Shift, or unmodified F-key bindings are unaffected. Ctrl is used (rather than Alt) because Alt has a tendency to get stuck on Alt-Tab. You can re-add your own Ctrl+F1 through Ctrl+F8 bindings by editing `function_key_bindings.lua`.
- D-pad inputs can only be captured by the addon when at least one trigger is held — without that, FFXI consumes them directly. This is mainly noticeable when navigating the action binder.
- All addon configuration is per-character. Hotbar XMLs live under `data/hotbar/<server>/<character>/`. CustomActions, Shared and SharedIcons XMLs are also here.

### Known issues

- **Phantom d-pad presses (rare)** — sometimes pressing a face button resulted in firing the equivalent direction on the d-pad (I.e., trying to use slot_rd would end up sending slot_ld). This was happening before I started making changes, but I could never consistently trigger it. The ahk script `ffxi_xinput_diagnostic.ahk` was made for that, to capture events. Not in use by default.

---

## License

MIT — see [LICENSE](LICENSE) for the full text.

Portions of this addon derive from `xivhotbar` by SirEdeonX, originally
licensed under BSD 3-Clause. The required BSD attribution is preserved in
[NOTICE](NOTICE).

---

## Credits

- Original `xivhotbar` — [SirEdeonX](https://github.com/SirEdeonX)
- `xivcrossbar` rewrite and gamepad layer — [Aliekber](https://github.com/AliekberFFXI), Aeliya
- This enhanced fork adds the features and fixes described above

## Development Note

Scripting languages are not my strong suite, more of a .NET person myself. That being said, I did use Claude (Anthropic's LLM) for a handful of various tasks in performing all of the above, not limited to:

- Bouncing ideas
- Implementing actual code 
- Saving me a hell of a lot of time not having to go through windower documentation
- Figuring out where a LOT of things were taking place in the addon when I first began modifying it
- Don't get me started on AutoHotKey...

Regardless of how much code I wrote or not for a given bullet point, I tested everything myself (lots of sortie and odyssey primarily) and any bugs/regressions were handled as they appeared.
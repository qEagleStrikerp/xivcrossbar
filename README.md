# XIVCrossbar
This is forked off of AliekberFFXI's xivcrossbar!

For changes, see further below.

Important TODOs for this Readme:
(1) Expand the `Settings Reference` section so it covers all available settings.
(2) Unify the sections so that it's better structured overall.

---

### Steps to get XIVCrossbar working:

1) Install Autohotkey (https://www.autohotkey.com/)

OR (for Steam Deck users)

1b) Add the following line to your init.txt Windower script, changing the path as appropriate to point to your FFXI_Input.sh:

    run C:/Windows/System32/cmd.exe /c start /unix /home/deck/Games/final-fantasy-xi-online/FFXI_Input.sh

2) Enable the "Run" plugin in Windower

3) Run FFXI Configuration tool and set up your gamepad to match ConfigureYourGamepadLikeThis.jpg. Green box = required to have set, Red box = required to leave blank, Yellow box = configure it the way you usually do.

4) There are two options to automatically load xivcrossbar. Either editing your gearswap, or adding the load command to windower.

    a) If you want to only use xivcrossbar for specific jobs then add the following to your Gearswap LUA for any jobs where you want to use the crossbar. If you already have these functions defined, simply add the "windower.send_command" line in each of them to the existing function.

    function user_setup()
        windower.send_command('lua load xivcrossbar')
    end

    function user_unload()
        windower.send_command('lua unload xivcrossbar')
    end

    function job_setup()
        windower.send_command('lua reload xivcrossbar')
    end

   OR
   
   b) In Windower's init.txt, add the line "lua load xivcrossbar". This will load xivcrossbar for all jobs. Windower executes each line, from top to bottom, of the file so keep in mind the order of loading addons. This should not conflict with any other.
   
6) Follow the instructions in the setup dialog shown in-game.

    a) If you're using an XInput controller, everything should Just Work.

    b) If you're using a DirectInput controller that is a Wired Fight Pad Pro for Nintendo Switch, everything should Just Work.

    c) If you're using a DirectInput controller that is something else, you may need to modify the button numbers in ffxi_directinput.ahk. You can use the AHK script at https://www.autohotkey.com/docs_1.0/scripts/JoystickTest.htm to determine what your button numbers are. In ffxi_directinput.ahk you shouldn't need to change ANY lines other than changing lines like `Joy10::` to `Joy4::`, and any corresponding lines like `if GetKeyState("Joy10")` to `if GetKeyState("Joy4")`, and so forth. Everything else can be configured through the addon in-game.

7) Minus button (Nintendo), Share button (PS4) or Back button (XBox) brings up the gamepad binding utility, and can also exit out of it.

8) Plus button (Nintendo), Options button (PS4) or Start button (XBox) brings up binding set selector as long as it is held down, and you can switch between different binding sets by using your dpad.

9) Once you're used to the button placement, I recommend updating your settings xml to use the compact layout, just to reclaim some screen real estate.

10) If you want a 4th crossbar in each set, you can set the crossbar number to 4 in settings, which will make the 3rd and 4th crossbars dependent on which trigger you press first. L -> R is Crossbar 4, and R -> L is Crossbar 3.

11) If you want to have 6 crossbars in each set, you can set the crossbar number to 6 in settings, do the same as above but also add Crossbar 5 (activated when you double-press L) and Crossbar 6 (activated when you double-press R).

12) Enjoy!

NOTE: The crossbar unbinds any existing bindings for Ctrl+F1 through Ctrl+F12 because it uses those buttons as proxies for the gamepad. Any Alt, Shift, or neutral bindings to F1-F12 will be unaffected. Ctrl is used for the bindings rather than Alt because Alt has a tendency to get "stuck" when Alt-Tabbing in and out, and can lead to accidental ability use. However, while Ctrl+F9 through Ctrl+F12 are completely locked down by this addon, you can re-add your Ctrl+F1 through Ctrl+F8 bindings by editing function_key_bindings.lua.

NOTE: in order to capture dpad inputs without affecting the underlying game, you will need to hold down at least one of the triggers for XIVCrossbar to be able to use its input. This should really only be noticeable when navigating the gamepad binding utility.

---

### Important Changes (qEagleStrikerp)
- If you want to use some of the newly added options but don't know where to find them, backup your `settings.xml`, delete the original one and let the addon re-build it. Then change the settings to your liking. If you want to enable the use of Hotbars 5 & 6, your `settings.xml` should look like this:

```xml
<settings>
    <global>
        <!-- ... -->
        <AutoHideExtraBars>true</AutoHideExtraBars>
        <Hotbar>
            <!-- ... -->
            <Number>6</Number>
        </Hotbar>
        <!-- ... -->
    </global>
</settings>
```

- XIVCrossbar has an amazing set of icons already, however, there are plenty of abilities and spells that could benefit from better looking ones. If you want to contribute some (e.g. by taking icons from FFXIV's crossbar), take a look at `resources/crossbar_abilities.lua` and `resources/crossbar_spells.lua`. E.g., the entry for Afflatus Misery states a custom icon path that says: `custom_icon = "abilities/afflatus-misery.png"`. That means, if you want to provide a better icon for it, place it here: `images/icons/iconpacks/default/abilities/afflactus-misery.png`. Note that all custom icons should be 40 x 40 px. If you have icons to contribute, please open up a Pull Request to share them with everyone!
- I added an alternative version of the Xinput AHK script that uses `R1` instead of `START` for switching crossbars, just like in FFXIV. You can find it under `/ahks`. Note that you will probably have to rename it to `ffxi_xinput.ahk` for it to work, at least I haven't gotten it to work without renaming.
- I also changed the UI to highlight spells and abilities that are eligible for Magic Bursts. Whenever a Skillchain is formed, the corresponding actions will be highlighted if able to Magic Burst. This also considers BLU's Azure Lore / Chain Affinity / Burst Affinity, SCH's Immanence, DRG's Smiting Breath and RUN's Swipe / Lunge. I haven't tested BRD, NIN and BST yet, if something doesn't work, please open up a new Github Issue.

![Magic Burst](readme_images/magic_burst.png?raw=true "Magic Burst")

---

### Important Changes (BlueSummersC)
- Added option in settings (AutoHideExtraBars) that will hide extra bars 5 & 6 until you double-tap `LT` or `RT`. It is **highly recommended** to enable this if you want to use the extra bars.
- Added Alternate Layout (UseAltLayout) that mimics FFXIV's alt layout, where the left side will always be dpad and right side will be face buttons. Note: This makes editing the xmls a litte more confusing, as it alternates what is shows. For example, from left to right on your screen you will now see hotbar_1 slots 1-4, then hotbar_2 slots 1-4, then hotbar_1 slots 5-8 and finally hotbar_2 slots 5-8. Keep that in mind if manually editing the xmls.

---

### Important Changes (Icydeath)
- If you want to auto-start the AHK script when booting up Windower, enable the 'Run' plugin via the Windower launcher. The AHK script should now start automatically. You should also edit your settings.xml and set `use_directinput` and `use_xinput`. Only set the one you want to use to `true`, the other one to `false`.
- New AHK files for Logitech F710, Flight Pad Pro and PS5 controllers.
- Added automatic crossbar switching for SMN. If there is a crossbar that has the same name as the avatar being casted (e.g. "ifrit"), it will automatically switch to that crossbar. When you use the Release command it will automatically switch back to the default crossbar.
- More new settings:

    `enable_superwarp_all [true/false] (default: false)`  
    Set to `true` to enable the `all` command when creating warp macros.

    `on_unload_killahk [true/false] (default: false)`  
    Set to `true` if you want to terminate the AHK scripts when the addon is unloaded. Only works if you are using the 'Run' plugin.

- Added ability to add an "Execute Command" (ex) placeholder and select its icon.

    `images/icons/iconpack/default/GENERATE_ICON_LIST.bat` - Run this batch file if you added new icons and you want to use them when creating a "Execute Command" via the GUI system.

- Added Superwarp macro creation. The screen allows you to pick either Survival guide or Home point areas.

---

### Important Changes (FionaBrightgrass)
Added GearSwap Macros. To add a gearswap macro, go to your Gearswap set and add the set: sets.gsmacro1 through sets.gsmacro8:
```lua
sets.gsmacro1 = {ring1 = "Facility Ring"}
```

Then go to XIVCrossBar's `resources/crossbar_abilities.lua` and set the icons:
```lua
["gsmacro1"] = { id = 1550, en = "gsmacro1", res_key = "macros", type = "gs", category = "ready", element = "Light", default_icon = "/images/icons/weapons/katana.png", custom_icon = "weaponskills/katana/zesho-meppo.png", mp_cost = 0, tp_cost = 0},
-- ...
["gsmacro8"] = { id = 1557, en = "gsmacro8", res_key = "macros", type = "gs", category = "ready", element = "Light", default_icon = "/images/icons/weapons/katana.png", custom_icon = "weaponskills/katana/zesho-meppo.png", mp_cost = 0, tp_cost = 0},
```

Finally open "XIVCrossBar\data\hotbar\SERVER\CHARACTER\Job-Subjob.Lua"
To set Slot4 to gsmacro 1, adjust it as follows: 
```xml
<slot_4>  
    <target>me</target>  
    <type>gs</type>  
    <action>gsmacro1</action>  
    <alias>CallThisAnythingUWant</alias>  
</slot_4>
```  
  
To add a cycle macro for Gearswap, follow this structure:  
```xml
<slot_4>
    <target>me</target>
    <type>gsc</type>
    <action>offenseMode</action>
    <alias>Offense Mode</alias>
</slot_4>
```

```lua
["cycle"] = { id = 1550, en = "offenseMode", res_key = "macros", type = "gsc", category = "ready", element = "Light", default_icon = "/images/icons/weapons/katana.png", custom_icon = "weaponskills/katana/zesho-meppo.png", mp_cost = 0, tp_cost = 0},
-- ...
["cycle8"] = { id = 1557, en = "defenseMode", res_key = "macros", type = "gsc", category = "ready", element = "Light", default_icon = "/images/icons/weapons/katana.png", custom_icon = "weaponskills/katana/zesho-meppo.png", mp_cost = 0, tp_cost = 0},
```

### Important changes (GrayFox)
- **Spell, Weaponskill, and Job Ability Lockout Bars**: This is a single visible "cooldown" bar that shows below the crossbar depending on what action you performed:  
    - **Spell lockout** — bluish-white during the bulk of the lockout, flashes a different color in the final ~15% of the time set. The default duration is 3.0 seconds (roughly the estimated lockout period, but seems to have a very small variance). This is purely to represent the period where you can NOT cast another spell. You can modify the duration to your liking in the setting `SpellLockoutIndicator.Duration`.  
    - **Weaponskill lockout** — 2.0 seconds, amber. During this period you can't really do anything else, and your auto-attack is also paused.  
    - **Job Ability lockout** — 2.0 seconds, red for the first 1.0s (full lockout) then green (you can perform another JA, WS or a spell at this point). Auto-attacks are paused for the whole 2 seconds, hence the distinction.
    
    Each bar has its own settings group where you can modify the colors used, and an `Opacity` field. **Setting any indicator's `Opacity` to 0 hides just that bar** but leaves the other ones alone.
    
    Setting Groups: `SpellLockoutIndicator`, `WeaponskillLockoutIndicator`, `JobAbilityLockoutIndicator`.

- **Custom Actions**: Editing XMLs not your thing? Got you covered. You can create `ex` actions from inside the game. Gearswap commands, other mods, whatever. Anything that you would send to the game with a windower command (`//`). Stored per-character in `CustomActions.xml`. These saved actions are job-agnostic. Any custom action you create will show up on the binder for you to assign to any slot of any job. 

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

- **Quick XB Switch**: A new binder action type that creates a one-shot temporary crossbar switch — pressing the slot swaps to another set, and the next non-switch action you fire automatically reverts to the original. If you "chain" multiple of these it will go back to the very first one at the end.

    The main difference between this and the original **Switch Crossbars** is just if you want to permanently switch into that set, or for a quick one-off. Useful for cleaner song, roll, whatever grouping without cluttering your "default" with your most common actions.

- **Shared Environment**: A 4th pinned crossbar set (alongside Default, Job-Default, and All-Jobs-Default) that's selectable like a regular set but **never participates in the icon-fallback chain**. Meaning, normally your current crossbar is a combination of the "default" sets with whatever you have in your active set, with the ones lower on the chain taking priority.

    This bar sits completely on its own, and the actions shown there are only the ones you set there. Useful for character-wide commands (mounts, trusts, job change addon macros, common items, etc.) that you want available on every job without cluttering your actual sets. 

    Stored per-character in `Shared.xml`.

    Setting: `UseSharedSet` (default true). If you don't want to use it, just set to false.

- **Global and Local Icon Overrides**: 
Two new options in the action binder, **Change Icon** and **Global Icon Set**.

    Change Icon allows you to select an action on your bar, and then use an in-game "explorer" to walk through your iconpack and select a new icon for it. This is the same as going to the specific job xml and editing the `<icon>` tag in that action.

    Global Icon Set is the same process, but saves the values to `SharedIcons.xml` to persist across sets. Basically, if you like to use a specific image for a given spell, you can use this to avoid messing with the default data. 

    The order of priority for solving which icon to show is the individual action (in your job xml), then the shared icons one, and finally whatever is the default in the addon.

    You might notice a command window popping up for a flash when navigating through the folders. In order to get the folders/images and list them, this information is obtained through a simple command prompt:

    - `dir /b /a:d "<full_path>" 2>nul`
    - `dir /b /a:-d "<full_path>\*.png" 2>nul`

    The full path is whatever is being accumulated as you go down folders, starting from the iconpack set in settings. The rest of the settings boil down to simply getting the names with no extra data, include/exclude subfolders (as necessary), and so on. The two commands are because folders and images need to be handled separately for rendering/logic reasons.

- **Readable XML Names**: If you don't mind editing XML files, the original addon used numbers to reference the clusters and icons and yes, you can memorize the order. But why do that when you can instead make them more readable?

    - **Hotbars**: `hotbar_l`, `hotbar_r`, `hotbar_rl`, `hotbar_lr`, `hotbar_ll`, `hotbar_rr` (the trigger sequence that activates each)
    - **Slots**: `slot_ll`, `slot_ld`, `slot_lr`, `slot_lu` (left cluster — d-pad), `slot_rl`, `slot_rd`, `slot_rr`, `slot_ru` (right cluster — face buttons)

    This is a pure boundary translation — internal data structures are unchanged. Just makes editing the XMLs by hand a bit easier. If you are coming from another version of XivCrossbar, you don't need to worry about losing any data, everything will be ported over seamlessly. That being said, it's a one-way street. Make a backup of your data/hotbar folder first, in case you want to go back to another version. 

- **Trigger paging**: In any selector, L2-then-R2 = next page, R2-then-L2 = previous page

---

### Settings Reference

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

### Chat Command Reference

All commands accept `//xivcrossbar`, `//xb`, or `//xcb` as the prefix.
The bulk of these can be done by editing the XMLs files manually as well, if you're into that.

#### Crossbar set management
| Command | Purpose |
|---|---|
| `new <name>` | Create a new crossbar set (alias: `n`) |
| `rename <old> <new>` | Rename a set (alias: `rn`) |
| `deleteset <name>` | Delete a set and all its bindings (no shorthand to avoid mistakes) |
| `bar <name>` | Switch active set (aliases: `crossbar`, `hotbar`) |

#### Slot binding management
| Command | Purpose |
|---|---|
| `set <env> <hb> <slot> ...` | Bind an action to a slot |
| `clear <env> <hb> <slot>` | Clear a slot binding |
| `cp <env> <hb> <slot> <dhb> <dslot>` | Copy a binding (alias: `copy`) |
| `mv <env> <hb> <slot> <dhb> <dslot>` | Move a binding (alias: `move`) |
| `icon <env> <hb> <slot> <icon>` | Set a slot's icon (alias: `ic`) |
| `alias <env> <hb> <slot> <text>` | Set a slot's caption (aliases: `al`, `caption`) |

#### Custom Actions (only valid during a Create/Edit flow in the binder)
| Command | Purpose |
|---|---|
| `ca <a\|n\|c> <value>` | Set alias / name / command field (alias: `custom`) |

#### Other
| Command | Purpose |
|---|---|
| `reload` | Reload the active hotbar |
| `remap` | Rerun gamepad setup |
| `regenerate` | Rebuild cached resource files |
| `help` | Show full help menu (alias: `?`) |

#### Identifiers
- **Hotbars**: `l`, `r`, `rl`, `lr`, `ll`, `rr` (or `1`–`6`) - order in which you hit the triggers
- **Slots**: `ll`, `ld`, `lr`, `lu`, `rl`, `rd`, `rr`, `ru` (or `1`–`8`) - holding L/R trigger, then what direction dpad or face button you press

Reserved set names (cannot be renamed or deleted): `default`, `job-default`, `all-jobs-default`, `shared`.

---

### Setup 

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

### Notes

- The addon unbinds Ctrl + F1 through Ctrl+F12 because it uses those as gamepad proxies. Alt, Shift, or unmodified F-key bindings are unaffected. Ctrl is used (rather than Alt) because Alt has a tendency to get stuck on Alt-Tab. You can re-add your own Ctrl+F1 through Ctrl+F8 bindings by editing `function_key_bindings.lua`.
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
- `xivcrossbar` rewrite and gamepad layer — [Aliekber](https://github.com/AliekberFFXI)
- Various modifications: Aeliya, [BlueSummersC](https://github.com/BluesummersC), [FionaBrightgrass](https://github.com/FionaBrightgrass), [grayfox2510](https://github.com/grayfox2510), Icydeath, [qEagleStrikerp](https://github.com/qEagleStrikerp), [Sylvebits](https://github.com/Sylvebits), [XerevNonori](https://github.com/XerevNonori)
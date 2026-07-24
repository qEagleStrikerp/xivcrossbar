local theme = {}

theme.apply = function (settings)
    local options = {}

    options.frame_skip = settings.FrameSkip or 0
    options.allow_stpc_for_self_targeted_actions = settings.AllowSTPCForSelfTargetedActions or false

    options.AutoCreateXML = settings.AutoCreateXML
    options.UseAltLayout = settings.UseAltLayout
    options.AutoHideExtraBars = settings.AutoHideExtraBars
    if settings.UseSharedSet == nil then
        options.UseSharedSet = true
    else
        options.UseSharedSet = settings.UseSharedSet
    end

    options.skillchain_window_opacity = settings.SkillchainIndicator.Opacity
    options.skillchain_waiting_color_red = settings.SkillchainIndicator.WindowWaitingColor.Red
    options.skillchain_waiting_color_green = settings.SkillchainIndicator.WindowWaitingColor.Green
    options.skillchain_waiting_color_blue = settings.SkillchainIndicator.WindowWaitingColor.Blue
    options.skillchain_open_color_red = settings.SkillchainIndicator.WindowOpenColor.Red
    options.skillchain_open_color_green = settings.SkillchainIndicator.WindowOpenColor.Green
    options.skillchain_open_color_blue = settings.SkillchainIndicator.WindowOpenColor.Blue

    -- Spell lockout (post-cast; default 3.0s, configurable)
    options.spell_lockout_duration = settings.SpellLockoutIndicator.Duration
    options.spell_lockout_opacity = settings.SpellLockoutIndicator.Opacity
    options.spell_lockout_primary_red = settings.SpellLockoutIndicator.PrimaryColor.Red
    options.spell_lockout_primary_green = settings.SpellLockoutIndicator.PrimaryColor.Green
    options.spell_lockout_primary_blue = settings.SpellLockoutIndicator.PrimaryColor.Blue
    options.spell_lockout_ending_red = settings.SpellLockoutIndicator.EndingFlashColor.Red
    options.spell_lockout_ending_green = settings.SpellLockoutIndicator.EndingFlashColor.Green
    options.spell_lockout_ending_blue = settings.SpellLockoutIndicator.EndingFlashColor.Blue

    -- Weapon Skill lockout (post-WS 2.0s)
    options.ws_lockout_opacity = settings.WeaponskillLockoutIndicator.Opacity
    options.ws_lockout_primary_red = settings.WeaponskillLockoutIndicator.PrimaryColor.Red
    options.ws_lockout_primary_green = settings.WeaponskillLockoutIndicator.PrimaryColor.Green
    options.ws_lockout_primary_blue = settings.WeaponskillLockoutIndicator.PrimaryColor.Blue

    -- Job Ability lockout (post-JA 2.0s, two phases)
    options.ja_lockout_opacity = settings.JobAbilityLockoutIndicator.Opacity
    options.ja_lockout_full_red = settings.JobAbilityLockoutIndicator.FullLockoutColor.Red
    options.ja_lockout_full_green = settings.JobAbilityLockoutIndicator.FullLockoutColor.Green
    options.ja_lockout_full_blue = settings.JobAbilityLockoutIndicator.FullLockoutColor.Blue
    options.ja_lockout_partial_red = settings.JobAbilityLockoutIndicator.PartialLockoutColor.Red
    options.ja_lockout_partial_green = settings.JobAbilityLockoutIndicator.PartialLockoutColor.Green
    options.ja_lockout_partial_blue = settings.JobAbilityLockoutIndicator.PartialLockoutColor.Blue

    -- Auto-attack swing timer
    options.aa_opacity = settings.AutoAttackIndicator.Opacity
    options.aa_paused_opacity = settings.AutoAttackIndicator.PausedOpacity
    options.aa_background_opacity = settings.AutoAttackIndicator.BackgroundOpacity
    options.aa_paused_background_opacity = settings.AutoAttackIndicator.PausedBackgroundOpacity
    options.aa_before_red = settings.AutoAttackIndicator.BeforeEstimateColor.Red
    options.aa_before_green = settings.AutoAttackIndicator.BeforeEstimateColor.Green
    options.aa_before_blue = settings.AutoAttackIndicator.BeforeEstimateColor.Blue
    options.aa_past_red = settings.AutoAttackIndicator.PastEstimateColor.Red
    options.aa_past_green = settings.AutoAttackIndicator.PastEstimateColor.Green
    options.aa_past_blue = settings.AutoAttackIndicator.PastEstimateColor.Blue

    options.iconpack = settings.iconpack
    options.is_compact = settings.iscompact
    options.button_background_alpha = settings.buttonbackgroundalpha or 150
    options.hotbar_number = settings.Hotbar.Number
    options.hide_empty_slots = settings.Hotbar.HideEmptySlots
    options.hide_action_names = settings.Hotbar.HideActionName
    options.hide_action_cost = settings.Hotbar.HideActionCost
    options.hide_action_element = settings.Hotbar.HideActionElement
    options.hide_recast_animation = settings.Hotbar.HideRecastAnimation
    options.hide_recast_text = settings.Hotbar.HideRecastText
    options.hide_battle_notice = settings.Hotbar.HideBattleNotice

    options.battle_notice_theme = settings.Theme.BattleNotice
    options.slot_theme = settings.Theme.Slot
    options.frame_theme = settings.Theme.Frame

    options.slot_opacity = settings.Style.SlotAlpha
    options.slot_spacing = settings.Style.SlotSpacing
    options.hotbar_spacing = settings.Style.HotbarSpacing
    options.offset_x = settings.Style.OffsetX
    options.offset_y = settings.Style.OffsetY

    -- Per-hotbar offsets (alternate-press and double-press pairs)
    options.alternate_press_offset_x = settings.HotbarOffsets.AlternatePress.X
    options.alternate_press_offset_y = settings.HotbarOffsets.AlternatePress.Y
    options.double_press_offset_x = settings.HotbarOffsets.DoublePress.X
    options.double_press_offset_y = settings.HotbarOffsets.DoublePress.Y

    options.feedback_max_opacity = settings.Color.Feedback.Opacity
    options.feedback_speed = settings.Color.Feedback.Speed
    options.disabled_slot_opacity = settings.Color.Disabled.Opacity

    options.font = settings.Texts.Font
    options.font_size = settings.Texts.Size
    options.font_alpha = settings.Texts.Color.Alpha
    options.font_color_red = settings.Texts.Color.Red
    options.font_color_green = settings.Texts.Color.Green
    options.font_color_blue = settings.Texts.Color.Blue
    options.font_stroke_width = settings.Texts.Stroke.Width
    options.font_stroke_alpha = settings.Texts.Stroke.Alpha
    options.font_stroke_color_red = settings.Texts.Stroke.Red
    options.font_stroke_color_green = settings.Texts.Stroke.Green
    options.font_stroke_color_blue = settings.Texts.Stroke.Blue
    options.mp_cost_color_red = settings.Color.MpCost.Red
    options.mp_cost_color_green = settings.Color.MpCost.Green
    options.mp_cost_color_blue = settings.Color.MpCost.Blue
    options.tp_cost_color_red = settings.Color.TpCost.Red
    options.tp_cost_color_green = settings.Color.TpCost.Green
    options.tp_cost_color_blue = settings.Color.TpCost.Blue
    options.text_offset_x = settings.Texts.OffsetX
    options.text_offset_y = settings.Texts.OffsetY

    options.controls_battle_mode = settings.Controls.ToggleBattleMode

    return options
end

return theme
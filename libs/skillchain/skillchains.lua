--[[
Copyright © 2017, Ivaar
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of SkillChains nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL IVAAR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
-- Based on the original addon by:
-- _addon.author = 'Ivaar'
-- _addon.command = 'sc'
-- _addon.name = 'SkillChains'
-- _addon.version = '2.20.08.25'

require('luau')
require('pack')
require('actions')

function build_module()
    local myself = {}

    local texts = require('texts')
    local skills = require('libs/skillchain/skills')

    local default = {}
    local message_ids = S{110,185,187,317,802}
    local skillchain_ids = S{288,289,290,291,292,293,294,295,296,297,298,299,300,301,385,386,387,388,389,390,391,392,393,394,395,396,397,767,768,769,770}
    local buff_dur = {[163]=40,[164]=30,[470]=60}
    local info = {}
    local resonating = {}
    local buffs = {}
    local is_logged_in = false

    if windower.ffxi.get_info().logged_in then
        if not info.job then
            local player = windower.ffxi.get_player()
            info.job = player.main_job
            info.player = player.id
            is_logged_in = true
        end
    end

    local skillchains = {'Light','Darkness','Gravitation','Fragmentation','Distortion','Fusion','Compression','Liquefaction','Induration','Reverberation','Transfixion','Scission','Detonation','Impaction','Radiance','Umbra'}

    local sc_info = {
        Radiance = {'Fire','Wind','Lightning','Light', lvl=4},
        Umbra = {'Earth','Ice','Water','Dark', lvl=4},
        Light = {'Fire','Wind','Lightning','Light', Light={4,'Light','Radiance'}, lvl=3},
        Darkness = {'Earth','Ice','Water','Dark', Darkness={4,'Darkness','Umbra'}, lvl=3},
        Gravitation = {'Earth','Dark', Distortion={3,'Darkness'}, Fragmentation={2,'Fragmentation'}, lvl=2},
        Fragmentation = {'Wind','Lightning', Fusion={3,'Light'}, Distortion={2,'Distortion'}, lvl=2},
        Distortion = {'Ice','Water', Gravitation={3,'Darkness'}, Fusion={2,'Fusion'}, lvl=2},
        Fusion = {'Fire','Light', Fragmentation={3,'Light'}, Gravitation={2,'Gravitation'}, lvl=2},
        Compression = {'Dark', Transfixion={1,'Transfixion'}, Detonation={1,'Detonation'}, lvl=1},
        Liquefaction = {'Fire', Impaction={2,'Fusion'}, Scission={1,'Scission'}, lvl=1},
        Induration = {'Ice', Reverberation={2,'Fragmentation'}, Compression={1,'Compression'}, Impaction={1,'Impaction'}, lvl=1},
        Reverberation = {'Water', Induration={1,'Induration'}, Impaction={1,'Impaction'}, lvl=1},
        Transfixion = {'Light', Scission={2,'Distortion'}, Reverberation={1,'Reverberation'}, Compression={1,'Compression'}, lvl=1},
        Scission = {'Earth', Liquefaction={1,'Liquefaction'}, Reverberation={1,'Reverberation'}, Detonation={1,'Detonation'}, lvl=1},
        Detonation = {'Wind', Compression={2,'Gravitation'}, Scission={1,'Scission'}, lvl=1},
        Impaction = {'Lightning', Liquefaction={1,'Liquefaction'}, Detonation={1,'Detonation'}, lvl=1},
    }

    -- Info about what elements resonate with a given skillchain
	local sc_elements = {
		Radiance = {Fire=true,Wind=true,Lightning=true,Light=true},
        Umbra = {Earth=true,Ice=true,Water=true,Dark=true},
        Light = {Fire=true,Wind=true,Lightning=true,Light=true},
        Darkness = {Earth=true,Ice=true,Water=true,Dark=true},
        Gravitation = {Earth=true,Dark=true},
        Fragmentation = {Wind=true,Lightning=true},
        Distortion = {Ice=true,Water=true},
        Fusion = {Fire=true,Light=true},
        Compression = {Dark=true},
        Liquefaction = {Fire=true},
        Induration = {Ice=true},
        Reverberation = {Water=true},
        Transfixion = {Light=true},
        Scission = {Earth=true},
        Detonation = {Wind=true},
        Impaction = {Lightning=true},
	}

    -- TODO: These don't match https://www.bg-wiki.com/ffxi/Chainbound_(Status)
    -- Is there something that needs to be udpated? If not, update this comment and explain the difference.
    local chainbound = {}
    chainbound[1] = L{'Compression','Liquefaction','Induration','Reverberation','Scission'}
    chainbound[2] = L{'Gravitation','Fragmentation','Distortion'} + chainbound[1]
    chainbound[3] = L{'Light','Darkness'} + chainbound[2]

    function aeonic_prop(ability, actor)
        if ability.aeonic and (ability.weapon == info.aeonic and actor == info.player and info.player ~= actor) then
            return {ability.skillchain[1], ability.skillchain[2], ability.aeonic}
        end
        return ability.skillchain
    end

    -- Checks for Skillchain properties
    function check_sc_props(old, new)
        for k = 1, #old do
            local first = old[k]
            local combo = sc_info[first]
            for i = 1, #new do
                local second = new[i]
                local result = combo[second]
                if result then
                    return unpack(result)
                end
                if #old > 3 and combo.lvl == sc_info[second].lvl then
                    break
                end
            end
        end
    end

    -- Checks for Magic Burst properties
	function check_burst_props(old, new)
        for k = 1, #old do
            local first = old[k]
            local combo = sc_elements[first]
            for i = 1, #new do
                local second = new[i]
                local result = combo[second]
                if result then
					return result
				end
            end
        end
    end

    -- TODO: Rename this to better reflect that it returns either a Skillchain or Magic Burst property
    myself.get_skillchain_result = function(id, resource)
        local result = nil
        local propertyType = nil

        if (skills[resource] ~= nil and skills[resource][id] ~= nil) then
            local ability = skills[resource][id]

            local now = os.clock()
            local targ = windower.ffxi.get_mob_by_target('t', 'bt')
            targ_id = targ and targ.id

            local reson = resonating[targ_id]

            if not reson then
                return result
            end

            local sc_timer = reson.times - now
            local mb_timer = reson.mb_window - now

            if (targ and targ.hpp > 0 and not reson.closed) then
                -- if the action has a Magic Burst property, check if it can burst
                if ability["element"] ~= nil and mb_timer > 0 and reson.step > 1 then
                    local prop = check_burst_props(reson.active, ability.element)
                    if prop then
                        result = prop
                        propertyType = "burst"
                    end
                -- if the action has a Skillchain property, check if it can form a Skillchain
                elseif ability["skillchain"] ~= nil and sc_timer > 0 and now >= reson.delay then
                    local lv, prop, aeonic = check_sc_props(reson.active, ability.skillchain)
                    if prop then
                        -- TODO: This looks like it doesn't work since AM is not defined anywhere.
                        -- This is probably a leftover from cutting out part of the original addon.
                        -- Fix this.
                        result = AM and aeonic or prop
                        propertyType = "skillchain"
                    end
                end
            end
        end

        return result, propertyType
    end

    myself.get_skillchain_window = function()
        local now = os.clock()
        local targ = windower.ffxi.get_mob_by_target('t', 'bt')
        targ_id = targ and targ.id

        local reson = resonating[targ_id]

        if (reson) then
            local remaining_delay = reson.delay - now
            if (now >= reson.delay) then
                remaining_delay = 0
            end

            local remaining_window = reson.times - now

            return remaining_delay, remaining_window
        else
            return 0, 0
        end
    end

    local next_frame = os.clock()

    myself.prerender = function()
        local now = os.clock()

        if now < next_frame then
            return
        end

        next_frame = now + 0.1

        for k, v in pairs(resonating) do
            if v.mb_window - now + 10 < 0 then
                resonating[k] = nil
            end
        end

        local targ = windower.ffxi.get_mob_by_target('t', 'bt')
        targ_id = targ and targ.id
        local reson = resonating[targ_id]
        local timer = reson and (reson.times - now) or 0

        if targ and targ.hpp > 0 and timer > 0 then
            if not reson.closed then
                reson.disp_info = ''
                local delay = reson.delay
                reson.timer = now < delay and
                    '\\cs(255,0,0)Wait  %.1f\\cr':format(delay - now) or
                    '\\cs(0,255,0)Go!   %.1f\\cr':format(timer)
            else
                resonating[targ_id] = nil
                return
            end
            reson.name = res[reson.res][reson.id].name
            reson.props = reson.props or not reson.bound and reson.active or 'Chainbound Lv.%d':format(reson.bound)
            reson.elements = reson.elements or reson.step > 1 and '(%s)':format(table.concat(sc_info[reson.active[1]], ', ')) or ''
        end
    end

    function check_buff(t, i)
        if t[i] == true or t[i] - os.time() > 0 then
            return true
        end
        t[i] = nil
    end

    function chain_buff(t)
        local i = t[164] and 164 or t[470] and 470
        if i and check_buff(t, i) then
            t[i] = nil
            return true
        end
        return t[163] and check_buff(t, 163)
    end

    categories = S{
        'weaponskill_finish',
        'spell_finish',
        'job_ability',
        'mob_tp_finish',
        'avatar_tp_finish',
        'job_ability_unblinkable',
    }

    function apply_properties(target, resource, action_id, properties, delay, step, closed, bound)
        local clock = os.clock()
        resonating[target] = {
            res=resource,
            id=action_id,
            active=properties,
            delay=clock+delay,
            times=clock+delay+8-step,
            mb_window=clock+10,
            step=step,
            closed=closed,
            bound=bound
        }
        if target == targ_id then
            next_frame = clock
        end
    end

    function action_handler(act)
        local actionpacket = ActionPacket.new(act)
        local category = actionpacket:get_category_string()

        if not categories:contains(category) or act.param == 0 then
            return
        end

        local actor = actionpacket:get_id()
        local target = actionpacket:get_targets()()
        local action = target:get_actions()()
        local message_id = action:get_message_id()
        local add_effect = action:get_add_effect()
        --local basic_info = action:get_basic_info()
        local param, resource, action_id, interruption, conclusion = action:get_spell()
        local ability = skills[resource] and skills[resource][action_id]

        if add_effect and conclusion and skillchain_ids:contains(add_effect.message_id) then
            local skillchain = add_effect.animation:ucfirst()
            local level = sc_info[skillchain].lvl
            local reson = resonating[target.id]
            local delay = ability and ability.delay or 3
            local step = (reson and reson.step or 1) + 1

            if level == 3 and reson and ability then
                level = check_sc_props(reson.active, aeonic_prop(ability, actor))
            end

            local closed = step > 5 or level == 4

            apply_properties(target.id, resource, action_id, {skillchain}, delay, step, closed)
        elseif ability and (message_ids:contains(message_id) or message_id == 2 and buffs[actor] and chain_buff(buffs[actor])) then
            apply_properties(target.id, resource, action_id, aeonic_prop(ability, actor), ability.delay or 3, 1)
        elseif message_id == 529 then
            apply_properties(target.id, resource, action_id, chainbound[param], 2, 1, false, param)
        elseif message_id == 100 and buff_dur[param] then
            buffs[actor] = buffs[actor] or {}
            buffs[actor][param] = buff_dur[param] + os.time()
        end
    end

    ActionPacket.open_listener(action_handler)

    myself.incoming_chunk = function(id, data)
        if (is_logged_in) then
            if id == 0x29 and data:unpack('H', 25) == 206 and data:unpack('I', 9) == info.player then
                buffs[info.player][data:unpack('H', 13)] = nil
            elseif id == 0x63 and data:byte(5) == 9 then
                local set_buff = {}
                for n=1,32 do
                    local buff = data:unpack('H', n*2+7)
                    if buff_dur[buff] or buff > 269 and buff < 273 then
                        set_buff[buff] = true
                    end
                end
                buffs[info.player] = set_buff
            end
        end
    end

    myself.job_change = function(job, lvl)
        job = res.jobs:with('id', job).english_short
        if job ~= info.job then
            info.job = job
        end
    end

    myself.zone_change = function()
        resonating = {}
    end

    myself.load = function()
        if windower.ffxi.get_info().logged_in then
            buffs[info.player] = {}
        end
    end

    myself.login = function()
        local player = windower.ffxi.get_player()
        info.job = player.main_job
        info.player = player.id
        is_logged_in = true
    end

    myself.logout = function()
        info = {}
        resonating = {}
        buffs = {}
        is_logged_in = false
    end

    return myself
end

return build_module()

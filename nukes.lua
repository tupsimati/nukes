--[[
Copyright © 2018, Nyarlko
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of EasyNuke nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Nyarlko, or it's members, BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name    = 'nukes'
_addon.author  = 'Nyarlko + modified'
_addon.version = '1.1.0'
_addon.commands = {'nukes','nuke','ez','ezn'}

require('sets')
require('tables')
require('strings')
local res = require('resources')
local handlers = {}

config = require('config')

local spells = windower.ffxi.get_spells()
local spell_recasts = T{}

local defaults = T{
	current_element = "fire",
	target_mode = "t"
}
settings = config.load(defaults)
debugmode = false

--state.Element = M{['description']='Offense Elemental', 'Lightning', 'Fire', 'Wind', 'Ice', 'Water', 'Earth', 'Dark', 'Light'}

elements = T{'lightning', 'fire', 'wind', 'light', 'ice', 'water', 'earth', 'dark'}
--elements = T{"fire","wind","thunder","light","ice","water","earth","dark"}
elements_dark = T{"ice","water","earth","dark"}
elements_light = T{"lightning","fire","wind","light"}
elements_index = 1
other_modes = S{"drain","aspir","absorb","cure"}

targets = T{"t","bt","stnpc",}
targets_index = 1

spell_tables = {}
spell_tables["fire"] = {"Fire","Fire II","Fire III","Fire IV","Fire V","Fire VI",}
spell_tables["fire"]["ga"] = {"Firaga","Firaga II","Firaga III","Firaja",}
spell_tables["fire"]["burst"] = {"Fire","Fire II","Fire III","Fire IV","Fire V","Fire VI","Firaja",}
spell_tables["fire"]["ra"] = {"Fira","Fira II","Fira III"}
spell_tables["fire"]["helix"] = {"Pyrohelix","Pyrohelix II"}
spell_tables["fire"]["am"] = {"Flare","Flare II"}
spell_tables["fire"]["shot"] = {"Fire Shot",}

spell_tables["earth"] = {"Stone","Stone II","Stone III","Stone IV","Stone V","Stone VI",}
spell_tables["earth"]["ga"] = {"Stonega","Stonega II","Stonega III","Stoneja",}
spell_tables["earth"]["burst"] = {"Stone","Stone II","Stone III","Stone IV","Stone V","Stone VI","Stoneja",}
spell_tables["earth"]["ra"] = {"Stonera","Stonera II","Stonera III"}
spell_tables["earth"]["helix"] = {"Geohelix","Geohelix II"}
spell_tables["earth"]["am"] = {"Quake","Quake II"}
spell_tables["earth"]["shot"] = {"Earth Shot",}

spell_tables["wind"] = {"Aero","Aero II","Aero III","Aero IV","Aero V","Aero VI",}
spell_tables["wind"]["ga"] = {"Aeroga","Aeroga II","Aeroga III","Aeroja",}
spell_tables["wind"]["burst"] = {"Aero","Aero II","Aero III","Aero IV","Aero V","Aero VI","Aeroja",}
spell_tables["wind"]["ra"] = {"Aerora","Aerora II","Aerora III"}
spell_tables["wind"]["helix"] = {"Anemohelix","Anemohelix II"}
spell_tables["wind"]["am"] = {"Tornado","Tornado II"}
spell_tables["wind"]["shot"] = {"Wind Shot",}

spell_tables["water"] = {"Water","Water II","Water III","Water IV","Water V","Water VI",}
spell_tables["water"]["ga"] = {"Waterga","Waterga II","Waterga III","Waterja",}
spell_tables["water"]["burst"] = {"Water","Water II","Water III","Water IV","Water V","Water VI","Waterja",}
spell_tables["water"]["ra"] = {"Watera","Watera II","Watera III"}
spell_tables["water"]["helix"] = {"Hydrohelix","Hydrohelix II"}
spell_tables["water"]["am"] = {"Flood","Flood II"}
spell_tables["water"]["shot"] = {"Water Shot",}

spell_tables["ice"] = {"Blizzard","Blizzard II","Blizzard III","Blizzard IV","Blizzard V","Blizzard VI",}
spell_tables["ice"]["ga"] = {"Blizzaga","Blizzaga II","Blizzaga III","Blizzaja",}
spell_tables["ice"]["burst"] = {"Blizzard","Blizzard II","Blizzard III","Blizzard IV","Blizzard V","Blizzard VI","Blizzaja",}
spell_tables["ice"]["ra"] = {"Blizzara","Blizzara II","Blizzara III"}
spell_tables["ice"]["helix"] = {"Cryohelix","Cryohelix II"}
spell_tables["ice"]["am"] = {"Freeze","Freeze II"}
spell_tables["ice"]["shot"] = {"Ice Shot",}

spell_tables["lightning"] = {"Thunder","Thunder II","Thunder III","Thunder IV","Thunder V","Thunder VI",}
spell_tables["lightning"]["ga"] = {"Thundaga","Thundaga II","Thundaga III","Thundaja",}
spell_tables["lightning"]["burst"] = {"Thunder","Thunder II","Thunder III","Thunder IV","Thunder V","Thunder VI","Thundaja",}
spell_tables["lightning"]["ra"] = {"Thundara","Thundara II","Thundara III"}
spell_tables["lightning"]["helix"] = {"Ionohelix","Ionohelix II"}
spell_tables["lightning"]["am"] = {"Burst","Burst II"}
spell_tables["lightning"]["shot"] = {"Thunder Shot",}

spell_tables["light"] = {"Banish","Banish II","Holy","Banish III",}
spell_tables["light"]["ga"] = {"Banishga","Banishga II"}
spell_tables["light"]["helix"] = {"Luminohelix","Luminohelix II"}
spell_tables["light"]["shot"] = {"Light Shot",}

spell_tables["dark"] = {"Impact"}
spell_tables["dark"]["ga"] = {"Comet"}
spell_tables["dark"]["helix"] = {"Noctohelix", "Noctohelix II"}
spell_tables["dark"]["shot"] = {"Dark Shot",}

spell_tables["cure"] = {"Cure","Cure II","Cure III","Cure IV","Cure V","Cure VI"}
spell_tables["cure"]["ga"] = {"Curaga","Curaga II","Curaga III","Curaga IV","Curaga V",}
spell_tables["cure"]["ra"] = {"Cura","Cura II","Cura III"} 
spell_tables["drain"] = {"Aspir","Aspir II","Aspir III","Drain","Drain II","Drain III"}
spell_tables["drain"]["ga"] = spell_tables["drain"]
spell_tables["drain"]["ra"] = spell_tables["drain"]
spell_tables["aspir"] = spell_tables["drain"]
spell_tables["aspir"]["ga"] = spell_tables["drain"]
spell_tables["aspir"]["ra"] = spell_tables["drain"]
spell_tables["absorb"] = {"Absorb-Acc","Absorb-TP","Absorb-Attri","Absorb-STR","Absorb-DEX","Absorb-VIT","Absorb-AGI","Absorb-INT","Absorb-MND","Absorb-CHR"}
spell_tables["absorb"]["ga"] = spell_tables["absorb"]
spell_tables["absorb"]["ra"] = spell_tables["absorb"]

spell_types = {}
spell_types[""] = {"","boom","nuke"}
spell_types["ga"] = {"ga","boomga","bga","nukega"}
spell_types["ra"] = {"ra","boomra","bra","nukera"}
spell_types["helix"] = {"he","ix", "helix"}
spell_types["am"] = {"am","boomam","nukeam","bam","nam"}
spell_types["burst"] = {"burst"}
spell_types["shot"] = {"shot"}


local indices = {
    lightning = 1,
	fire = 2,
    wind = 3,
    light = 4,
    ice = 5,
    water = 6,
    earth = 7,
    dark = 8,
}

function execute_spell_cast(spell_type, arg, target)
	local player = windower.ffxi.get_player()
	local targ = target or "<"..target_mode..">"
	
	debugchat("execute_spell_cast "..spell_type..' '..arg..' '..target)
    local current_spell_table = nil
    if spell_type == "" then
        current_spell_table = spell_tables[current_element]
    else
        current_spell_table = spell_tables[current_element][spell_type]
    end
	
    if current_spell_table == nil then
        debugchat("Invalid Spell.") return
    end
	
	if arg > #current_spell_table then
		arg = #current_spell_table
	end 
	
	debugchat("current_spell_table "..(current_spell_table[arg] or ''))
	local spell = res.spells:with('en', current_spell_table[arg])
	
	if spell then
		debugchat("spell ".. spell.en)
	else
		debugchat("spell invalid ".. arg)
	end
	
	
	if not can_cast_spell(spell,player) then
		execute_spell_cast(spell_type, arg - 1, target)
	else 
		windower.chat.input("/ma \""..current_spell_table[arg].."\" "..targ)
	end 
end

function echochat(str)
	windower.add_to_chat(206, str)
end

function debugchat(str)
	if debugmode then
		windower.add_to_chat(206, str)
	end
end

function can_cast_spell(spell, player)
	debugchat("spells ")
	if not spells[spell.id] then return false end
	debugchat("spell_recasts ")
	if spell_recasts[spell.id] > 0 then return false end
	debugchat("vitals ")
	if player.vitals.mp < spell.mp_cost then return false end
	
	local mlvl = player.main_job_level
	local slvl = player.sub_job_level
	local jp = player.job_points[string.lower(player.main_job)].jp_spent
	if jp > mlvl then mlvl = jp end

	local spell_main_job_lvl = spell.levels[player.main_job_id] or 9999
	local spell_sub_job_lvl = spell.levels[player.sub_job_id] or 9999
	-- debugchat('mj/sj '..tostring(mjlvl)..' '..tostring(sjlvl))
	-- debugchat('mlvl '..tostring(mlvl or -1))
	-- debugchat('sjid '..tostring(spell.levels[player.sub_job_id]))
	-- debugchat('slvl '..tostring(slvl))
	
	--if spell.levels[player.main_job_id] == nil then return false end
	--if spell.levels[player.sub_job_id] == nil then return false end
	debugchat("main or sub reqirements ".. spell_main_job_lvl ..'/'..mlvl ..'  ' ..spell_sub_job_lvl..'/'..slvl)
	if spell_main_job_lvl > mlvl and spell_sub_job_lvl > slvl then return false end
	--debugchat("sch requirements ".. tostring(spell.requirements) ..' ' ..tostring(T(player.buffs):contains(402)))
	debugchat("sch requirements ".. tostring(spell.requirements) ..' ' ..table.concat(player.buffs, ","))
	if player.main_job == 'SCH' and spell.requirements > 0 and T(player.buffs):contains(402) == false then return false end
	debugchat("ok! ")
	return true
end 

function command_mode(arg)
	arg = string.lower(arg)
	if elements:contains(arg) or other_modes:contains(arg) then
		current_element = arg
		windower.send_command("gs c set Element "..current_element)
		echochat("EZ Element Mode is now: "..string.ucfirst(current_element))
	else
		echochat("Invalid element")
	end
end

function command_nuke(...)
	local args = {...}
	local command = 'nuke'
	local spell_type = ''
	local tier = 6
	local target = nil
		
	for _,arg in pairs(args) do
		local dbg_arg = 'arg '..tostring(target)
		local to_num = tonumber(arg)
		if to_num then
			if to_num > 7 then
				target = to_num
				debugchat('arg targ'..arg..': '..tostring(target))
			else
				tier = to_num
				debugchat('arg tier '..arg..': '..tostring(tier))
			end
		else
			debugchat('arg type '..arg)
			for spelltypes, value in pairs(spell_types) do
				debugchat("table "..spelltypes)
				for ispell, cmdtype in pairs(value) do
					--debugchat("list "..cmdtype)
					if arg == cmdtype then
						debugchat('arg nuke '..arg)
						command = "nuke"
						spell_type = spelltypes
						if spell_type == 'ja' then
							tier = 1
						end
						break
					end 
				end
			end
		end
	end
		
	debugchat(table.concat({...}, ' '))
	debugchat('args '..#args)
	debugchat('cmd '..command)
	debugchat('tier '..tostring(tier))
	debugchat('target '..tostring(target))
	debugchat('element '..current_element)
		
	local mob = nil
	if tonumber(target) ~= nil then
		debugchat(target)
		debugchat("getID")
		mob = windower.ffxi.get_mob_by_id(target)
		debugchat("valid "..tostring(mob.valid_target))
	else
		debugchat("getT")
		if target == nil then
			target = "t"
		end
		mob = windower.ffxi.get_mob_by_target(target)
	end
	
	if mob == nil then 
		debugchat( "Invalid Target")
		return 
	end 
	
	debugchat("valid "..tostring(mob.valid_target))
	debugchat( "Spawn Type: "..mob.spawn_type)
	
	if mob.spawn_type ~= 16 then 
		return 
	end 
		
	debugchat(mob.name..' cid_'..tostring(mob.claim_id)..' npc_'..tostring(mob.is_npc)..' etype_'..tostring(mob.entity_type)..' spawntype_'..tostring(mob.spawn_type)..' status_'..tostring(mob.status)..' Index_'..tostring(mob.index))
	
	-- local srgs = table.concat({...}, ' ')
	-- debugchat("len: "..#args.. " "..srgs)
	
	spell_recasts = windower.ffxi.get_spell_recasts()
	
	debugchat("nuke "..spell_type)	
	execute_spell_cast(spell_type, tier, target)
end

function command_target(arg)
	if arg then
		arg = string.lower(arg)
		target_mode = arg
	else
		targets_index = targets_index % #targets + 1
		target_mode = targets[targets_index]    
	end
	echochat("Target Mode is now: "..target_mode)
end

function command_cycle(arg)
	if arg then
		arg = string.lower(arg)
	end
	if arg == nil then
		local details = ''
		if not elements:contains(current_element) then
			elements_index = 1
			--details = 'index=1 ' .. tostring(elements_index) ..' '
		else
			--details = string.format('%s (%d %s) ', details, elements_index, current_element)
			elements_index = indices[current_element]
			--details = string.format('%s (%d %d) ', details, elements_index, elements_index % 8)
			elements_index = (elements_index % 8) + 1
		end
		current_element = elements[elements_index]
		--details = string.format('%s (%d %s) ', details, elements_index, current_element)
		--print(details)
	elseif arg == "back" then
		if not elements:contains(current_element) then
			elements_index = 1
		else
			elements_index = indices[current_element]
			elements_index = elements_index - 1
		end
		if elements_index < 1 then
			elements_index = 8
		end
		current_element = elements[elements_index]
	elseif arg == "dark" then
		if not elements_dark:contains(current_element) then
			elements_index = 1
		else
			elements_index = elements_index % 4 + 1
		end
			current_element = elements_dark[elements_index]
	elseif arg == "light" then
		if not elements_light:contains(current_element) then
			elements_index = 1
		else
			elements_index = elements_index % 4 + 1
		end    
			current_element = elements_light[elements_index]
	elseif arg == "fusion" or "fus" then
		if current_element ~= "fire" and current_element ~= "light" then
			current_element = "fire"
		elseif current_element == "fire" then
			current_element = "light"
		elseif current_element == "light" then
			current_element = "fire"
		end
	elseif arg == "distortion" or arg == "dist" then
		if current_element ~= "ice" and current_element ~= "water" then
			current_element = "ice"
		elseif current_element == "ice" then
			current_element = "water"
		elseif current_element == "water" then
			current_element = "ice"
		end
	elseif arg == "gravitation" or arg == "grav" then
		if current_element ~= "earth" and current_element ~= "dark" then
			current_element = "earth"
		elseif current_element == "earth" then
			current_element = "dark"
		elseif current_element == "dark" then
			current_element = "earth"
		end
	elseif arg == "fragmentation" or arg == "frag" then
		if current_element ~= "lightning" and current_element ~= "wind" then
			current_element = "lightning"
		elseif current_element == "lightning" then
			current_element = "wind"
		elseif current_element == "wind" then
			current_element = "lightning"
		end
	end
	echochat( "EZ Element Mode is now: "..string.ucfirst(current_element))
	windower.send_command("gs c set Element "..current_element)
end

function command_show_current()
	debugchat( "----- Element Mode: "..string.ucfirst(current_element).." --- Target Mode: < "..target_mode.." > -----")
end

function command_debug(arg)
	if arg then
		if arg == 'on' then
			debugmode = true
		else
			debugmode = false
		end
	else
		debugmode = not debugmode
	end
	
	debugchat( "----- EZ Nukes Debug : "..tostring(debugmode))
end

handlers['nuke']	= command_nuke
handlers['element']	= command_mode
handlers['mode']	= command_mode
handlers['cycle']	= command_cycle
handlers['target']	= command_target
handlers['debug']	= command_debug
handlers['show']	= command_show_current
handlers['current']	= command_show_current
handlers['showcurrent']	= command_show_current


local function handle_command(cmd, ...)
    local cmd = cmd or 'nuke'
    if handlers[cmd] then
        local msg = handlers[cmd](unpack({...}))
        if msg then
            error(msg)
        end
    else
        error("Unknown command %s":format(cmd))
    end
end

windower.register_event('addon command', handle_command)

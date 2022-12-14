local idstr_anim_data = Idstring("anim_data")
local idstr_base = Idstring("base")
local idstr_upper = Idstring("upper_body")
local idstr_weapon_hold = Idstring("weapon_hold_l_arm")
local ik_displacement = {
	[Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4"):key()] = Vector3(0, -3, 1),
	[Idstring("units/payday2/weapons/wpn_npc_m4_yellow/wpn_npc_m4_yellow"):key()] = Vector3(0, -3, 1),
	[Idstring("units/payday2/weapons/wpn_npc_ak47/wpn_npc_ak47"):key()] = Vector3(0, 0, 2),
	[Idstring("units/payday2/weapons/wpn_npc_r870/wpn_npc_r870"):key()] = Vector3(0, 9, -2),
	[Idstring("units/payday2/weapons/wpn_npc_spas12/wpn_npc_spas12"):key()] = Vector3(0, 6, 0),
	[Idstring("units/payday2/weapons/wpn_npc_ksg/wpn_npc_ksg"):key()] = Vector3(0, 1, 0),
	[Idstring("units/payday2/weapons/wpn_npc_mp5/wpn_npc_mp5"):key()] = Vector3(0, -8, 2),
	[Idstring("units/payday2/weapons/wpn_npc_shepheard/wpn_npc_shepheard"):key()] = Vector3(0, -8, 2),
	[Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical"):key()] = Vector3(0, -6, 0),
	[Idstring("units/payday2/weapons/wpn_npc_sniper/wpn_npc_sniper"):key()] = Vector3(0, 6, 0),
	[Idstring("units/payday2/weapons/wpn_npc_saiga/wpn_npc_saiga"):key()] = Vector3(0, 2, -3),
	[Idstring("units/payday2/weapons/wpn_npc_lmg_m249/wpn_npc_lmg_m249"):key()] = Vector3(0, 2, -1),
	[Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli"):key()] = Vector3(0, 6, -1),
	[Idstring("units/payday2/weapons/wpn_npc_g36/wpn_npc_g36"):key()] = Vector3(0, -2, 0),
	[Idstring("units/payday2/weapons/wpn_npc_ump/wpn_npc_ump"):key()] = Vector3(0, -4, 1),
	[Idstring("units/payday2/weapons/wpn_npc_scar_murkywater/wpn_npc_scar_murkywater"):key()] = Vector3(0, 0, 0),
	[Idstring("units/pd2_dlc_chico/weapons/wpn_npc_sg417/wpn_npc_sg417"):key()] = Vector3(0, 0, -4)
}

local base_displacement = Vector3(-9, 23, -1)
local base_displacement_player = Vector3(-8, 0, -2)
local base_displacement_player_v = Vector3(-7, 8, -4)

local tmp_rot1 = Rotation()
local tmp_rot2 = Rotation()

local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()

local mrot_set = mrotation.set_yaw_pitch_roll

local mvec3_add = mvector3.add
local mvec3_copy = mvector3.copy
local mvec3_not_equal = mvector3.not_equal
local mvec3_rotate = mvector3.rotate_with
local mvec3_set = mvector3.set
local mvec3_set_static = mvector3.set_static
local mvec3_sub = mvector3.subtract

Hooks:PostHook(PlayerAnimationData, "init", "ik_init", function(self, unit)
	unit:set_extension_update_enabled(idstr_anim_data, false)

	-- Filter out menu and fps units
	local meta = unit:base() and getmetatable(unit:base())
	if not meta or meta ~= CopBase and meta ~= HuskCopBase and meta ~= TeamAIBase and meta ~= HuskTeamAIBase and meta ~= HuskPlayerBase then
		return
	end

	self._machine = unit:anim_state_machine()
	self._obj_hand = unit:get_object(Idstring("LeftHand"))
	self._modifier = self._machine:get_modifier(idstr_weapon_hold)
	unit:inventory():add_listener("anim_data", {"equip", "unequip"}, callback(self, self, "clbk_inventory"))
end)

-- aint nobody got time to restart constantly
--[[
local yaw = 0
local pitch = 0
Hooks:Add("GameSetupUpdate", "asdf", function (t, dt)
	if Input:keyboard():down(Idstring("left")) then
		yaw = yaw + dt * 45
		log("yaw", yaw, "pitch", pitch)
	elseif Input:keyboard():down(Idstring("right")) then
		yaw = yaw - dt * 45
		log("yaw", yaw, "pitch", pitch)
	elseif Input:keyboard():down(Idstring("up")) then
		pitch = pitch + dt * 45
		log("yaw", yaw, "pitch", pitch)
	elseif Input:keyboard():down(Idstring("down")) then
		pitch = pitch - dt * 45
		log("yaw", yaw, "pitch", pitch)
	end
end)]]

function PlayerAnimationData:update(unit)
	local upper_seg_rel_t = self._machine:segment_relative_time(idstr_upper)
	if self._machine:get_global("ntl") == 0 and (self.still or self.move or self.dodge) and not self.zipline and not self.act and (not self.upper_body_active or self.upper_body_empty or (self.switch_weapon or self.equip) and upper_seg_rel_t > 0.5 or self.recoil or self.upper_body_hurt) then
		if not self._modifier_on then
			self._machine:force_modifier(idstr_weapon_hold)
			self._modifier_on = true
		end

		local weapon = self._equipped_unit
		local rot = tmp_rot1
		local hand_rot = tmp_rot2

		weapon:m_rotation(rot)
		self._obj_hand:m_rotation(hand_rot)

		local adj_value = math.cos(hand_rot:pitch())
		local displacement = tmp_vec1
		mvec3_set(displacement, self._grip_offset)
		mvec3_rotate(displacement, rot)
		-- because a modifier with position enabled can only rotate the target bone we have to do this fuckery to account for the position difference between the LeftHand and a_weapon_left_front bones
		mvec3_set_static(tmp_vec2, -2 * adj_value, -5 * adj_value, 5 * adj_value)
		mrot_set(tmp_rot2, rot:yaw(), 0, 0)
		mvec3_rotate(tmp_vec2, tmp_rot2)
		mvec3_add(displacement, tmp_vec2)

		weapon:m_position(tmp_vec2)

		mvec3_add(displacement, tmp_vec2)
		
		--Draw:brush(Color.red:with_alpha(0.5)):sphere(displacement, 5)
		--Draw:brush(Color.red:with_alpha(0.5)):sphere(self._unit:get_object(Idstring("a_weapon_left_front")):position(), 5)

		mrot_set(rot, rot:yaw() + self._yaw, rot:pitch() + self._pitch, rot:roll())

		self._modifier:set_target_position(displacement)
		self._modifier:set_target_rotation(rot)
	elseif self._modifier_on then
		self._modifier_on = nil
		self._machine:allow_modifier(idstr_weapon_hold)
	end
end

function PlayerAnimationData:clbk_inventory(unit, event)
	if not alive(unit) then
		return
	end

	self._grip_offset = nil

	if event == "equip" then
		local weapon = unit:inventory():equipped_unit()

		self._equipped_unit = weapon
		self._yaw = 28
		self._pitch = -82

		local displacement = ik_displacement[weapon:name():key()]
		if displacement then
			-- NPC weapon hold displacement
			self._grip_offset = mvec3_copy(displacement)
			mvec3_add(self._grip_offset, base_displacement)
		else
			-- Player weapon hold displacement
			local weapon_parts = weapon:base()._parts
			if weapon_parts and not weapon:base().AKIMBO then
				if weapon:base()._assembly_complete then
					local rifle_hold = self._machine:get_global("rifle") > 0 or self._machine:get_global("bullpup") > 0
					local vgrip = managers.weapon_factory:get_part_from_weapon_by_type("vertical_grip", weapon_parts)
					local fgrip = not vgrip and (rifle_hold and managers.weapon_factory:get_part_from_weapon_by_type("underbarrel", weapon_parts) or managers.weapon_factory:get_part_from_weapon_by_type("foregrip", weapon_parts))
					local grip = vgrip or fgrip
					if grip and alive(grip.unit) and mvec3_not_equal(weapon:position(), grip.unit:position()) then
						local oobb = grip.unit:oobb()
						self._grip_offset = oobb:center()
						mvec3_sub(self._grip_offset, weapon:position())
						mvec3_rotate(self._grip_offset, weapon:rotation():inverse())
						local y = math.clamp(self._grip_offset.y + oobb:size().y * (vgrip and 0.5 or 0), 10, 28)
						local z = math.clamp(self._grip_offset.z - oobb:size().z * (fgrip and 0.5 or 0), -5, 3)
						mvec3_set_static(self._grip_offset, 0, y, z) -- limit offset to avoid stretchy arms and inaccurate oobbs
						--log(tostring(self._grip_offset))
						mvec3_add(self._grip_offset, vgrip and base_displacement_player_v or base_displacement_player)

						if vgrip then
							self._machine:set_global("bullpup", 1)
							self._yaw = 0
							self._pitch = 10
						else
							self._machine:set_global("bullpup", 0)
							self._machine:set_global("rifle", 1)
						end
					end
				else
					managers.enemy:add_delayed_clbk("clbk_inventory" .. tostring(unit:key()), callback(self, self, "clbk_inventory", unit, event), TimerManager:game():time() + 0.2)
				end
			end
		end
	end

	self:chk_update_state()
end

function PlayerAnimationData:on_anim_freeze(state)
	self._frozen = state
	self:chk_update_state()
end

function PlayerAnimationData:chk_update_state()
	local state = not self._frozen and self._grip_offset and true or false

	self._unit:set_extension_update_enabled(idstr_anim_data, state)
end

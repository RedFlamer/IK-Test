local idstr_anim_data = Idstring("anim_data")
local idstr_base = Idstring("base")
local idstr_upper = Idstring("upper_body")
local idstr_weapon_hold = Idstring("weapon_hold_l_arm")
local ik_displacement = {
	[Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4"):key()] = Vector3(0, -3, 7),
	[Idstring("units/payday2/weapons/wpn_npc_m4_yellow/wpn_npc_m4_yellow"):key()] = Vector3(0, -3, 7),
	[Idstring("units/payday2/weapons/wpn_npc_ak47/wpn_npc_ak47"):key()] = Vector3(0, 0, 8),
	[Idstring("units/payday2/weapons/wpn_npc_r870/wpn_npc_r870"):key()] = Vector3(0, 9, 4),
	[Idstring("units/payday2/weapons/wpn_npc_spas12/wpn_npc_spas12"):key()] = Vector3(0, 6, 6),
	[Idstring("units/payday2/weapons/wpn_npc_ksg/wpn_npc_ksg"):key()] = Vector3(0, 1, 6),
	[Idstring("units/payday2/weapons/wpn_npc_mp5/wpn_npc_mp5"):key()] = Vector3(0, -8, 8),
	[Idstring("units/payday2/weapons/wpn_npc_shepheard/wpn_npc_shepheard"):key()] = Vector3(0, -8, 8),
	[Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical"):key()] = Vector3(0, -6, 6),
	[Idstring("units/payday2/weapons/wpn_npc_sniper/wpn_npc_sniper"):key()] = Vector3(0, 6, 9),
	[Idstring("units/payday2/weapons/wpn_npc_saiga/wpn_npc_saiga"):key()] = Vector3(0, 6, 7),
	[Idstring("units/payday2/weapons/wpn_npc_lmg_m249/wpn_npc_lmg_m249"):key()] = Vector3(0, 2, 5),
	[Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli"):key()] = Vector3(0, 6, 5),
	[Idstring("units/payday2/weapons/wpn_npc_g36/wpn_npc_g36"):key()] = Vector3(0, -5, 6),
	[Idstring("units/payday2/weapons/wpn_npc_ump/wpn_npc_ump"):key()] = Vector3(0, -4, 7)
}

local base_displacement = Vector3(-10, 28, -5)

local tmp_vec1 = Vector3()

local mvec3_add = mvector3.add
local mvec3_not_equal = mvector3.not_equal
local mvec3_rotate = mvector3.rotate_with
local mvec3_set = mvector3.set

Hooks:PostHook(PlayerAnimationData, "init", "ik_init", function(self, unit)
		self._machine = self._unit:anim_state_machine()

		if self._machine:get_global("ntl") == 0 then -- get_modifier crashes if the modifier doesn't exist so just have a dumb bypass, sigh...
			return unit:set_extension_update_enabled(idstr_anim_data, false)
		end

		self._modifier = self._machine:get_modifier(idstr_weapon_hold)
	end
)

function PlayerAnimationData:update(unit)
	local weapon = unit:inventory():equipped_unit()
	if alive(weapon) and (not alive(self._equipped_unit) or self._equipped_unit ~= weapon) then
		self._equipped_unit = weapon
		self._weapon_displacement = ik_displacement[weapon:name():key()]
		local weapon_parts = weapon:base()._parts
		if weapon_parts and not weapon:base().AKIMBO then
			if weapon:base()._assembly_complete then
				local vgrip = managers.weapon_factory:get_part_from_weapon_by_type("vertical_grip", weapon_parts)
				local fgrip = managers.weapon_factory:get_part_from_weapon_by_type("foregrip", weapon_parts)
				local grip = vgrip or fgrip
				if grip and alive(grip.unit) and mvec3_not_equal(weapon:position(), grip.unit:position()) then
					self._weapon_grip = grip.unit
					self._grip_is_v = vgrip and true
				end
			else
				-- Wait til assembly is complete
				self._equipped_unit = nil
			end
		end
	end

	local upper_seg_rel_t = self._machine:segment_relative_time(idstr_upper)
	local anim_check = (self.still or self.move or self.dodge) and not self.zipline and (not self.upper_body_active or self.upper_body_empty or (self.switch_weapon or self.equip) and upper_seg_rel_t > 0.6 or self.recoil or self.upper_body_hurt)
	if (self._weapon_displacement or alive(self._weapon_grip)) and anim_check then
		if not self._modifier_on then
			self._machine:force_modifier(idstr_weapon_hold)
			self._modifier_on = true
		end

		local rot = weapon:rotation()
		local displacement = tmp_vec1
		
		-- default offset
		mvec3_set(displacement, base_displacement)

		if self._weapon_displacement then
			mvec3_add(displacement, self._weapon_displacement)
			mvec3_rotate(displacement, rot)
			mvec3_add(displacement, weapon:position())
		else
			mvec3_rotate(displacement, rot)
			mvec3_add(displacement, self._weapon_grip:position())
		end

		Draw:brush(Color.red:with_alpha(0.5)):sphere(displacement, 5)

		mrotation.set_yaw_pitch_roll(rot, rot:yaw(), rot:pitch() - 90, rot:roll())

		self._modifier:set_target_position(displacement)
		self._modifier:set_target_rotation(rot)
	elseif self._modifier_on then
		self._modifier_on = nil
		self._machine:allow_modifier(idstr_weapon_hold)
	end
end

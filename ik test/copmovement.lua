Hooks:PostHook(CopMovement, "on_anim_freeze", "ik_on_anim_freeze", function(self, state)
	self._ext_anim:on_anim_freeze(state)
end)

scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI}

event OnEffectStart(Actor target, Actor caster)
    Search_UI.ShowSearchPrompt()
endEvent

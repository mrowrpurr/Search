scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    ; Search2.LoadConfig()
    ; string[] searchProviders = Search2.GetSearchProviderNames()
endEvent

event OnEffectStart_Original(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()
endEvent

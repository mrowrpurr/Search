scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    Search.LoadConfig()
    string[] searchProviders = Search.GetSearchProviderNames()
    string providerName = Search_UI.GetUserSelection(searchProviders)
    Debug.MessageBox("Provide your query to search for " + providerName)
    string query = Search_UI.GetUserInput()
endEvent

event OnEffectStart_Original(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()
endEvent

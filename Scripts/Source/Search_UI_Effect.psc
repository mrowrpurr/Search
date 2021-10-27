scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    string query = Search_UI.GetUserInput()
    int results = Search.ExecuteQuery(query)
    JValue.writeToFile(results, "SearchResults.json")
    Search_UI_2.ShowSearch_Main(results)
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnEffectStart_Original(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()
endEvent

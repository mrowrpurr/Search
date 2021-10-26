scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    string query = Search_UI.GetUserInput()
    int results = Search.ExecuteQuery(query)
    Utility.WaitMenuMode(3)
    DisplayResults(results)
endEvent

function DisplayResults(int results)
    JValue.writeToFile(results, "SearchResults.json")
    Debug.MessageBox("Wrote to SearchResults.json")
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnEffectStart_Original(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()
endEvent

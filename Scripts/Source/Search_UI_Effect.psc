scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    DisplayResults(Search.ExecuteQuery(Search_UI.GetUserInput()))
endEvent

function DisplayResults(int results)
    string[] categoryNames = SearchResult.GetCategoryNames(results)
    Debug.MessageBox(categoryNames)
endFunction







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnEffectStart_Original(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()
endEvent

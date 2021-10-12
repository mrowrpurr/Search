scriptName ConsoleSearchUI_Search extends ActiveMagicEffect  

event OnEffectStart(Actor target, Actor caster)
    Show()
endEvent

function Show()
    string query = GetTextInput()
    ; Debug.MessageBox(ConsoleSearch.Help(query))
    ConsoleSearch.Search(query)
endFunction

string function GetTextInput()
    UITextEntryMenu textEntry = UIExtensions.GetMenu("UITextEntryMenu") as UITextEntryMenu
    textEntry.OpenMenu()
    return textEntry.GetResultString()
endFunction

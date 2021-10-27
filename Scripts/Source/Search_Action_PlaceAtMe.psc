scriptName Search_Action_PlaceAtMe extends ReferenceAlias  

event OnInit()
    RegisterForModEvent("Search_Action_PlaceAtMe", "OnPlaceAtMe")
endEvent

event OnPlayerLoadGame()
    RegisterForModEvent("Search_Action_PlaceAtMe", "OnPlaceAtMe")
endEvent

event OnPlaceAtMe(string eventName, int searchResults, string categoryName, int searchResultSet, int searchResult)
    string displayText = Search.GetResultDisplayText(searchResult)
    UITextEntryMenu textEntry = UIExtensions.GetMenu("UITextEntryMenu") as UITextEntryMenu
    textEntry.SetPropertyString("text", "1")
    textEntry.OpenMenu()
    int numberToPlace = textEntry.GetResultString() as int
    if numberToPlace
        string formId = JMap.getStr(JMap.getObj(searchResult, "data"), "formId")
        Form theForm = FormHelper.HexToForm(formId) 
        if theForm
            GetActorReference().PlaceAtMe(theForm, numberToPlace)
        endIf
    endIf
endEvent

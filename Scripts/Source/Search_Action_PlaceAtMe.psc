scriptName Search_Action_PlaceAtMe extends ReferenceAlias  

event OnInit()
    RegisterForModEvent("Search_Action_PlaceAtMe", "OnPlaceAtMe")
endEvent

event OnPlayerLoadGame()
    RegisterForModEvent("Search_Action_PlaceAtMe", "OnPlaceAtMe")
endEvent

event OnPlaceAtMe(string eventName, int searchResult)
    string displayText = Search.GetResultDisplayText(searchResult)
    Debug.MessageBox("This will now spawn " + displayText)
endEvent

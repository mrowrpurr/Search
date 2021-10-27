scriptName Search_Action_SpawnAll extends ReferenceAlias  

event OnInit()
    RegisterForModEvent("Search_Action_SpawnAll", "OnSpawnAll")
endEvent

event OnPlayerLoadGame()
    RegisterForModEvent("Search_Action_SpawnAll", "OnSpawnAll")
endEvent

event OnSpawnAll(string eventName, int searchResults, string categoryName)
    int searchResultSetCount = Search.GetSearchResultSetCount(searchResults)
    int i = 0
    while i < searchResultSetCount
        int searchResultSet = Search.GetNthSearchResultSet(searchResults, i)
        int categoryResultCount = Search.GetCategoryResultCountForSearchResultSet(searchResultSet, categoryName)
        int j = 0
        while j < categoryResultCount
            int result = Search.GetNthCategoryResultForSearchResultSet(searchResultSet, categoryName, j)
            string displayText = Search.GetResultDisplayText(result)
            string formId = JMap.getStr(JMap.getObj(result, "data"), "formId")
            Form theForm = FormHelper.HexToForm(formId)
            if theForm
                GetActorReference().PlaceAtMe(theForm)
            endIf
            j += 1
        endWhile
        i += 1
    endWhile
endEvent

scriptName Search_UI_2
{Version two of Search UI ~ the Extensible version!}


; Action Types
;
; CategoryListAction
; CategoryAction
; IndividualResultAction

function ShowSearch_Main(int searchResults) global

    ; "Armor (2)" "Armor" => 2
    int categoriesAndCounts = JMap.object()
    JValue.retain(categoriesAndCounts)

    int searchResultSetCount = Search.GetSearchResultSetCount(searchResults)
    int i = 0
    while i < searchResultSetCount
        int searchResultSet = Search.GetNthSearchResultSet(searchResults, i)
        string[] categoryNames = Search.GetCategoryNamesForSearchResultSet(searchResultSet)
        int j = 0
        while j < categoryNames.Length
            string categoryName = categoryNames[j]
            int categoryResultCount = Search.GetCategoryResultCountForSearchResultSet(searchResultSet, categoryName)
            int totalCategoryCount = JMap.getInt(categoriesAndCounts, categoryName)
            JMap.setInt(categoriesAndCounts, categoryName, totalCategoryCount + categoryResultCount)
            j += 1
        endWhile
        i += 1
    endWhile

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int allCategoryNames = JArray.object()
    JValue.retain(allCategoryNames)
    string text = ""
    string[] categoryNames = JMap.allKeysPArray(categoriesAndCounts)
    i = 0
    while i < categoryNames.Length
        string categoryName = categoryNames[i]
        JArray.addStr(allCategoryNames, categoryName)
        int categoryCount = JMap.getInt(categoriesAndCounts, categoryName)
        listMenu.AddEntryItem(categoryName + " (" + categoryCount + ")")
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()
    string selectedCategoryName = JArray.getStr(allCategoryNames, selection)

    ShowSearch_CategorySubmenu(searchResults, selectedCategoryName)

    JValue.release(allCategoryNames)
    JValue.release(categoriesAndCounts)

endFunction

string[] function GetCategoryActionNames(string categoryName) global
    int actionNames = JArray.object()
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/Categories/" + categoryName)
    string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
    int i = 0
    while i < configFiles.Length
        string filename = configFiles[i]
        int actionConfig = JMap.getObj(categoryActionConfigs, filename)
        string actionText = JMap.getStr(actionConfig, "text")
        JArray.addStr(actionNames, actionText)
        i += 1
    endWhile
    return JArray.asStringArray(actionNames)
endFunction

int function GetCategoryAction(string categoryName, string actionName) global
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/Categories/" + categoryName)
    string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
    int i = 0
    while i < configFiles.Length
        string filename = configFiles[i]
        int actionConfig = JMap.getObj(categoryActionConfigs, filename)
        string actionText = JMap.getStr(actionConfig, "text")
        if actionText == actionName
            return actionConfig
        endIf
        i += 1
    endWhile
endFunction

function ShowSearch_CategorySubmenu(int searchResults, string categoryName) global
    string[] categoryActionNames = GetCategoryActionNames(categoryName)

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int i = 0
    while i < categoryActionNames.Length
        listMenu.AddEntryItem(categoryActionNames[i])
        i += 1
    endWhile

    int resultSetsForEachResult = JArray.object()
    JValue.retain(resultSetsForEachResult)

    int searchResultSetCount = Search.GetSearchResultSetCount(searchResults)
    i = 0
    while i < searchResultSetCount
        int searchResultSet = Search.GetNthSearchResultSet(searchResults, i)
        int categoryResultCount = Search.GetCategoryResultCountForSearchResultSet(searchResultSet, categoryName)
        int j = 0
        while j < categoryResultCount
            JArray.addObj(resultSetsForEachResult, searchResultSet)
            int result = Search.GetNthCategoryResultForSearchResultSet(searchResultSet, categoryName, j)
            string displayText = Search.GetResultDisplayText(result)
            listMenu.AddEntryItem(displayText)
            j += 1
        endWhile
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()
    int resultOffset = categoryActionNames.Length

    if selection > -1
        if selection < resultOffset
            int selectedAction = GetCategoryAction(categoryName, categoryActionNames[selection])
            string eventName = JMap.getStr(selectedAction, "action")
            int theEvent = ModEvent.Create("Search_Action_" + eventName)
            ModEvent.PushString(theEvent, eventName)
            ModEvent.PushInt(theEvent, searchResults)
            ModEvent.PushString(theEvent, categoryName)
            ModEvent.Send(theEvent)
        else
            int index = selection - resultOffset
            int searchResultSet = JArray.getObj(resultSetsForEachResult, index)
            int selectedResult = Search.GetNthCategoryResultForSearchResultSet(searchResultSet, categoryName, index)
            string selectedResultDisplayText = Search.GetResultDisplayText(selectedResult)
            Debug.MessageBox("You selected: " + selectedResultDisplayText)
        endIF
    endIf

    JValue.release(resultSetsForEachResult)

endFunction

scriptName Search_UI
{Version two of Search UI ~ the Extensible version!}

function ShowSearchPrompt() global
    string[] searchProviders = new string[2]
    searchProviders[0] = "ConsoleSearch"
    searchProviders[1] = "Weather"

    string query = UIExtensionsExtensions.GetUserText()
    int results = Search.ExecuteQuery(query, searchProviders)

    ; For testing!
    JValue.writeToFile(results, "SearchResults.json")

    ShowSearchResultsCategoryList(results)
endFunction

function ShowSearchResultsCategoryList(int searchResults) global
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

    string[] categoryListActionNames = Search_UI_Actions.GetCategoryListActionNames(JMap.allKeysPArray(categoriesAndCounts))

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    i = 0
    while i < categoryListActionNames.Length
        listMenu.AddEntryItem(categoryListActionNames[i])
        i += 1
    endWhile

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
    int resultOffset = categoryListActionNames.Length

    if selection > -1
        if selection < resultOffset
            int selectedAction = Search_UI_Actions.GetCategoryListAction(categoryListActionNames[selection])
            Search_UI_Actions.SendActionEvent(selectedAction, searchResults)
        else
            string selectedCategoryName = JArray.getStr(allCategoryNames, selection - resultOffset)
            ShowSearchResultsCategory(searchResults, selectedCategoryName)
        endIf
    endIf

    JValue.release(allCategoryNames)
    JValue.release(categoriesAndCounts)
endFunction

function ShowSearchResultsCategory(int searchResults, string categoryName) global
    string[] categoryActionNames = Search_UI_Actions.GetCategoryActionNames(categoryName)

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
            int selectedAction = Search_UI_Actions.GetCategoryAction(categoryName, categoryActionNames[selection])
            Search_UI_Actions.SendActionEvent(selectedAction, searchResults, categoryName)
        else
            int index = selection - resultOffset
            int searchResultSet = JArray.getObj(resultSetsForEachResult, index)
            int selectedResult = Search.GetNthCategoryResultForSearchResultSet(searchResultSet, categoryName, index)
            string selectedResultDisplayText = Search.GetResultDisplayText(selectedResult)
            ShowSearchResult(searchResults, categoryName, searchResultSet, selectedResult)
        endIF
    endIf

    JValue.release(resultSetsForEachResult)
endFunction

function ShowSearchResult(int searchResults, string categoryName, int searchResultSet, int searchResult) global
    string[] categoryResultActionNames = Search_UI_Actions.GetCategoryResultActionNames(categoryName)

    if categoryResultActionNames.Length == 0
        Debug.MessageBox("There are no actions registered for Search category: " + categoryName)
        return
    elseIf categoryResultActionNames.Length == 1
        int selectedAction = Search_UI_Actions.GetCategoryResultAction(categoryName, categoryResultActionNames[0])
        Search_UI_Actions.SendActionEvent(selectedAction, searchResults, categoryName, searchResultSet, searchResult)
        return
    endIf

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int i = 0
    while i < categoryResultActionNames.Length
        listMenu.AddEntryItem(categoryResultActionNames[i])
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()
    string selectedActionName = categoryResultActionNames[selection]
    int selectedAction = Search_UI_Actions.GetCategoryResultAction(categoryName, selectedActionName)
    Search_UI_Actions.SendActionEvent(selectedAction, searchResults, categoryName, searchResultSet, searchResult)
endFunction

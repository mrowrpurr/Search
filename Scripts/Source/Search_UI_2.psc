scriptName Search_UI_2
{Version two of Search UI ~ the Extensible version!}

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

function ShowSearch_CategorySubmenu(int searchResults, string categoryName) global

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int searchResultSetCount = Search.GetSearchResultSetCount(searchResults)
    int i = 0
    while i < searchResultSetCount
        int searchResultSet = Search.GetNthSearchResultSet(searchResults, i)
        int categoryResultCount = Search.GetCategoryResultCountForSearchResultSet(searchResultSet, categoryName)
        int j = 0
        while j < categoryResultCount
            int result = Search.GetNthCategoryResultForSearchResultSet(searchResultSet, categoryName, j)
            string displayText = Search.GetResultDisplayText(result)
            listMenu.AddEntryItem(displayText)
            j += 1
        endWhile
        i += 1
    endWhile

    listMenu.OpenMenu()

endFunction

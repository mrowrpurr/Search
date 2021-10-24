scriptName Search
{Upcoming version of Search with:
- multiple search provider
- multiple actions based on the search type}

function EnsureConfig() global
    if ! JDB.solveObj(".search.config")
        ReloadConfig()
    endIf
endFunction

function ReloadConfig() global
    JDB.solveObjSetter(                                 \
        ".search.config",                               \
        JValue.readFromFile("Data/Search/Config.json"), \
        createMissingKeys = true                        \
    )
endFunction

string[] function GetSearchProviderNames() global
    int searchProviders = JDB.solveObj(".search.config.search_providers")
    if searchProviders
        return JArray.asStringArray(searchProviders)
    else
        string[] providerNames
        return providerNames        
    endIf
endFunction

int function GetSearchResultHistory() global
    int history = JDB.solveObj(".search.history")
    if ! history
        history = JArray.object()
        JDB.solveObjSetter(           \
            ".search.history",        \
            history,                  \
            createMissingKeys = true  \
        )
    endIf
    return history
endFunction

function ClearSearchResultHistory() global
    JArray.clear(GetSearchResultHistory())
endFunction

int function ExecuteQuery(string query, float timeout = 5.0, bool autoLoadConfig = true) global
    if autoLoadConfig
        ; Load Search script configuration from disk
        EnsureConfig()
    endIf

    ; Get all of the providers to search
    string[] providerNames = GetSearchProviderNames()

    ; Object representing the search results for this query at this time
    int searchResults = JMap.object()
    JArray.addObj(GetSearchResultHistory(), searchResults)

    ; Store info about this query's total runtime (across all providers)
    float startTime = Utility.GetCurrentRealTime()
    JMap.setFlt(searchResults, "startTime", startTime)

    ; Store the results from each searched provider
    int providerResults = JArray.object()
    JMap.setObj(searchResults, "results", providerResults)

    ; Send the search query event
    int searchEvent = ModEvent.Create("SearchQuery")
    ModEvent.PushString(searchEvent, query)
    ModEvent.PushInt(searchEvent, providerResults)
    ModEvent.Send(searchEvent)

    ; Wait for the search query responses...
    float searchStartTime = Utility.GetCurrentRealTime()
    while JArray.count(providerResults) < providerNames.Length \
          && (Utility.GetCurrentRealTime() - searchStartTime) < timeout
        Utility.WaitMenuMode(0.1)
    endWhile

    ; Store info about this query's total runtime (across all providers)
    float endTime = Utility.GetCurrentRealTime()
    JMap.setFlt(searchResults, "endTime", endTime)
    JMap.setFlt(searchResults, "duration", endTime - startTime)

    JValue.writeToFile(searchResults, "Search ExecuteQuery Results " + query + ".json")

    return searchResults
endFunction

int function CreateResultSet(string provider) global
    int result = JMap.object()
    JMap.setStr(result, "provider", provider)
    JMap.setObj(result, "resultsByCategory", JMap.object())
    return result
endFunction

function AddSearchResult(int resultSet, string provider, string category, string displayText, int data) global
    int resultsByCategory = JMap.getObj(resultSet, "resultsByCategory")

    int result = JMap.object()
    JMap.setStr(result, "provider", provider)
    JMap.setStr(result, "category", category)
    JMap.setStr(result, "displayText", displayText)
    JMap.setObj(result, "data", data)

    int categoryArray = JMap.getObj(resultsByCategory, category)

    if ! categoryArray
        categoryArray = JArray.object()
        JMap.setObj(resultsByCategory, category, categoryArray)        
    endIf

    JArray.addObj(categoryArray, result)
endFunction

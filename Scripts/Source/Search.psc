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

int function ExecuteQuery(string query, float timeout = 5.0) global
    Debug.MessageBox("Execute Query " + query)

    ; Get all of the providers to search
    EnsureConfig()
    string[] providerNames = GetSearchProviderNames()

    Debug.MessageBox("Provider Names: " + providerNames)

    ; Store the results from each searched provider
    int providerResults = JArray.object()
    JArray.addObj(GetSearchResultHistory(), providerResults)

    ; Send the search query event
    int searchEvent = ModEvent.Create("SearchQuery")
    ModEvent.PushString(searchEvent, query)
    ModEvent.PushInt(searchEvent, providerResults)
    ModEvent.Send(searchEvent)
    Debug.MessageBox("Sent SearchQuery event")

    ; Wait for the search query responses...
    float searchStartTime = Utility.GetCurrentRealTime()
    while JArray.count(providerResults) < providerNames.Length \
          && (Utility.GetCurrentRealTime() - searchStartTime) < timeout
        Utility.WaitMenuMode(0.1)
    endWhile

    JValue.writeToFile(providerResults, "ProviderResults.json")
    Debug.MessageBox("Provider Results.json")

    return providerResults
endFunction

int function NewSearchResultSet(string provider) global
    int result = JMap.object()
    JMap.setStr(result, "provider", provider)
    JMap.setObj(result, "results", JMap.object())
    return result
endFunction

function AddSearchResult(int results, string category, string displayText, int data) global
    int result = JMap.object()
    JMap.setStr(result, "displayText", displayText)
    JMap.setObj(result, "data", data)

    if JMap.hasKey(results, category)
        JArray.addObj(JMap.getObj(results, category), result)
    else
        int categoryArray = JArray.object()
        JArray.addObj(categoryArray, result)
        JMap.setObj(results, category, categoryArray)
    endIf
endFunction

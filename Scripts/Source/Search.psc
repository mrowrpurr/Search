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

int function ExecuteQuery(string query, string[] providerNames = None, float timeout = 30.0) global
    ; Get all of the providers to search
    if ! providerNames
        EnsureConfig()
        providerNames = GetSearchProviderNames()
    endIf

    ; Store the results from each searched provider
    int providerResults = JArray.object()
    JArray.addObj(GetSearchResultHistory(), providerResults)

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

    return providerResults
endFunction

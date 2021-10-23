scriptName Search
{Upcoming version of Search with:
- multiple search provider
- multiple actions based on the search type}

function LoadConfig() global
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

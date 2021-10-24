scriptName Search_WeatherSearchProvider extends SearchProvider

; TODO ~ we can search on "Pine" and "Coast" and stuff

int function PerformSearch(string query, int storeResults)
    int weathers = ReadConfigFile("Weathers.json")
    string[] formIds = JMap.allKeysPArray(weathers)
    int i = 0
    while i < formIds.Length
        string formId   = formIds[i] 
        string editorId = JMap.getStr(weathers, formId)
        if StringUtil.Find(editorId, query) > -1
            AddSearchResult(           \
                storeResults,          \
                category = "Weather",  \
                text     = editorId,   \
                formId   = formId,     \
                editorId = editorId    \
            )
        endIf
        i += 1
    endWhile
    return storeResults
endFunction

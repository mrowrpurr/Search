scriptName Search_WeatherSearchProvider extends SearchProvider 

string WeatherDataFilePath = "Data/Search/Providers/Weather/Weathers.json"

; TODO ~ we can search on "Pine" and "Coast" and stuff
event OnSearch(string query)
    int weathers = JValue.readFromFile(WeatherDataFilePath)
    string[] formIds = JMap.allKeysPArray(weathers)
    int i = 0
    while i < formIds.Length
        string formId   = formIds[i] 
        string editorId = JMap.getStr(weathers, formId)
        if StringUtil.Find(editorId, query) > -1
            AddSearchResult("Weather",   \
                displayText = editorId,  \
                formId      = formId     \
            )
        endIf
        i += 1
    endWhile
endEvent

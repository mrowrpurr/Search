scriptName Search_WeatherSearchProvider extends SearchProvider

string WeatherDataFilePath = "Data/Search/Providers/Weather/Weathers.json"

; TODO ~ we can search on "Pine" and "Coast" and stuff
int function PerformSearch(string query, int results)
    int weathers = JValue.readFromFile(WeatherDataFilePath)
    string[] formIds = JMap.allKeysPArray(weathers)
    int i = 0
    while i < formIds.Length
        string formId   = formIds[i] 
        string editorId = JMap.getStr(weathers, formId)
        if StringUtil.Find(editorId, query) > -1
            int result = JMap.object()
            JMap.setStr(result, "formId", formId)
            JMap.setStr(result, "editorId", editorId)
            Search.AddSearchResult(results, "Weather", editorId, result)
        endIf
        i += 1
    endWhile
    return results
endFunction

scriptName SearchProvider extends ReferenceAlias
{Extend this on a PlayerRef Quest alias to implement a
custom Search Provider for the "Search" mod.}

string _providerName

string property ProviderName
    string function get()
        if ! _providerName
            string theFullScriptName = self ; [Search_FooSearchProvider < (00000000)>]
            int theSpace = StringUtil.Find(theFullScriptName, " ")
            string theScriptName = StringUtil.Substring(theFullScriptName, 1, theSpace)
            Debug.MessageBox("Script name: '" + theScriptName + "'")
        endIf
        return _providerName
    endFunction
    function set(string providerName)
        _providerName = ProviderName
    endFunction
endProperty

event OnInit()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
    Debug.MessageBox("Listening for SearchQuery... " + self)
endEvent

event OnPlayerLoadGame()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
    Debug.MessageBox("Listening for SearchQuery... " + self)
endEvent

; Override this function to implement your search provider.
int function PerformSearch(string query, int results)
    ; Intended to be overriden
endFunction

; Do not override this event. Use `PerformSearch()` instead.
event OnSearchQuery(string query, int searchResultArray)
    Debug.MessageBox("GOT A QUERY REQUEST!!! " + self)
    int result = Search.NewSearchResultSet(provider = ProviderName)
    float startTime = Utility.GetCurrentRealTime()
    int runtime = JMap.object()
    JMap.setObj(result, "runtime", runtime)
    JMap.setFlt(runtime, "startTime", startTime)

    PerformSearch(query, result) ; Perform the search!

    float endTime = Utility.GetCurrentRealTime()
    JMap.setFlt(runtime, "startTime", endTime)
    JMap.setFlt(runtime, "duration", endTime - startTime)
    JArray.addObj(searchResultArray, result)
endEvent

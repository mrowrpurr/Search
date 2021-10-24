scriptName SearchProvider extends ReferenceAlias
{Extend this on a PlayerRef Quest alias to implement a
custom Search Provider for the "Search" mod.}

string _providerName

string property ProviderName
    string function get()
        if ! _providerName
            _providerName = self ; [Search_FooSearchProvider < (00000000)>]
            int theSpaceIndex = StringUtil.Find(_providerName, " ")
            _providerName = StringUtil.Substring(_providerName, 1, theSpaceIndex) ; Search_FooSearchProvider
            int searchProviderIndex = StringUtil.Find(_providerName, "SearchProvider")
            if searchProviderIndex > -1
                _providerName = StringUtil.Substring(_providerName, 0, searchProviderIndex) ; Search_Foo
                if StringUtil.Find(_providerName, "Search_") == 0
                    _providerName = StringUtil.Substring(_providerName, 7) ; Foo
                endIf
            endIf
        endIf
        return _providerName
    endFunction
    function set(string providerName)
        _providerName = ProviderName
    endFunction
endProperty

; Override to configure your Search Provider.
;
; Runs the first time your provider is initialized
; and every time the game is loaded after that.
event OnProviderInit()
    ; Intended to be overriden
endEvent

event OnInit()
    OnProviderInit()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
endEvent

event OnPlayerLoadGame()
    OnProviderInit()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
endEvent

int function ReadConfigFile(string filename = "config.json")
    return JValue.readFromFile(GetConfigPath(filename))
endFunction

int function ReadConfigDirectory(string directory = "")
    return JValue.readFromDirectory(GetConfigPath(directory))
endFunction

string function GetConfigPath(string filename = "")
    if filename
        return "Data/Search/Providers/" + ProviderName + "/" + filename
    else
        return "Data/Search/Providers/" + ProviderName
    endIf
endFunction

; Override this function to implement your search provider.
int function PerformSearch(string query, int storeResults)
    ; Intended to be overriden
endFunction

; Do not override this event. Use `PerformSearch()` instead.
event OnSearchQuery(string query, int searchResultArray)
    int result = Search.CreateResultSet(ProviderName)
    JArray.addObj(searchResultArray, result)
    
    ; Store info about this query's total runtime for this provider
    float startTime = Utility.GetCurrentRealTime()
    JMap.setFlt(result, "startTime", startTime)

    PerformSearch(query, result) ; Perform the search!

    float endTime = Utility.GetCurrentRealTime()
    JMap.setFlt(result, "endTime", endTime)
    JMap.setFlt(result, "duration", endTime - startTime)
endEvent

function AddSearchResult(int storeResults, string category, string text, string formId = "", string editorId = "", int customData = 0)
    int result = JMap.object()
    JArray.addObj(storeResults, result)
    JMap.setStr(result, "provider", ProviderName)
    JMap.setStr(result, "category", category)
    JMap.setStr(result, "displayText", text)
    JMap.setStr(result, "formId", formId)
    JMap.setStr(result, "editorId", editorId)
    JMap.setObj(result, "data", customData)
endFunction

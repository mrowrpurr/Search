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
    function set(string name)
        _providerName = name
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
    RegisterForModEvent("SearchQuery_" + ProviderName, "OnSearchQuery")
endEvent

event OnPlayerLoadGame()
    OnProviderInit()
    RegisterForModEvent("SearchQuery_" + ProviderName, "OnSearchQuery")
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
    int resultSet = Search.CreateResultSet(ProviderName)
    JArray.addObj(searchResultArray, resultSet)
    
    ; Store info about this query's total runtime for this provider
    float startTime = Utility.GetCurrentRealTime()
    JMap.setFlt(resultSet, "startTime", startTime)

    PerformSearch(query, resultSet) ; Perform the search!

    float endTime = Utility.GetCurrentRealTime()
    JMap.setFlt(resultSet, "endTime", endTime)
    JMap.setFlt(resultSet, "duration", endTime - startTime)
    JMap.setStr(resultSet, "done", "true")
endEvent

function AddSearchResult(int resultSet, string category, string text, string name = "", string formId = "", string editorId = "", int customData = 0)
    int resultData = JMap.object()
    Search.AddSearchResult(resultSet, ProviderName, category, text, resultData)
    JMap.setStr(resultData, "text", text)
    JMap.setStr(resultData, "name", name)
    JMap.setStr(resultData, "formId", formId)
    JMap.setStr(resultData, "editorId", editorId)
endFunction

function AddResultSetKeyword(int resultSet, string resultSetKeyword)
    Search.AddResultSetKeyword(resultSet, resultSetKeyword)
endFunction

string function JDBPath(string path)
    return ".search.providers." + ProviderName + path
endFunction

int function GetObject(string path)
    return JDB.solveObj(JDBPath(path))
endFunction

function SetObject(string path, int objectRef)
    JDB.solveObjSetter(JDBPath(path), objectRef, createMissingKeys = true)
endFunction

scriptName SearchProvider extends ReferenceAlias
{Extend this on a PlayerRef Quest alias to implement a
custom Search Provider for the "Search" mod.}

event OnInit()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
endEvent

event OnPlayerLoadGame()
    RegisterForModEvent("SearchQuery", "OnSearchQuery")
endEvent

; Override this function to implement your search provider.
int function PerformSearch(string query)
    ; Intended to be overriden
endFunction

; Do not override this event. Use `PerformSearch()` instead.
event OnSearchQuery(string query, int searchResultArray)
    JArray.addObj(searchResultArray, PerformSearch(query))
endEvent

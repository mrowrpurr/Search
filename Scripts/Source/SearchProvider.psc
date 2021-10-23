scriptName SearchProvider extends ReferenceAlias
{Extend this on a PlayerRef Quest alias to implement a
custom Search Provider for the "Search" mod.}

event OnInit()

endEvent

event OnPlayerLoadGame()

endEvent

; Override this event to implement your search provider.
;
; ```
; event OnSearch()
;   int result = NewSearchResult()
;   result.AddResult( \
;     category = "Actor References",
;     name     = "Sven",
;     formId   = "".
;     ... TODO
;   )
; endEvent
; ```
event OnSearch()

endEvent
scriptName Search_ConsoleSearchProvider extends SearchProvider

int _recordTypesToCategoryNames

event OnProviderInit()
    ProviderName = "ConsoleSearch"
endEvent

int function PerformSearch(string query, int storeResults)
    int consoleSearchResults = ConsoleSearch.ExecuteSearch(query)
    JValue.retain(consoleSearchResults)
    string[] recordTypes = ConsoleSearch.GetResultRecordTypes(consoleSearchResults)
    int i = 0
    while i < recordTypes.Length
        string recordType = recordTypes[i]
        int recordResultCount = ConsoleSearch.GetResultRecordTypeCount(consoleSearchResults, recordType)
        int j = 0
        while j < recordResultCount
            int record      = ConsoleSearch.GetNthResultOfRecordType(consoleSearchResults, recordType, j)
            string name     = ConsoleSearch.GetRecordName(record)
            string formId   = ConsoleSearch.GetRecordFormID(record)
            string editorId = ConsoleSearch.GetRecordEditorID(record)
            string text     = name
            if ! text
                text = editorId
            endIf
            if ! text
                text = formId
            endIf
            AddSearchResult(                                     \
                storeResults,                                    \
                category = GetCategoryForRecordType(recordType), \
                text     = text,                                 \
                formId   = formId,                               \
                editorId = editorId                              \
            )
            j += 1
        endWhile
        i += 1
    endWhile

    JValue.release(consoleSearchResults)
    return storeResults
endFunction

string function GetCategoryForRecordType(string recordType)
    if ! _recordTypesToCategoryNames
        _recordTypesToCategoryNames = ReadConfigFile("recordTypeCategoryNames.json")
    endIf
    string categoryName = JMap.getStr(_recordTypesToCategoryNames, recordType)
    if ! categoryName
        categoryName = "UNKNOWN"
    endIf
    return categoryName
endFunction

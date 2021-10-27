scriptName Search_ConsoleSearchProvider extends SearchProvider

event OnProviderInit()
    ProviderName = "ConsoleSearch"
endEvent

string property RecordTypesToCategoryNamesFile = "recordTypeCategoryNames.json" autoReadonly
string property RecordTypesToCategoryNamesPath = ".recordTypesToCategoryNames"  autoReadonly

int property RecordTypesToCategoryNames
    int function get()
        int theRecordInventoryTypeNames = GetObject(RecordTypesToCategoryNamesPath)
        if ! theRecordInventoryTypeNames
            SetObject(RecordTypesToCategoryNamesPath, ReadConfigFile(RecordTypesToCategoryNamesFile))
        endIf
        return theRecordInventoryTypeNames
    endFunction
endProperty

int function PerformSearch(string query, int resultSet)
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
                resultSet,                                       \
                category = GetCategoryForRecordType(recordType), \
                text     = text,                                 \
                name     = name,                                 \
                formId   = formId,                               \
                editorId = editorId                              \
            )
            j += 1
        endWhile
        i += 1
    endWhile

    JValue.release(consoleSearchResults)
    return resultSet
endFunction

string function GetCategoryForRecordType(string recordType)
    string categoryName = JMap.getStr(RecordTypesToCategoryNames, recordType)
    if ! categoryName
        categoryName = "Unknown"
    endIf
    return categoryName
endFunction

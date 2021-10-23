scriptName SearchResult
{Read values from results returned by `SearchProvider.Search`}

string[] function GetCategoryNames(int result) global
    return JMap.allKeysPArray(JMap.getObj(result, "categories"))
endFunction

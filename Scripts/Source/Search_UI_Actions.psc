scriptName Search_UI_Actions
{Integrates Search Actions with the UI via configuration files}

string[] function GetCategoryListActionNames(string[] categoryNames) global
    int actionNames = JArray.object()
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/")
    string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
    int i = 0
    while i < configFiles.Length
        string filename = configFiles[i]
        int actionConfig = JMap.getObj(categoryActionConfigs, filename)
        string actionText = JMap.getStr(actionConfig, "text")
        int categoryConditionalList = JMap.getObj(actionConfig, "categories")
        if categoryConditionalList
            string[] actionCategories = JArray.asStringArray(categoryConditionalList)
            bool showAction = false
            int j = 0
            while j < actionCategories.Length && ! showAction
                string actionCategory = actionCategories[j]
                if categoryNames.Find(actionCategory) > -1
                    showAction = true
                endIf
                j += 1
            endWhile
            if showAction
                JArray.addStr(actionNames, actionText)
            endIf
        else
            JArray.addStr(actionNames, actionText)
        endIf

        ; Check if any of the categories match
        i += 1
    endWhile
    return JArray.asStringArray(actionNames)
endFunction

int function GetCategoryListAction(string actionName) global
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/")
    if categoryActionConfigs
        string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
        int i = 0
        while i < configFiles.Length
            string filename = configFiles[i]
            int actionConfig = JMap.getObj(categoryActionConfigs, filename)
            string actionText = JMap.getStr(actionConfig, "text")
            if actionText == actionName
                return actionConfig
            endIf
            i += 1
        endWhile
    endIf
endFunction

string[] function GetCategoryActionNames(string categoryName) global
    int actionNames = JArray.object()
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/" + categoryName + "/List")
    string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
    int i = 0
    while i < configFiles.Length
        string filename = configFiles[i]
        int actionConfig = JMap.getObj(categoryActionConfigs, filename)
        string actionText = JMap.getStr(actionConfig, "text")
        JArray.addStr(actionNames, actionText)
        i += 1
    endWhile
    return JArray.asStringArray(actionNames)
endFunction

int function GetCategoryAction(string categoryName, string actionName) global
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/" + categoryName + "/List")
    if categoryActionConfigs
        string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
        int i = 0
        while i < configFiles.Length
            string filename = configFiles[i]
            int actionConfig = JMap.getObj(categoryActionConfigs, filename)
            string actionText = JMap.getStr(actionConfig, "text")
            if actionText == actionName
                return actionConfig
            endIf
            i += 1
        endWhile
    endIf
endFunction

string[] function GetCategoryResultActionNames(string categoryName) global
    int actionNames = JArray.object()
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/" + categoryName)
    string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
    int i = 0
    while i < configFiles.Length
        string filename = configFiles[i]
        int actionConfig = JMap.getObj(categoryActionConfigs, filename)
        string actionText = JMap.getStr(actionConfig, "text")
        JArray.addStr(actionNames, actionText)
        i += 1
    endWhile
    return JArray.asStringArray(actionNames)
endFunction

int function GetCategoryResultAction(string categoryName, string actionName) global
    int categoryActionConfigs = JValue.readFromDirectory("Data/Search/CategoryActions/" + categoryName)
    if categoryActionConfigs
        string[] configFiles = JMap.allKeysPArray(categoryActionConfigs)
        int i = 0
        while i < configFiles.Length
            string filename = configFiles[i]
            int actionConfig = JMap.getObj(categoryActionConfigs, filename)
            string actionText = JMap.getStr(actionConfig, "text")
            if actionText == actionName
                return actionConfig
            endIf
            i += 1
        endWhile
    endIf
endFunction

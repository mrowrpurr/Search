scriptName ConsoleSearch
{Get `help` results from the console}

function Log(string text) global
    Debug.Trace("[ConsoleSearch] " + text)
endFunction

int function Search(string query, string type = "") global
    string text = Help(query)

    int results = JMap.object()

    JValue.retain(results) ; For testing

    int index = 0
    int len = StringUtil.GetLength(text)

    int currentResult
    int previousSpace
    int previousParenthesisOpen
    int previousSingleQuote
    bool isReadingFormID
    bool isReadingFormName
    bool isReadingEditorID
    bool isWaitingForSingleQuote
    string newline = StringUtil.AsChar(13) ; 10 is Line Feed, 13 is Carriage Return

    Debug.MessageBox(StringUtil.Split(text, newline))

    while index < len
        string character = StringUtil.GetNthChar(text, index)
        
        if currentResult && character != " " && character != newline ; Processing a current result
            if isReadingEditorID && character == "("
                JMap.setStr(currentResult, "editorID", StringUtil.Substring(text, previousSpace, index - previousSpace))
                isReadingEditorID = false
                isReadingFormID = true
            elseIf isReadingFormID && character == "("
                string currentFormID = StringUtil.Substring(text, previousParenthesisOpen + 1, index - (previousParenthesisOpen + 1))
                JMap.setStr(currentResult, "formID", currentFormID)
                JMap.setForm(currentResult, "form", FormHelper.HexToForm(currentFormID))
                isReadingFormID = false
                isReadingFormName = true
                isWaitingForSingleQuote = true
            elseIf isReadingFormName && isWaitingForSingleQuote && character == "'"
                isWaitingForSingleQuote = false
            elseIf isReadingFormName && character == "'"
                JMap.setStr(currentResult, "name", StringUtil.Substring(text, previousSingleQuote + 1, index - (previousSingleQuote + 1)))
                isReadingFormName = false
                currentResult = 0
            endIf

        elseIf character == ":" ; Start processing a new result
            string currentType = StringUtil.Substring(text, previousSpace + 1, index - (previousSpace + 1))
            currentResult = JMap.object()
            if JMap.hasKey(results, currentType)
               JArray.addObj(JMap.getObj(results, currentType), currentResult)
            else
                int currentTypeArray = JArray.object()
                JArray.addObj(currentTypeArray, currentResult)
                JMap.setObj(results, currentType, currentTypeArray)
            endIf
            JMap.setStr(currentResult, "type", currentType)
            isReadingEditorID = true
        endIf

        if character == " " || character == newline
            previousSpace = index
        elseIf character == "("
            previousParenthesisOpen = index
        elseIf character == "'"
            previousSingleQuote = index
        endIf

        index += 1
    endWhile

    string fileName = "Search_" + query + ".json"
    JValue.writeToFile(results, fileName)
    Debug.MessageBox("Saved " + fileName)

    return results
endFunction

; Returns the raw returned text from running `help "[query]"` in the console
string function Help(string query) global
    if ! __consoleSearch.IsConsoleOpen()
        __consoleSearch.ToggleConsole()
    endIf
    __consoleSearch.ClearConsoleText()
    __consoleSearch.RunCommand("help \"" + query + "\"")
    string text = __consoleSearch.ReadConsoleText()
    __consoleSearch.ToggleConsole()
    return text
endFunction

scriptName ConsoleSearch
{Get `help` results from the console}

int function Search(string query, string filter = "") global
    int results = JMap.object()
    string newline = StringUtil.AsChar(13) ; 10 is Line Feed, 13 is Carriage Return
    string text = Help(query)
    string[] lines = StringUtil.Split(text, newline)

    int i = 0
    while i < lines.Length
        string line = lines[i]
        if ! filter || StringUtil.Find(line, filter) > -1
            int colon = StringUtil.Find(line, ":")
            if colon > -1
                int openParens = StringUtil.Find(line, "(")
                int closeParens = StringUtil.Find(line, ")")
                int openSingleQuote = StringUtil.Find(line, "'")
                if openParens && closeParens && openSingleQuote
                    string type = StringUtil.Substring(line, 0, colon)
                    if type != "usage" && type != "filters"
                        string editorId = ""
                        if (openParens - colon - 3) > 0
                            editorId = StringUtil.Substring(line, colon + 2, openParens - colon - 3)
                        endIf
                        string formId = StringUtil.Substring(line, openParens + 1, closeParens - openParens - 1)
                        string name = StringUtil.Substring(line, openSingleQuote + 1, StringUtil.GetLength(line) - openSingleQuote - 2)
                        int result = JMap.object()
                        if JMap.hasKey(results, type)
                            JArray.addObj(JMap.getObj(results, type), result)
                        else
                            int typeArray = JArray.object()
                            JArray.addObj(typeArray, result)
                            JMap.setObj(results, type, typeArray)
                        endIf
                        JMap.setStr(result, "name", name)
                        JMap.setStr(result, "editorID", editorId)
                        JMap.setStr(result, "formID", formId)
                    endIf
                endIf
            endIf
        endIf
        i += 1
    endWhile

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

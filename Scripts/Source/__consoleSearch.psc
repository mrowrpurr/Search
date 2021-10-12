scriptName __consoleSearch
{Private functions to support the ConsoleSearch utility}

bool function IsConsoleOpen() global
    return UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
endFunction

function ToggleConsole() global
    Input.TapKey(Input.GetMappedKey("Console"))
endFunction

function ClearConsoleText() global
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", "")
    if ReadConsoleText()
        ClearConsoleText()
    endIf
endFunction

string function ReadConsoleText() global
    return UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")
endFunction

function RunCommand(string command) global
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", command)
    Input.TapKey(28) ; Enter
    while ReadConsoleText() == "" || ReadConsoleText() == command ; Nothing printed out except the command
        Utility.WaitMenuMode(0.1)
    endWhile
endFunction

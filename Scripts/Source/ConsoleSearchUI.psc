scriptName ConsoleSearchUI extends ReferenceAlias  
{UI for testing the `ConsoleSearch` utility}

; Left Ctrl + Left Shift + S to trigger search

int KEY_LEFT_CTRL  = 29
int KEY_LEFT_SHIFT = 42
int KEY_S          = 31

event OnInit()
    ListenForSearch()
endEvent

event OnPlayerLoadGame()
    ListenForSearch()
endEvent

function ListenForSearch()
    RegisterForKey(KEY_S)
endFunction

event OnKeyDown(int keyCode)
    if Input.IsKeyPressed(KEY_LEFT_CTRL) && Input.IsKeyPressed(KEY_LEFT_SHIFT)
        Show()
    endIf
endEvent

function Show()
    string query = GetTextInput()
    Debug.MessageBox(ConsoleSearch.Help(query))
endFunction

string function GetTextInput()
    UITextEntryMenu textEntry = UIExtensions.GetMenu("UITextEntryMenu") as UITextEntryMenu
    textEntry.OpenMenu()
    return textEntry.GetResultString()
endFunction

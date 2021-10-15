scriptName Search_UI extends Quest
{Primary `Search` Mod with User Interface

Requires:
- JContainers
- UI Extensions
- FormHelper
- ConsoleUtil (optional)

For the Papyrus Utility, see the `Search.psc` script.}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mod Installation and Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event OnInit()
    CurrentlyInstalledVersion = GetCurrentVersion()
endEvent

function Setup()
    LoadConfiguration()
    ListenForKeyboardShortcuts()
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Versioning
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float property CurrentlyInstalledVersion auto

float function GetCurrentVersion() global
    return 1.0
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string property ConfigPath_Root              = ".search.config" autoReadonly
string property ConfigPath_KeyboardShortcuts = ".search.config.keyboard_shortcuts" autoReadonly
string property ConfigurationFilePath        = "Search/Config.json" autoReadonly

function LoadConfiguration()
    int configFromFile = JValue.readFromFile(ConfigurationFilePath)
    if configFromFile
        JDB.solveObjSetter(ConfigPath_Root, configFromFile, createMissingKeys = true)
    else
        JDB.solveObjSetter(ConfigPath_KeyboardShortcuts, JMap.object(), createMissingKeys = true)
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Keyboard Shortcuts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int CTRL_LEFT   = 29
int CTRL_RIGHT  = 157
int ALT_LEFT    = 56
int ALT_RIGHT   = 184
int SHIFT_LEFT  = 42
int SHIFT_RIGHT = 54

function OnKeyDown(int keyCode)
    string triggeredShortcut = GetTriggeredKeyboardShortcutName(keyCode, \
        ctrlPressed  = (Input.IsKeyPressed(CTRL_LEFT)  || Input.IsKeyPressed(CTRL_RIGHT)), \
        altPressed   = (Input.IsKeyPressed(ALT_LEFT)   || Input.IsKeyPressed(ALT_RIGHT)),  \
        shiftPressed = (Input.IsKeyPressed(SHIFT_LEFT) || Input.IsKeyPressed(SHIFT_RIGHT)))
    if triggeredShortcut
        if triggeredShortcut == "ui"
            OpenSearchPrompt()
        else
            Debug.MessageBox("Unknown [Search] keyboard shortcut type: " + triggeredShortcut)
        endIf
    endIf
endFunction

int property KeyboardShortcutMap
    int function get()
        return JDB.solveObj(ConfigPath_KeyboardShortcuts)
    endFunction
endProperty

function ListenForKeyboardShortcuts()
    int keysToListenTo = JIntMap.object()
    string[] shortcutNames = JMap.allKeysPArray(KeyboardShortcutMap)

    ; Get the key codes for each shortcut (may have duplicates)
    int i = 0
    while i < shortcutNames.Length
        int shortcutConfig = JMap.getObj(KeyboardShortcutMap, shortcutNames[i])
        int keyCode = JMap.getInt(shortcutConfig, "key")
        JIntMap.setInt(keysToListenTo, keyCode, 1)
        i += 1
    endWhile

    ; Listen to each unique key code
    int[] keyCodes = JIntMap.allKeysPArray(keysToListenTo)
    i = 0
    while i < keyCodes.Length
        RegisterForKey(keyCodes[i])
        i += 1
    endWhile
endFunction

string function GetTriggeredKeyboardShortcutName(int keyCode, bool ctrlPressed, bool altPressed, bool shiftPressed)
    string[] shortcutNames = JMap.allKeysPArray(KeyboardShortcutMap)

    ; See if any configs match and return the first matching one
    int i = 0
    while i < shortcutNames.Length
        string shortcutName = shortcutNames[i]
        int shortcutConfig = JMap.getObj(KeyboardShortcutMap, shortcutName)
        int configKeyCode  = JMap.getInt(shortcutConfig, "key")
        if configKeyCode == keyCode
            bool matches = true
            bool requiresCtrl  = JMap.getStr(shortcutConfig, "ctrl") == "true"
            bool requiresAlt   = JMap.getStr(shortcutConfig, "alt") == "true"
            bool requiresShift = JMap.getStr(shortcutConfig, "shift") == "true"
            if requiresCtrl && ! ctrlPressed
                matches = false
            endIf
            if requiresAlt && ! altPressed
                matches = false
            endIf
            if requiresShift && ! shiftPressed
                matches = false
            endIf
            if matches
                return shortcutName
            endIf
        endIf
        i += 1
    endWhile

    return ""
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Open Main Search UI prompt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string property SearchResultsPath_Root = ".search.results" autoReadonly

function OpenSearchPrompt()
    string query = GetUserInput()
    if query
        int searchResults = Search.ExecuteSearch(query)
        if ! searchResults
            Debug.MessageBox("Search for '" + query + "' failed")
            return
        endIf
        SaveSearchResult(searchResults)
        ShowSearchCategorySelection(query, searchResults)
    endIf
endFunction

function ClearPreviouslySavedSearchResults()
    JArray.clear(SearchResultsArray)
endFunction

function SaveSearchResult(int resultId)
    JArray.addObj(SearchResultsArray, resultId)
endFunction

int property SearchResultsArray
    int function get()
        int resultsArray = JDB.solveObj(SearchResultsPath_Root)
        if ! resultsArray
            resultsArray = JArray.object()
            JDB.solveObjSetter(SearchResultsPath_Root, resultsArray, createMissingKeys = true)
        endIf
        return resultsArray
    endFunction
endProperty

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Search Category Selection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function ShowSearchCategorySelection(string query, int searchResults)
    string[] categoryNames = Search.GetResultCategories(searchResults)
    if ! categoryNames
        Debug.MessageBox("No results found for '" + query + "'")
        return
    endIf
    string category = GetUserSelection(categoryNames)
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UI Extensions Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string function GetUserInput(string defaultText = "") global
    UITextEntryMenu textEntry = UIExtensions.GetMenu("UITextEntryMenu") as UITextEntryMenu
    if defaultText
        textEntry.SetPropertyString("text", defaultText)
    endIf
    textEntry.OpenMenu()
    return textEntry.GetResultString()
endFunction

string function GetUserSelection(string[] options, bool showFilter = true, string filter = "") global
    int optionsToShow = JArray.object()

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
    if showFilter
        listMenu.AddEntryItem("[Filter List]")
    endIf

    int i = 0
    while i < options.Length
        string optionText = options[i]
        if ! filter || StringUtil.Find(optionText, filter) > -1
            JArray.addStr(optionsToShow, optionText)
            listMenu.AddEntryItem(optionText)
        endIf
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()

    if selection > -1
        if selection == 0 && showFilter
            return GetUserSelection(JArray.asStringArray(optionsToShow), showFilter = true, filter = GetUserInput())
        else
            int index = selection
            if showFilter
                index = selection - 1
            endIf
            return JArray.getStr(optionsToShow, index)
        endIf
    endIf
endFunction

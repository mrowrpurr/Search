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

Actor property PlayerRef auto

event OnInit()
    CurrentlyInstalledVersion = GetCurrentVersion()
    Setup()
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

string property ConfigPath_Root              = ".search.config"                    autoReadonly
string property ConfigPath_KeyboardShortcuts = ".search.config.keyboard_shortcuts" autoReadonly
string property ConfigPath_Category_Names    = ".search.config.category_names"     autoReadonly
string property ConfigurationFilePath        = "Data/Search/Config.json"                autoReadonly

function LoadConfiguration()
    int configFromFile = JValue.readFromFile(ConfigurationFilePath)
    if configFromFile
        JDB.solveObjSetter(ConfigPath_Root, configFromFile, createMissingKeys = true)
    else
        JDB.solveObjSetter(ConfigPath_KeyboardShortcuts, JMap.object(), createMissingKeys = true)
        JDB.solveObjSetter(ConfigPath_Category_Names,    JMap.object(), createMissingKeys = true)
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
; Category Name Replacement and Info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int property CategoryNameMap
    int function get()
        return JDB.solveObj(ConfigPath_Category_Names)
    endFunction
endProperty

string function GetCategoryDisplayName(string name)
    string friendlyName = JMap.getStr(CategoryNameMap, name)
    if friendlyName
        return friendlyName
    else
        return name
    endIf
endFunction

string function GetRealCategoryNameFromDisplayName(string displayName)
    string[] categoryNames = JMap.allKeysPArray(CategoryNameMap)
    int i = 0
    while i < categoryNames.Length
        string categoryName = categoryNames[i]
        string friendlyName = JMap.getStr(CategoryNameMap, categoryName)
        if friendlyName == displayName
            return categoryName
        endIf
        i += 1
    endWhile
    return displayName
endFunction

string[] function GetCategoryDisplayNames(string[] categories)
    string[] displayNames = Utility.CreateStringArray(categories.Length)
    int i = 0
    while i < categories.Length
        displayNames[i] = GetCategoryDisplayName(categories[i])
        i += 1
    endWhile
    return displayNames
endFunction

bool function CategoryIsSpellType(string category)
    return category == "SPEL" || category == "SHOU"
endFunction

bool function CategoryIsInventoryType(string category)
    return category == "ALCH" || category == "INGR" || category == "KEYM" || \
           category == "WEAP" || category == "ARMO" || category == "AMMO" || \
           category == "SCRL" || category == "BOOK"
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

    bool anySpellTypes = false
    bool anyItemTypes = false
    int categoriesWithCounts = JArray.object()
    int i = 0
    while i < categoryNames.Length
        string categoryName = categoryNames[i]
        if CategoryIsSpellType(categoryName)
            anySpellTypes = true
        endIf
        if CategoryIsInventoryType(categoryName)
            anyItemTypes = true
        endIf
        string displayName = GetCategoryDisplayName(categoryName)
        int count = Search.GetResultCategoryCount(searchResults, categoryName)
        JArray.addStr(categoriesWithCounts, displayName + " (" + count + ")")
        i += 1
    endWhile

    int options = JArray.object()
    if anyItemTypes
        JArray.addStr(options, "[View All Items]")
    endIf
    if anySpellTypes
        JArray.addStr(options, "[View All Spells]")
    endIf
    JArray.addFromArray(options, categoriesWithCounts)

    string categoryNameWithCount = GetUserSelection(JArray.asStringArray(options), showFilter = false)

    if categoryNameWithCount
        int categoryIndex = JArray.findStr(categoriesWithCounts, categoryNameWithCount)
        string category = categoryNames[categoryIndex]
        ShowCategory(searchResults, category)
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Category Subview
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function ShowCategory(int searchResults, string category)
    if category == "[View All Items]"

    elseIf category == "[View All Spells]"

    elseIf category == "CELL"
        ShowCategory_Cell(searchResults)

    elseIf category == "NPC_"
        ShowCategory_Actors(searchResults)

    elseIf category == "ARMO"
        ShowCategory_Armor(searchResults)

    elseIf category == "FURN"
        ShowCategory_Furniture(searchResults)

    else
        Debug.MessageBox("Category not yet supported: " + category)
    endIf
endFunction

function ShowCategory_Cell(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "CELL", "~ Choose Cell to Teleport ~", showName = false, showEditorId = true, showFormId = false)
    if selection >= 0
        int result = Search.GetNthResultInCategory(searchResults, "CELL", selection)
        string editorId = Search.GetResultEditorID(result)
        Debug.CenterOnCell(editorId)
    endIf
endFunction

function ShowCategory_Armor(int searchResults)
endFunction

function ShowCategory_Actors(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "NPC_", "~ Choose NPC to Spawn ~", showName = true, showEditorId = false, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "NPC_", selection)
        int count = GetUserInput(1) as int
        if ! count
            count = 1
        endIf
        string formId = Search.GetResultFormID(result)
        Form theForm = FormHelper.HexToForm(formId)
        PlayerRef.PlaceAtMe(theForm, count)
    endIf
endFunction

function ShowCategory_Furniture(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "FURN", "~ Choose Furniture to Place ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "FURN", selection)
        string formId = Search.GetResultFormID(result)
        Debug.MessageBox("Try casting the fork spell!")
        PlayerRef.AddSpell(Search_Placement_Spell)
        PlayerRef.EquipSpell(Search_Placement_Spell, 0)
        PlayerRef.EquipSpell(Search_Placement_Spell, 1)
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get Names of Items in Categories
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Click on header: 0
; Click on option 1:  -1
; Click on option 2:  -2
; Click on option 3:  -3
int function ShowSearchResultChooser(int searchResults, string category, string header = "", bool showFilter = true, string filter = "", string option1 = "", string option2 = "", string option3 = "", bool showName = true, bool showFormId = true, bool showEditorId = false)
    int optionsToShow = JArray.object()

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int currentIndex = 0

    int headerIndex  = -1
    int option1Index = -1
    int option2Index = -1
    int option3Index = -1
    int filterIndex  = -1

    if header
        listMenu.AddEntryItem(header)
        headerIndex = currentIndex
        currentIndex += 1
    endIf
    if option1
        listMenu.AddEntryItem(option1)
        option1 = currentIndex
        currentIndex += 1
    endIf
    if option2
        listMenu.AddEntryItem(option2)
        option2 = currentIndex
        currentIndex += 1
    endIf
    if option3
        listMenu.AddEntryItem(option3)
        option3 = currentIndex
        currentIndex += 1
    endIf
    if showFilter && ! filter
        listMenu.AddEntryItem("[Filter List]")
        filterIndex = currentIndex
        currentIndex += 1
    endIf

    int count = Search.GetResultCategoryCount(searchResults, category)

    int selectionIndexToNthIndex = JIntMap.object()

    int itemIndex = 0
    int i = 0
    while i < count
        int result = Search.GetNthResultInCategory(searchResults, category, i)
        string name = Search.GetResultName(result)
        string formId = Search.GetResultFormID(result)
        string editorId = Search.GetResultEditorID(result)
        string prefix = ""
        string text = ""
        if showName
            text += name
            prefix = " "
        endIf
        if showEditorId
            text += prefix + editorId
            prefix = " "
        endIf
        if showFormId
            text += prefix + "(" + formId + ")"
        endIf
        if ! filter || StringUtil.Find(name + editorId + formId, filter) > -1
            JArray.addStr(optionsToShow, text)
            listMenu.AddEntryItem(text)
            JIntMap.setInt(selectionIndexToNthIndex, itemIndex, i)
            itemIndex += 1
        endIf
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()

    if selection > -1

        if showFilter && selection == filterIndex
            ; int function ShowSearchResultChooser(int searchResults, string category, string header = "", bool showFilter = true, string filter = "", string option1 = "", string option2 = "", string option3 = "", bool showName = true, bool showFormId = true, bool showEditorId = false)
            return ShowSearchResultChooser(            searchResults,        category,        header,           showFilter,        GetUserInput(),            option1,             option2,             option3,           showName,             showFormId,             showEditorId)
        else
            ; Click on header:    -1
            ; Click on option 1:  -2
            ; Click on option 2:  -3
            ; Click on option 3:  -4
            if selection == headerIndex
                return -1
            elseIf selection == option1Index
                return -2
            elseIf selection == option2Index
                return -3
            elseIf selection == option3Index
                return -4
            else
                ; Return the ACTUAL INDEX of the provided collection
                int potentiallyFilteredItemIndex = selection - currentIndex
                int originalIndex = JIntMap.getInt(selectionIndexToNthIndex, potentiallyFilteredItemIndex)
                return originalIndex
            endIf
        endIf
    endIf
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Object Placement Spell
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Spell property Search_Placement_Spell auto

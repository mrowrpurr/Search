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
; OnUpdate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string CurrentNotification
float  CurrentNotificationInterval = 2.0

event OnUpdate()
    if CurrentNotification
        Debug.Notification(CurrentNotification)
        RegisterForSingleUpdate(CurrentNotificationInterval)
    endIf
endEvent

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
        CurrentNotification = "Searching..."
        RegisterForSingleUpdate(0.0)
        int searchResults = Search.ExecuteSearch(query)
        SaveSearchResult(searchResults)
        Search.SaveResultToFile(searchResults, "_SearchResults_.json")
        CurrentNotification = ""
        if ! searchResults
            Debug.MessageBox("Search for '" + query + "' failed")
            return
        endIf
        ShowSearchCategorySelection(query, searchResults)
    endIf
endFunction

function ClearPreviouslySavedSearchResults()
    JArray.clear(SearchResultsArray)
endFunction

; TODO - No array, use 1 object instead of saving all search result
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

    bool anyItemTypes = false
    int categoriesWithCounts = JArray.object()
    int i = 0
    while i < categoryNames.Length
        string categoryName = categoryNames[i]
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
    JArray.addFromArray(options, categoriesWithCounts)

    string categoryNameWithCount = GetUserSelection(JArray.asStringArray(options), showFilter = false)

    if categoryNameWithCount
        if categoryNameWithCount == "[View All Items]"
            CurrentNotification = "Loading Items"
            RegisterForSingleUpdate(0.0)
            ItemAndSpellStorage.RemoveAllItems()
            i = 0
            while i < categoryNames.Length
                string categoryName = categoryNames[i]
                if CategoryIsInventoryType(categoryName)
                    int categoryCount = Search.GetResultCategoryCount(searchResults, categoryName)
                    int categoryIndex = 0
                    while categoryIndex < categoryCount
                        int item = Search.GetNthResultInCategory(searchResults, categoryName, categoryIndex)
                        string formId = Search.GetResultFormID(item)
                        Form theForm = FormHelper.HexToForm(formId)
                        if theForm.GetType() == 42 ; AMMO
                            ItemAndSpellStorage.AddItem(theForm, 50)
                        else
                            ItemAndSpellStorage.AddItem(theForm)
                        endIf
                        categoryIndex += 1
                    endWhile
                endIf
                i += 1
            endWhile
            CurrentNotification = ""
            ItemAndSpellStorage.OpenInventory(abForceOpen = true)
            
        elseIf categoryNameWithCount == "[View All Spells]"
            Debug.MessageBox("TODO")

        else
            int categoryIndex = JArray.findStr(categoriesWithCounts, categoryNameWithCount)
            string category = categoryNames[categoryIndex]
            ShowCategory(searchResults, category)
        endIf
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Category Subview
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function ShowCategory(int searchResults, string category)
    if category == "[View All Items]"

    elseIf category == "CELL"
        ShowCategory_Cell(searchResults)

    elseIf category == "NPC_"
        ShowCategory_Actors(searchResults)

    elseIf category == "ARMO"
        ShowCategory_Armor(searchResults)

    elseIf category == "WEAP"
        ShowCategory_Weapon(searchResults)

    elseIf category == "FURN"
        ShowCategory_Furniture(searchResults)

    elseIf category == "QUST"
        ShowCategory_Quest(searchResults)

    elseIf category == "SPEL"
        ShowCategory_Spell(searchResults)

    elseIf category == "SHOU"
        ShowCategory_Shout(searchResults)

    elseIf category == "WOOP"
        ShowCategory_WordOfPower(searchResults)

    elseIf category == "LCRT"
        Debug.MessageBox("Markers aren't yet really useful, we'll make it so you can move them, move TO them, and SEE them by changing the .ini settings")
        ShowCategory_Marker(searchResults)

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

function ShowCategory_Quest(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "QUST", "~ Choose Quest ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "QUST", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Quest theQuest = FormHelper.HexToForm(formId) as Quest

        int listOptions = JArray.object()
        JArray.addStr(listOptions, "[" + editorId + "]")
        JArray.addStr(listOptions, "Start Quest")
        JArray.addStr(listOptions, "Stop Quest")
        JArray.addStr(listOptions, "Reset Quest")
        JArray.addStr(listOptions, "Set Stage")
        JArray.addStr(listOptions, "Set Objective Displayed")
        JArray.addStr(listOptions, "Set Objective Completed")
        JArray.addStr(listOptions, "Set Objective Failed")

        string questAction = GetUserSelection(JArray.asStringArray(listOptions))

        if questAction == "Start Quest"
            theQuest.Start()
        elseIf questAction == "Stop Quest"
            theQuest.Stop()
        elseIf questAction == "Reset Quest"
            theQuest.Reset()
        elseIf questAction == "Set Stage"
            theQuest.SetCurrentStageID(GetUserInput() as int)
        elseIf questAction == "Set Objective Displayed"
            theQuest.SetObjectiveDisplayed(GetUserInput() as int)
        elseIf questAction == "Set Objective Completed"
            theQuest.SetObjectiveCompleted(GetUserInput() as int)
        elseIf questAction == "Set Objective Failed"
            theQuest.SetObjectiveFailed(GetUserInput() as int)
        endIf
    endIf
endFunction

function ShowCategory_Armor(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "ARMO", "~ View Armor ~", showName = true, showEditorId = true, showFormId = true, option1 = "[View All Items]")
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "ARMO", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Armor theArmor = FormHelper.HexToForm(formId) as Armor

        int listOptions = JArray.object()
        JArray.addStr(listOptions, "[" + theArmor.GetName() + "]")
        JArray.addStr(listOptions, "Edit Armor Rating")
        JArray.addStr(listOptions, "Edit Armor Type")
        JArray.addStr(listOptions, "Set Enchantment")
        if theArmor.GetEnchantment()
            JArray.addStr(listOptions, "Set Enchantment Magnitude")
        endIf
        JArray.addStr(listOptions, "Set Slot Mask")

        string armorAction = GetUserSelection(JArray.asStringArray(listOptions))

        if armorAction == "Edit Armor Rating"
            int armorRating = GetUserInput(theArmor.GetArmorRating()) as int
            theArmor.SetArmorRating(armorRating)
            Debug.MessageBox("Set the armor rating of " + theArmor.GetName() + "  to " + armorRating)
        elseIf armorAction == "Edit Armor Type"

        elseIf armorAction == "Set Enchantment"
            Enchantment theEnchantmentOnArmor
            while ! theEnchantmentOnArmor
                int enchantmentResult = ChooseEnchantment()
                string enchantmentFormId = Search.GetResultFormID(enchantmentResult)
                Enchantment theEnchantment = FormHelper.HexToForm(enchantmentFormId) as Enchantment
                if theEnchantment
                    theArmor.SetEnchantment(theEnchantment)
                    theEnchantmentOnArmor = theArmor.GetEnchantment()
                    if theEnchantmentOnArmor
                        if theEnchantmentOnArmor == theEnchantment
                            Debug.MessageBox("Applied enchantment " + theEnchantment.GetName() + " to " + theArmor.GetName())
                        else
                            theEnchantmentOnArmor = None
                        endIf
                    endIf
                endIf
            endWhile

        elseIf armorAction == "Set Enchantment Magnitude"
            Enchantment theEnchantment = theArmor.GetEnchantment()
            int effectIndex = ChooseNthEnchantmentMagicEffect(theEnchantment)
            float originalMagnitude = theEnchantment.GetNthEffectMagnitude(effectIndex)
            float magnitude = GetUserInput(originalMagnitude) as float
            theEnchantment.SetNthEffectMagnitude(effectIndex, magnitude) 
            MagicEffect theEffect = theEnchantment.GetNthEffectMagicEffect(effectIndex)
            Debug.MessageBox("Changed magnitude of " + theEffect.GetName() + " from " + originalMagnitude + " to " + magnitude)

        elseIf armorAction == "Set Slot Mask"

        endIf

    elseIf selection == -2
        ; View All Items
        ItemAndSpellStorage.RemoveAllItems()
        int count = Search.GetResultCategoryCount(searchResults, "ARMO")
        int i = 0
        while i < count
            int item = Search.GetNthResultInCategory(searchResults, "ARMO", i)
            string formId = Search.GetResultFormID(item)
            Form theForm = FormHelper.HexToForm(formId)
            ItemAndSpellStorage.AddItem(theForm)
            i += 1
        endWhile
        ItemAndSpellStorage.GetActorBase().SetName("Items")
        ItemAndSpellStorage.OpenInventory(abForceOpen = true)
    endIf
endFunction

function ShowCategory_Weapon(int searchResults)
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
        Debug.MessageBox("Cast spell to place furniture")
        PlayerRef.AddSpell(Search_Placement_Spell)
        PlayerRef.EquipSpell(Search_Placement_Spell, 0)
        PlayerRef.EquipSpell(Search_Placement_Spell, 1)
        ObjectToPlace = FormHelper.HexToForm(formId)
    endIf
endFunction

function ShowCategory_Marker(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "LCRT", "~ Choose Marker ~", showName = false, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "LCRT", selection)
        string formId = Search.GetResultFormID(result)
        Debug.MessageBox(formId)
        Form theMarker = FormHelper.HexToForm(formId)
        Debug.MessageBox(theMarker)
        ObjectReference markerInstance = theMarker as ObjectReference
        Debug.MessageBox(markerInstance)
        ; Debug.MessageBox("Try casting the fork spell!")
        ; PlayerRef.AddSpell(Search_Placement_Spell)
        ; PlayerRef.EquipSpell(Search_Placement_Spell, 0)
        ; PlayerRef.EquipSpell(Search_Placement_Spell, 1)
        ; ObjectToPlace = FormHelper.HexToForm(formId)
    endIf
endFunction

function ShowCategory_Spell(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "SPEL", "~ ChooseSpell ~", showName = true, showEditorId = true, showFormId = true, option1 = "[View All Spells]")
    if selection == -2
        ; View All Spells
        RemoveAllSpells(ItemAndSpellStorage)
        AddAllSpellsToItemAndSpellStorage(searchResults)
        ShowSpellTradingMenu()

    elseIf selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "SPEL", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Spell theSpell = FormHelper.HexToForm(formId) as Spell
        Debug.MessageBox(theSpell + " " + theSpell.GetName())
    endIf
endFunction

function ShowCategory_Shout(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "SHOU", "~ Choose Shout ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "SHOU", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Shout theShout = FormHelper.HexToForm(formId) as Shout
        int i = 0
        bool loop = true
        while loop
            WordOfPower word = theShout.GetNthWordOfPower(i)
            if word
                Game.TeachWord(word)
                Game.UnlockWord(word)
            else
                loop = false
            endIf
            i += 1
        endWhile
        PlayerRef.AddShout(theShout)
        Debug.MessageBox("Taught player " + theShout.GetName())
    endIf
    PlayerRef.ModActorValue("DragonSouls", 13)
endFunction

function ShowCategory_WordOfPower(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "WOOP", "~ Choose Word of Power ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "WOOP", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        WordOfPower theWord = FormHelper.HexToForm(formId) as WordOfPower
        Game.TeachWord(theWord)
        Debug.MessageBox("Player has now learned the word " + theWord.GetName())
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Custom Choosers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Click on header:    -1
; Click on option 1:  -2
; Click on option 2:  -3
; Click on option 3:  -4
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
        option1Index = currentIndex
        currentIndex += 1
    endIf
    if option2
        listMenu.AddEntryItem(option2)
        option2Index = currentIndex
        currentIndex += 1
    endIf
    if option3
        listMenu.AddEntryItem(option3)
        option3Index = currentIndex
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

int function ChooseEnchantment()
    string enchantmentQuery = GetUserInput()
    if enchantmentQuery
        int enchantmentSearchResults = Search.ExecuteSearch(enchantmentQuery)
        int enchantmentIndex = ShowSearchResultChooser(enchantmentSearchResults, "ENCH", "~ Choose Enchantment to Apply ~")
        if enchantmentIndex > -1
            int enchantmentResult = Search.GetNthResultInCategory(enchantmentSearchResults, "ENCH", enchantmentIndex)
            return enchantmentResult
        endIf
    endIf
endFunction

int function ChooseNthEnchantmentMagicEffect(Enchantment theEnchanment)
    int options = JArray.object()
    int count = theEnchanment.GetNumEffects()
    int i = 0
    while i < count
        MagicEffect theEffect = theEnchanment.GetNthEffectMagicEffect(i)
        JArray.addStr(options, theEffect.GetName())
        i += 1
    endWhile
    string selection = GetUserSelection(JArray.asStringArray(options))
    int selectionIndex = JArray.findStr(options, selection)
    return selectionIndex
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

Form property ObjectToPlace auto
Spell property Search_Placement_Spell auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Item and Spell Storage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Actor property ItemAndSpellStorage auto
Actor property FakePlayerForSpellUI auto
UIMagicMenu property MagicMenu auto

function RemoveAllSpells(actor theActor)
    int count = theActor.GetSpellCount()
    int i = 0
    while i < count
        theActor.RemoveSpell(theActor.GetNthSpell(0))
        i += 1
    endWhile
endFunction

function AddAllSpellsToItemAndSpellStorage(int searchResults)
    int spellCount = Search.GetResultCategoryCount(searchResults, "SPEL")
    int i = 0 
    while i < spellCount
        int spellResult = Search.GetNthResultInCategory(searchResults, "SPEL", i)
        string formId = Search.GetResultFormID(spellResult)
        Spell theSpell = FormHelper.HexToForm(formId) as Spell
        ItemAndSpellStorage.AddSpell(theSpell)
        i += 1
    endWhile
endFunction

function ShowSpellTradingMenu()
    ItemAndSpellStorage.GetActorBase().SetName("Spells")
    MagicMenu = UIExtensions.GetMenu("UIMagicMenu") as UIMagicMenu
    MagicMenu.SetPropertyForm("receivingActor", PlayerRef)
    StartListeningToSpellMenuEvents()
    MagicMenu.OpenMenu(ItemAndSpellStorage)
endFunction

function StartListeningToSpellMenuEvents()
	RegisterForModEvent("UIMagicMenu_CloseMenu", "SpellMenu_OnClose")
	RegisterForModEvent("UIMagicMenu_AddRemoveSpell", "SpellMenu_OnSpellAddRemove")
endFunction

function StopListeningToSpellMenuEvents()
	UnregisterForModEvent("UIMagicMenu_CloseMenu")
	UnregisterForModEvent("UIMagicMenu_AddRemoveSpell")
endFunction

event SpellMenu_OnSpellAddRemove(string eventName, string strArg, float fltArg, Form sender)
    Spell theSpell = sender as Spell
    PlayerRef.AddSpell(theSpell)
    ; MagicMenu.SetPropertyForm("AddSpell", theSpell)
    RemoveAllSpells(FakePlayerForSpellUI)
    FakePlayerForSpellUI.GetActorBase().SetName(PlayerRef.GetActorBase().GetName())
    FakePlayerForSpellUI.AddSpell(theSpell)
    UI.InvokeForm("CustomMenu", "_root.Menu_mc.MagicMenu_SetSecondaryActor", FakePlayerForSpellUI)
endEvent

event SpellMenu_OnClose(string eventName, string strArg, float fltArg, Form sender)
    StopListeningToSpellMenuEvents()
endEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Items
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spells
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


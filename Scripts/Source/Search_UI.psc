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
string property ConfigPath_Weapon_Types      = ".search.config.weapon_types"       autoReadonly
string property ConfigurationFilePath        = "Data/Search/Config.json"           autoReadonly

function LoadConfiguration()
    int configFromFile = JValue.readFromFile(ConfigurationFilePath)
    if configFromFile
        JDB.solveObjSetter(ConfigPath_Root, configFromFile, createMissingKeys = true)
    else
        JDB.solveObjSetter(ConfigPath_KeyboardShortcuts, JMap.object(), createMissingKeys = true)
        JDB.solveObjSetter(ConfigPath_Category_Names,    JMap.object(), createMissingKeys = true)
        JDB.solveObjSetter(ConfigPath_Weapon_Types,      JMap.object(), createMissingKeys = true)
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
           category == "SCRL" || category == "BOOK" || category == "MISC" || \
           category == "SLGM"
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

; TODO - Clean up old ones when you search using the MAIN SEARCH UI - note that some searched do sub-searched
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
    JValue.retain(categoriesWithCounts)
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
            ResetInventoryView()
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
                        if theForm.GetType() == 42 || theForm.GetType() == 52 ; AMMO or SLGM
                            AddToInventoryView(theForm, 50)
                        else
                            AddToInventoryView(theForm)
                        endIf
                        categoryIndex += 1
                    endWhile
                endIf
                i += 1
            endWhile
            CurrentNotification = ""
            ShowInventoryView()
            
        elseIf categoryNameWithCount == "[View All Spells]"
            Debug.MessageBox("TODO")

        else
            int categoryIndex = JArray.findStr(categoriesWithCounts, categoryNameWithCount)
            string category = categoryNames[categoryIndex]
            ShowCategory(searchResults, category)
        endIf
    endIf

    JValue.release(categoriesWithCounts)
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Category Subview
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function ShowCategory(int searchResults, string category)
    if category == "[View All Items]"

    elseIf category == "CELL"
        ShowCategory_Cell(searchResults)

    elseIf category == "DIAL"
        ShowCategory_Dialogue(searchResults)

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

    elseIf category == "IDLE"
        ShowCategory_Idle(searchResults)

    elseIf category == "IMAD"
        ShowCategory_ImageSpaceModifier(searchResults)

    elseIf category == "MESG"
        ShowCategory_Message(searchResults)

    ; elseIf category == "SLGM"
    ;     ShowCategory_SoulGem(searchResults)

    elseIf category == "LCRT"
        Debug.MessageBox("Markers aren't yet really useful, we'll make it so you can move them, move TO them, and SEE them by changing the .ini settings")
        ShowCategory_Marker(searchResults)

    elseIf CategoryIsInventoryType(category)
        int selection = ShowSearchResultChooser(searchResults, category, "~ " + GetCategoryDisplayName(category) + " ~", showName = true, showEditorId = true, showFormId = true, option1 = "[View All Items]")
        if selection == -2
            ShowInventoryViewForCategory(searchResults, category)

        elseIf selection > -1
            int result = Search.GetNthResultInCategory(searchResults, category, selection)
            string editorId = Search.GetResultEditorID(result)
            string formId = Search.GetResultFormID(result)
            Form theItem = FormHelper.HexToForm(formId) as Form
            int count = 1
            if theItem.GetType() == 42 || theItem.GetType() == 52 ; AMMO or SLGM
                count = 50
            endIf
            count = GetUserInput(count) as int
            if count > 0
                PlayerRef.AddItem(theItem, count)
            endIf
        endIf

    else        
        int selection = ShowSearchResultChooser(searchResults, category, "~ " + GetCategoryDisplayName(category) + " ~", showName = true, showEditorId = true, showFormId = true)
        if selection > -1
            int    result   = Search.GetNthResultInCategory(searchResults, category, selection)
            string formId   = Search.GetResultFormID(result)
            string editorId = Search.GetResultEditorID(result)
            string name     = Search.GetResultName(result)
            string text     = "[Item Info]\n\n"
            if editorId
                text += editorId + "\n\n"
            endIf
            text += "(" + formId + ")\n\n"
            if name
                text += name
            endIf
            Debug.MessageBox(text)
        endIf
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
        if theQuest.IsCompleted()
            JArray.addStr(listOptions, "[ Completed ]")
        endIf
        JArray.addStr(listOptions, "[ Current Stage: " + theQuest.GetCurrentStageID() + " ]")
        JArray.addStr(listOptions, "Start Quest")
        JArray.addStr(listOptions, "Stop Quest")
        JArray.addStr(listOptions, "Reset Quest")
        JArray.addStr(listOptions, "Set Stage")
        JArray.addStr(listOptions, "Set Objective Displayed")
        JArray.addStr(listOptions, "Set Objective Completed")
        JArray.addStr(listOptions, "Set Objective Failed")
        JArray.addStr(listOptions, "Move To Next Quest Objective Location")

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
        elseIf questAction == "Move To Next Quest Objective Location"
            ConsoleUtil.ExecuteCommand("movetoqt " + editorId)
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
        ShowInventoryViewForCategory(searchResults, "ARMO")
    endIf
endFunction

function ShowCategory_Weapon(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "WEAP", "~ View Weapon ~", showName = true, showEditorId = false, showFormId = false, option1 = "[View All Items]")
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "WEAP", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Weapon theWeapon = FormHelper.HexToForm(formId) as Weapon

        int listOptions = JArray.object()
        JArray.addStr(listOptions, "[" + theWeapon.GetName() + "]")
        JArray.addStr(listOptions, "Add to Inventory")
        JArray.addStr(listOptions, "Edit Base Damage")
        JArray.addStr(listOptions, "Edit Critical Damage")
        JArray.addStr(listOptions, "Edit Weapon Type")
        JArray.addStr(listOptions, "Enchantment Item")
        JArray.addStr(listOptions, "Enchantment All Items")
        if theWeapon.GetEnchantment()
            JArray.addStr(listOptions, "Set Enchantment Magnitude")
        endIf

        string weaponAction = GetUserSelection(JArray.asStringArray(listOptions))

        if weaponAction == "Add to Inventory"
            int count = GetUserInput(1) as int
            if ! count
                count = 1
            endIf
            PlayerRef.AddItem(theWeapon, count)

        elseIf weaponAction == "Edit Base Damage"
            int originalBaseDamage = theWeapon.GetBaseDamage()
            int newBaseDamage = GetUserInput(originalBaseDamage) as int
            theWeapon.SetBaseDamage(newBaseDamage)
            Debug.MessageBox("Changed " + theWeapon.GetName() + " base damage from " + originalBaseDamage + " to " + newBaseDamage)

        elseIf weaponAction == "Edit Critical Damage"
            ; TODO

        elseIf weaponAction == "Edit Weapon Type"
            string originalTypeName = GetWeaponTypeName(theWeapon.GetWeaponType())
            string newTypeName = GetUserSelection(JMap.allKeysPArray(WeaponTypesMap))
            if newTypeName
                int newTypeId = GetWeaponIdFromName(newTypeName)
                theWeapon.SetWeaponType(newTypeId)
                Debug.MessageBox("Changed " + theWeapon.GetName() + " type from " + originalTypeName + " to " + newTypeName)
            endIf

        elseIf weaponAction == "Enchantment Item"
            Enchantment theEnchantmentOnWeapon
            ; while ! theEnchantmentOnWeapon
                int enchantmentResult = ChooseEnchantment()
                string enchantmentFormId = Search.GetResultFormID(enchantmentResult)
                Enchantment theEnchantment = FormHelper.HexToForm(enchantmentFormId) as Enchantment
                if theEnchantment
                    PlayerRef.AddItem(theWeapon)
                    PlayerRef.EquipItemEx(theWeapon, equipSlot = 1)
                    EnchantItem(theEnchantment, 0, 1)
                    Debug.MessageBox("Enchanted " + theWeapon.GetName() + " with " + theEnchantment.GetName())
                    ; theEnchantmentOnWeapon = 
                endIf
            ; endWhile

        elseIf weaponAction == "Enchantment All Items"
            Enchantment theEnchantmentOnWeapon
            while ! theEnchantmentOnWeapon
                int enchantmentResult = ChooseEnchantment()
                string enchantmentFormId = Search.GetResultFormID(enchantmentResult)
                Enchantment theEnchantment = FormHelper.HexToForm(enchantmentFormId) as Enchantment
                if theEnchantment
                    theWeapon.SetEnchantment(theEnchantment)
                    theEnchantmentOnWeapon = theWeapon.GetEnchantment()
                    if theEnchantmentOnWeapon
                        theWeapon.SetEnchantmentValue(10000)
                        if theEnchantmentOnWeapon == theEnchantment
                            Debug.MessageBox("Applied enchantment " + theEnchantment.GetName() + " to " + theWeapon.GetName())
                        else
                            theEnchantmentOnWeapon = None
                        endIf
                    endIf
                endIf
            endWhile
            
        elseIf weaponAction == "Set Enchantment Magnitude"
            Enchantment theEnchantment = theWeapon.GetEnchantment()
            int effectIndex = ChooseNthEnchantmentMagicEffect(theEnchantment)
            float originalMagnitude = theEnchantment.GetNthEffectMagnitude(effectIndex)
            float magnitude = GetUserInput(originalMagnitude) as float
            theEnchantment.SetNthEffectMagnitude(effectIndex, magnitude) 
            MagicEffect theEffect = theEnchantment.GetNthEffectMagicEffect(effectIndex)
            Debug.MessageBox("Changed magnitude of " + theEffect.GetName() + " from " + originalMagnitude + " to " + magnitude)

        endIf
    endIf
endFunction

; TODO support up to 10+ magic effects
function EnchantItem(Enchantment theEnchanment, int slotMask, int handSlot = 0)
    MagicEffect[] effects    = new MagicEffect[1]
    float[]       magnitudes = new float[1]
    int[]         areas      = new int[1]
    int[]         durations  = new int[1]

    effects[0]    = theEnchanment.GetNthEffectMagicEffect(0)
    magnitudes[0] = theEnchanment.GetNthEffectMagnitude(0)
    areas[0]      = theEnchanment.GetNthEffectArea(0)
    durations[0] = theEnchanment.GetNthEffectDuration(0)

    float maxCharge = 1000.0 ; ?

    WornObject.CreateEnchantment( \
        PlayerRef, \
        handSlot, \
        slotMask, \
        maxCharge, \
        effects, \
        magnitudes, \
        areas, \
        durations)

    ; ; int i = 0
    ; ; while i < 200
    ; ;     Armor theArmor = player.GetEquippedArmorInSlot(i)
    ; ;     if theArmor
    ; ;         Debug.MessageBox(theArmor.GetName() + " is equipped in slot " + i + " ---> " + theArmor.GetSlotMask())
    ; ;     endIf
    ; ;     i += 1
    ; ; endWhile
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
        PlayerRef.AddSpell(theSpell)
        Debug.MessageBox("Added " + theSpell.GetName() + " the player")
    endIf
endFunction

function ShowCategory_ImageSpaceModifier(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "IMAD", "~ Choose Image Space Modifier to Preview ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "IMAD", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        ImageSpaceModifier theImad = FormHelper.HexToForm(formId) as ImageSpaceModifier
        theImad.Apply(1.0)
        Debug.MessageBox("Applied " + editorId)
    endIf
endFunction

function ShowCategory_Message(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "MESG", "~ Choose Message to Show ~", showName = true, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "MESG", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Message theMessage = FormHelper.HexToForm(formId) as Message
        theMessage.Show()
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

function ShowCategory_Idle(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "IDLE", "~ Choose Idle to Play ~", showName = false, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "IDLE", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Idle theIdle = FormHelper.HexToForm(formId) as Idle

        Actor cursorActor = Game.GetCurrentCrosshairRef() as Actor

        if cursorActor
            int listOptions = JArray.object()
            JArray.addStr(listOptions, "[" + editorId + "]")
            JArray.addStr(listOptions, "Player Play Idle")
            JArray.addStr(listOptions, "NPC Play Idle")
            string idleAction = GetUserSelection(JArray.asStringArray(listOptions))
            if idleAction == "Player Play Idle"
                PlayerRef.PlayIdle(theIdle)
            elseIf idleAction == "NPC Play Idle"
                Debug.SendAnimationEvent(cursorActor, editorId)
            endIf
        else
            PlayerRef.PlayIdle(theIdle)
        endIf
    endIf
endFunction

function ShowCategory_Dialogue(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "DIAL", "~ Choose Dialogue Topic ~", showName = false, showEditorId = true, showFormId = false)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "DIAL", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)

        Actor cursorActor = Game.GetCurrentCrosshairRef() as Actor

        if cursorActor
            ConsoleUtil.SetSelectedReference(cursorActor)
            Debug.MessageBox(cursorActor.GetActorBase().GetName() + " say " + editorId)
        else
            Debug.MessageBox("say " + editorId)
            ConsoleUtil.ExecuteCommand("say " + editorId)
        endIf
    endIf
endFunction

; TODO
function ShowCategory_SoulGem(int searchResults)
    int selection = ShowSearchResultChooser(searchResults, "SLGM", "~ Choose Soul Gem ~", showName = false, showEditorId = true, showFormId = true)
    if selection > -1
        int result = Search.GetNthResultInCategory(searchResults, "SLGM", selection)
        string editorId = Search.GetResultEditorID(result)
        string formId = Search.GetResultFormID(result)
        Idle theIdle = FormHelper.HexToForm(formId) as Idle
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Weapon Types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int property WeaponTypesMap
    int function get()
        return JDB.solveObj(ConfigPath_Weapon_Types)
    endFunction
endProperty

string function GetWeaponTypeName(int weaponType)
    string[] weaponTypeNames = JMap.allKeysPArray(WeaponTypesMap)
    int i = 0
    while i < weaponTypeNames.Length
        string name = weaponTypeNames[i]
        int value = JMap.getInt(WeaponTypesMap, name)
        if value == weaponType
            return name
        endIf
        i += 1
    endWhile
endFunction

int function GetWeaponIdFromName(string name)
    if JMap.hasKey(WeaponTypesMap, name)
        return JMap.getInt(WeaponTypesMap, name)
    else
        return -1
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Custom Choosers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Click on header:    -1
; Click on option 1:  -2
; Click on option 2:  -3
; Click on option 3:  -4
int function ShowSearchResultChooser(int searchResults, string category, string header = "", bool showFilter = true, string filter = "", bool showPluginFilter = true, string pluginFilter = "", string option1 = "", string option2 = "", string option3 = "", bool showName = true, bool showFormId = true, bool showEditorId = false)
    int optionsToShow = JArray.object()

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    int currentIndex      = 0
    int headerIndex       = -1
    int option1Index      = -1
    int option2Index      = -1
    int option3Index      = -1
    int filterIndex       = -1
    int pluginFilterIndex = -1

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
    if showFilter
        if filter
            listMenu.AddEntryItem("[\"" + filter + "\"]")
        else
            listMenu.AddEntryItem("[Filter List]")
        endIf
        filterIndex = currentIndex
        currentIndex += 1
    endIf
    if showPluginFilter && ! pluginFilter
        if pluginFilter
            listMenu.AddEntryItem("[" + pluginFilter + "]")
        else
            listMenu.AddEntryItem("[Filter by Plugin]")
        endIf
        pluginFilterIndex = currentIndex
        currentIndex += 1
    endIf

    int count = Search.GetResultCategoryCount(searchResults, category)

    int selectionIndexToNthIndex = JIntMap.object()
    JValue.retain(selectionIndexToNthIndex)

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
            if ! pluginFilter || FormHelper.HexToModName(formId) == pluginFilter
                JArray.addStr(optionsToShow, text)
                listMenu.AddEntryItem(text)
                JIntMap.setInt(selectionIndexToNthIndex, itemIndex, i)
                itemIndex += 1
            endIf
        endIf
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()

    if selection > -1

        if showFilter && selection == filterIndex
            JValue.release(selectionIndexToNthIndex)
            return ShowSearchResultChooser(searchResults, category, \
                header           = header, \
                showFilter       = showFilter, \
                filter           = GetUserInput(), \
                showPluginFilter = showPluginFilter, \
                pluginFilter     = pluginFilter, \
                option1          = option1, \
                option2          = option2, \
                option3          = option3, \
                showName         = showName, \
                showFormId       = showFormId, \
                showEditorId     = showEditorId)
        elseIf showPluginFilter && selection == pluginFilterIndex
            JValue.release(selectionIndexToNthIndex)
            return ShowSearchResultChooser(searchResults, category, \
                header           = header, \
                showFilter       = showFilter, \
                filter           = filter, \
                showPluginFilter = showPluginFilter, \
                pluginFilter     = GetUserInput(), \
                option1          = option1, \
                option2          = option2, \
                option3          = option3, \
                showName         = showName, \
                showFormId       = showFormId, \
                showEditorId     = showEditorId)
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
                JValue.release(selectionIndexToNthIndex)
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
    JValue.retain(optionsToShow)

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
            string[] theOptions = JArray.asStringArray(optionsToShow)
            JValue.release(optionsToShow)
            return GetUserSelection(theOptions, showFilter = true, filter = GetUserInput())
        else
            int index = selection
            if showFilter
                index = selection - 1
            endIf
            string option = JArray.getStr(optionsToShow, index)
            JValue.release(optionsToShow)
            return option
        endIf
    endIf
endFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Object Placement Spell
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Form property  ObjectToPlace          auto
Spell property Search_Placement_Spell auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Item and Spell Storage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Actor       property ItemAndSpellStorage  auto
Actor       property FakePlayerForSpellUI auto
UIMagicMenu property MagicMenu            auto

function ShowInventoryViewForCategory(int searchResults, string category)
    ResetInventoryView()
    int count = Search.GetResultCategoryCount(searchResults, category)
    int i = 0
    while i < count
        int item = Search.GetNthResultInCategory(searchResults, category, i)
        string formId = Search.GetResultFormID(item)
        Form theForm = FormHelper.HexToForm(formId)
        if theForm.GetType() == 42 || theForm.GetType() == 52 ; AMMO or SLGM
            AddToInventoryView(theForm, 50)
        else
            AddToInventoryView(theForm)
        endIf
        i += 1
    endWhile
    ShowInventoryView()
endFunction

function ResetInventoryView()
    ItemAndSpellStorage.RemoveAllItems()
endFunction

function AddToInventoryView(Form theForm, int count = 1)
    ItemAndSpellStorage.AddItem(theForm, count)
endFunction

function ShowInventoryView()
    ItemAndSpellStorage.GetActorBase().SetName("Items")
    ItemAndSpellStorage.OpenInventory(abForceOpen = true)
endFunction

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


scriptName ConsoleSearchUI_Search extends ActiveMagicEffect  

event OnEffectStart(Actor target, Actor caster)
    Show()
endEvent

function Show()
    string query = GetTextInput()

    int allResults = ConsoleSearch.Search(query)

    ConsoleSearch.SaveResult(allResults)
    ConsoleSearch.SaveResultToFile(allResults, "SearchResults.json")

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

    string[] categories = ConsoleSearch.GetResultCategories(allResults)
    int i = 0
    while i < categories.Length
        listMenu.AddEntryItem(categories[i])
        i += 1
    endWhile

    listMenu.OpenMenu()

    int selection = listMenu.GetResultInt()
    string category = categories[selection]

    string text = ""

    int count = ConsoleSearch.GetResultCategoryCount(allResults, category)

    Debug.MessageBox("Category " + category + " has " + count + " results")

    i = 0
    while i < count
        int result = ConsoleSearch.GetNthResultInCategory(allResults, category, i)
        string name = ConsoleSearch.GetResultName(result)
        string editorId = ConsoleSearch.GetResultEditorID(result)
        string formId = ConsoleSearch.GetResultFormID(result)
        Form theForm = FormHelper.HexToForm(formId)
        text += name + " " + formId + " " + theForm + " " + theForm.GetName() + "\n"
        i += 1
    endWhile

    Debug.MessageBox(text)

    ConsoleSearch.DeleteResult(allResults)
endFunction

string function GetTextInput()
    UITextEntryMenu textEntry = UIExtensions.GetMenu("UITextEntryMenu") as UITextEntryMenu
    textEntry.OpenMenu()
    return textEntry.GetResultString()
endFunction

scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    ; API.UnregisterForAllKeys()
    ; API.Setup()
    ; API.OpenSearchPrompt()

    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", "")

    ConsoleUtil.ExecuteCommand("ss npc sven")

    Utility.WaitMenuMode(1.0)

    string text = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")

    Debug.MessageBox(text)
endEvent

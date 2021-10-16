scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory.maxScroll", 100000)
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._maxScroll", 100000)
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory.maxChars", 100000)
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._maxChars", 100000)

    API.UnregisterForAllKeys()
    API.Setup()
    API.OpenSearchPrompt()
endEvent

scriptName Search_UI_LoadGameHandler extends ReferenceAlias
{Handled `OnPlayerLoadGame` events for the `Search` mod.

Simply calls `Search_UI.Setup()` on player load game.}

event OnPlayerLoadGame()
    (GetOwningQuest() as Search_UI).Setup()
endEvent

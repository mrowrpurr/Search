scriptName Search_UI_LoadGameHandler extends ReferenceAlias
{Handled `OnPlayerLoadGame` events for the `Search` mod.

Simply calls `Search_UI.Setup()` on player load game.}

event OnInit()
    ; Load up the spell for testing
    Spell theSpell = Game.GetFormFromFile(0xd64, "Search.esp") as Spell
    GetActorReference().EquipSpell(theSpell, 0)
    GetActorReference().EquipSpell(theSpell, 1)
endEvent

event OnPlayerLoadGame()
    (GetOwningQuest() as Search_UI).Setup()
endEvent

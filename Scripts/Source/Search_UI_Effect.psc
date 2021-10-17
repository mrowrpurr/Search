scriptname Search_UI_Effect extends ActiveMagicEffect
{Opens Search UI when this spell (_lesser power_) is triggered.}

Search_UI property API auto

event OnEffectStart(Actor target, Actor caster)
    Actor player = Game.GetPlayer()

    ; Armor helmet = player.GetEquippedArmorInSlot(1)

    ; int i = 0
    ; while i < 200
    ;     Armor theArmor = player.GetEquippedArmorInSlot(i)
    ;     if theArmor
    ;         Debug.MessageBox(theArmor.GetName() + " is equipped in slot " + i + " ---> " + theArmor.GetSlotMask())
    ;     endIf
    ;     i += 1
    ; endWhile

    ; if helmet
        MagicEffect fireDamange = Game.GetForm(0x4605a) as MagicEffect
        MagicEffect fortifyArchery = Game.GetForm(0x7a0fe) as MagicEffect

        MagicEffect[] effects    = new MagicEffect[1]
        float[]       magnitudes = new float[1]
        int[]         areas      = new int[1]
        int[]         durations  = new int[1]

        ; effects[0]    = fireDamange
        effects[0]    = fortifyArchery
        magnitudes[0] = 50.0
        areas[0]      = 0
        durations[0]  = 0

        int handSlot = 0 ; ? Right ?
        ; int handSlot = 1 ; ? Right ?
        int slotMask = 31 ; ? Hand ?

        float maxCharge = 1000.0 ; ?

        WornObject.CreateEnchantment( \
            player, \
            handSlot, \
            slotMask, \
            maxCharge, \
            effects, \
            magnitudes, \
            areas, \
            durations)
    ; endIf

    API.UnregisterForAllKeys()
    API.Setup()
    API.OpenSearchPrompt()
endEvent

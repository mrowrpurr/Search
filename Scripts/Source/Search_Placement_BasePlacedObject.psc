scriptName Search_Placement_BasePlacedObject extends ObjectReference  

Search_UI property API auto 

event OnInit()
    Debug.MessageBox("Hello, I am a fork. I exist now!")
    PlaceAtMe(API.ObjectToPlace)
    Delete()
endEvent

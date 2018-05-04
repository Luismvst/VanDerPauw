#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Van der Pauws"
	"Panel/ç", /Q, VDP_Panel()
	"Initialize", /Q, VDP_initialize()
	"Close", /Q, VDP_close()
end

Function VDP_Panel ()

	string path = "root:VanDerPauw" 
	if (ItemsinList (WinList ("VDPanel", ";", "")) > 0 )
		DoWindow /F VDPanel
		return 0
	else if (!DataFolderExists(path))
		VDP_initialize()
	endif
	
		
End
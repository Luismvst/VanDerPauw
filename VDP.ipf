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
	elseif (!DataFolderExists(path))
		VDP_initialize()
	endif
	string savedf = getdatafolder (1)
	SetDataFolder path
	
	VDP_initialize()
	
	string :MagicBox:com
	variable :K2600:npoints
	variable :K2600:nmin
	variable :K2600:nmax
	
	make /d/o data, fitting, resistance, origin, v_r
	wave data, fitting, resistance, origin, v_r
		
End

Function VDP_initialize()

End
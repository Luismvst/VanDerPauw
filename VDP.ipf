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
	init_K2600()
	init_MBox()
End

Function init_K2600 ([mode])
	//mode is used to print on history commands "Keithley has beed initialized"
	//If mode == 0 -> NO PRINT 
	variable mode 
	if (Paramisdefault(mode))
		mode = 1 
	endif
	DFRef saveDFR=GetDataFolderDFR()
	string path = "root:VanDerPauw:K2600"
	if (!DataFolderExists(path))
		genDFolders(path)
	endif
	DFRef dfr = $path
	SetDataFolder dfr 
	
	InitBoard _GPIB (0)
	InitDevice_GPIB (0, 26)
	
	if (mode)
		print "Keithley initialized"
	endif
	SetDataFolder saveDFR
End

Function init_MBox()
	DFRef saveDFR = GetDataFolderDFR()
	string path = "root:VanDerPauw:MagicBox"
	  if (!DataFolderExists(path))
	  	genDFolders (path)
	  endif
	  DFRef dfr = $path
	  SetDataFolder dfr
	  
	  string sports = GetSerialPorts()
	  string /G com = sports
	  string /G Device = "MagicBox"
	  
	  init_OpenSerial (com, Device)
	  MBox_Change(com, 0)	//Idle state
	  SetDataFolder saveDFR
End

Function close_K2600 ()
	DevClearList (0,26)
end

Function init_OpenSerial (com, Device)
	
	string com, Device
	string cmd, DeviceCOmmands
	variable flag
	if (StringMatch (Device, "MagicBox")) //Made for spectroscopic, if theres more instruments connected
		DeviceCOmmands = " baud=1200, stopbits=1, databits=8, parity=0"
	endif
	//Is the port available in the computer?
	if (WhichListItem(com, sports)!=1)
	endif
end

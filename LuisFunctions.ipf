#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "serialcom"

Menu "Functions_Luis"
	"MagicBoxParty",/Q, MBox_Party()
	"Init",/Q, init_OpenSerial("COM3", "MagicBox")
End 

Function MBox_Party ()

	string com = "COM3"
	string Device = "MagicBox"
	if (init_OpenSerial (com, Device))
		//print Device + " Initialized"
	endif
	variable i
	for (i = 0; i<13; i+=1)
		MBox_Change (com, i)
	endfor	
End

Function init_OpenSerial (com, Device)

	string com, Device
	string cmd, DeviceCommands
	variable flag
	string sports=getSerialPorts()
	if(StringMatch(Device,"MagicBox"))	//It looks for the Word in the DeviceStr
		DeviceCommands=" baud=1200, stopbits=1, databits=8, parity=0"
	endif
		// is the port available in the computer?
	//if (WhichListItem(com,sports)!=-1)
	if (1)
		cmd = "VDT2 /P=" + com + DeviceCommands
		Execute cmd
		cmd = "VDTOperationsPort2 " + com
		Execute cmd
		cmd = "VDTOpenPort2 " + com
		Execute cmd
		flag = 1
	else
		//Error Message with an OK button
		string smsg="Problem openning port:" +com+". Try the following:\r"
		smsg+="0.- TURN IT ON!\r"
		smsg+="1.- Verify is not being used by another program\r"
		smsg+="2.- Verify the PORT is available in Device Manager (Ports COM). If not, rigth-click and scan hardware changes or disable and enable it.\r"
		DoAlert /T="Unable to open Serial Port" 0, smsg
		Abort "Execution aborted.... Restart IGOR"
	endif
	return flag 
end

Function MBox_Change (com, mode)
	
	variable mode
	string com
	
	string command, cmd
	command = Change(mode)
	
	variable i
	variable length = strlen (command)
	
	//Opening Serial Port -> Optional, not really needed. Ensure Port's working well
	cmd = "VDTOpenPort2 " + com
	Execute cmd
	for (i = 0; i<length; i+=1)
		VDTWrite2 command[i]
		delay (100)		//Delay dont really needed, but the PIC and serialport gets a better syncronization
		//I close the serial-port to ensure the character is sent
		cmd = "VDTClosePort2 " + com
		Execute cmd 
		if (V_VDT != 1)
			string str = "Reestart the device and the program"
			DoAlert /T="Unable to write in serial port", 0, str
			Abort  "Execution aborted.... Restart IGOR"
		endif
	endfor	
	delay (100) 	
	//needed for the pic to have time to operate ( USUALLY 1000 MSEC, BUT NOT REALLY TRUE )
End

Function/S Change(mode) 
	variable mode
	switch(mode)
		case 0: 
			return "Z"		//Idle state
		case 1: 
			return "ZABCD"	
		case 2: 
			return "ZEFGH"	
		case 3: 
			return "ZIJKL"	
		case 4: 
			return "ZMNOP"	
		case 5: 
			return "ZAEIM"	
		case 6: 
			return "ZBFJN"
		case 7: 
			return "ZCGKO"	
		case 8:
			return "ZDHLP"	
		case 9:
			return "ZAFKP"	
		case 10:
			return "ZDGJM"		
		case 11:
			return "ZAFKPDGJM"		//Estado de error
		case 12:
			return "ZAFKPDGJMEIBNCOHLZ"		//Complete
		default:			
			return "ZX" 		//Execution
	endswitch		
End
#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <FilterDialog> menus=0

Menu "Van der Pauws"
	"Panel/ç", /Q, VDP_Panel ()
	"Initialize",/Q, init()
	"Close Keithley",/Q,  close_K2600()
	End
End

//This function is the main action of the code
Function/wave VanDerPauws()

	svar com = root:VanDerPauw:MagicBox:com
	nvar npoints = root:VanDerPauw:K2600:npoints
	nvar nmin = root:VanDerPauw:K2600:nmin
	nvar nmax = root:VanDerPauw:K2600:nmax
		
	SetDataFolder root:VanDerPauw
	nvar result
	wave data, Resistance, Origin, V_r, increment
	clear()
	variable i
//	WAVEClear data, Resistance, Origin, V_r
	for (i = 0; i<8; i+=1) 
		if (i == 0 )
			MBox_Change(com,2)	
		endif
		wave ivResult = IVmeas (nmax, npoints)
		if (i<1)
			concatenate/O {increment}, data
			concatenate   {ivResult}, data                 
		else
			concatenate	 {ivResult}, data
		endif
//		data[*][i+1]=ivResult[p]
		CurveFit/Q /W=1 line, data[][i+1] /X=data[][0] /D
		wave fitting = $"fit_data"
		if(i<1)
			concatenate/O {fitting}, fit
		else 
			concatenate {fitting}, fit
		endif
		//Appendtograph /W=VDPanel#VDPGraph data[][0] vs fit[][i]
		 
		Resistance[i] = 1/V_Sigb
		Origin[i]     = V_Siga
		V_r[i] 		 = V_r2
		
	//		StatsLinearRegression
	endfor
	string nameDisplay = "VDPanel#VDPGraph"
	Appendtograph/W=$nameDisplay /C=(65535,65535,0)		data[*][0] vs data[*][2] 
	Appendtograph/W=$nameDisplay /C=(0,0,65535)			data[*][0] vs data[*][3] 
	Appendtograph/W=$nameDisplay /C=(65535,0,52428)		data[*][0] vs data[*][4] 
	Appendtograph/W=$nameDisplay /C=(39321,1,1)			data[*][0] vs data[*][5] 
	Appendtograph/W=$nameDisplay /C=(39321,39321,39321)	data[*][0] vs data[*][6] 
	Appendtograph/W=$nameDisplay /C=(0,65535,0)			data[*][0] vs data[*][7]
	ModifyGraph  /W=$nameDisplay mirror=1, tick=2, zero=2, minor = 1, mode=3, standoff=0
	MBox_Change(com, 0)	//Idle state. Disconnected.
	
	//Cálculo de VanDerPauws para las 8 pendientes
	result = VDP_Calculo()
		
	return data
End

Function VDP_Calculo ()

	wave Resistance, coefs
	variable Rv, Rh, Rs
	//Rvertical = (3 + 4 + 7 + 8) / 4
	//Rhorizontal = (1 + 2 + 5 + 6) / 4
	//Equation -> e^(-pi*Rvertical/Rs) + e^(-pi*Rhorizontal/Rs) = 1
	
	Rv = (Resistance[2] + Resistance[3] + Resistance[6] + Resistance[7])/4 
	Rh = (Resistance[0] + Resistance[1] + Resistance[4] + Resistance[5])/4	

	coefs={Rv, Rh}
 	FindRoots/Q MyFunc, coefs
 	Rs = V_Root
 	
 	return Rs 	
end

Function MyFunc (w, x)
	
	wave w
	variable x
	
	//Return root value for f(x) = 0
	return ( exp (-PI*w[0]/x ) + exp (-PI*w[1]/x ) ) - 1 

end
	
End
//Initialize both keithley and magic box
Function init ()
	init_K2600()
	init_MBox ()
End

Function init_K2600([mode])
	//mode is used to print on history commands that Keithley has been initialized
	//If mode == 0, NO PRINT
	variable mode
	if (paramisdefault(mode))
		mode=1
	endif
	DFRef saveDFR=GetDataFolderDFR()
	string path = "root:VanDerPauw:K2600"
	if(!DatafolderExists(path))
		genDFolders (path)
	endif
	DFRef dfr = $path
	SetDatafolder dfr
	
	InitBoard_GPIB(0)
	InitDevice_GPIB(0,26)
	
	variable/G   npoints = 10
	variable/G 	nmin	= 0
	variable/G 	nmax  = 0.01	
	
	if (mode)
		print "Keithley initialized"
	endif
	SetDataFolder saveDFR
End

Function init_MBox()
	DFRef saveDFR=GetDataFolderDFR()
	string path = "root:VanDerPauw:MagicBox"
	if(!DatafolderExists(path))
		genDFolders (path)
	endif
	DFRef dfr = $path
	SetDatafolder dfr
	
	string /G com	= "COM5"
	string /G Device 	= "MagicBox"
	
	init_OpenSerial (com, Device)	
	MBox_Change(com, 0)	//Idle state. Disconnect.
	SetDataFolder saveDFR
End

//This closes the Keithley 
Function  close_K2600()
	DevClearList(0,26)
End

Function init_OpenSerial (com, Device)

	string com, Device
	string cmd, DeviceCommands
	variable flag
	string/G sports=getSerialPorts()
		print sports
	if(StringMatch(Device,"MagicBox"))	//It looks for the Word in the DeviceStr
		DeviceCommands=" baud=1200, stopbits=1, databits=8, parity=0"
	endif
		// is the port available in the computer?
	if (WhichListItem(com,sports)!=-1)
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

//This function is where the conmutation takes place
Function MBox_Change (com, mode)
	
	variable mode
	string com
	
	SetDataFolder root:VanDerPauw:
	
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
	//There will be 8 different measurings
	variable mode
	
	//		|---------------	|
	//		|	1*		 *2		|	Representación de las 4 puntas
	//		|					|	
	//		|	4*		 *3		|
	//		|---------------	|
	
	switch(mode)
		case 0: 
			return "Z"		//Idle state
		case 1: //R21,43
			return "ZBEKPX"	//I21, V43
		case 2: //R12,43
			return "ZAFKPX"	//I12, V43
		case 3: //R23,14
			return "ZBHIOX"	//I23, V14
		case 4: //R32,14
			return "ZDFIOX"	//I32, V14
		case 5: //R34,21
			return "ZDGJMX"	//I34, V21
		case 6: //R43,21
			return "ZCHJMX"	//I43, V21
		case 7: //R41,32
			return "ZCELNX"	//I41, V32
		case 8: //R14,32
			return "ZAGLNX"	//I14, V32
		case 9:
			return "" 		//Nothing
		default: 
			return "ZAFKPDGJM"		//Estado de error
	endswitch	
	
	//Calcululation VDP following "mode"
	//Rvertical = (3 + 4 + 7 + 8) / 4
	//Rhorizontal = (1 + 2 + 5 + 6) / 4
	//Equation -> e^(-pi*Rvertical/Rs) + e^(-pi*Rhorizontal/Rs) = 1
	
End

//Source current and measure voltage, in 4-probe mode
Function/wave SweepI_MeasV (imin, imax, npoints, ivResult)

	variable imin
	variable imax
	variable npoints
	wave ivResult
	
	variable inc, i
	
	string channelI = "a"
	string channelV = "b"
	string cmd
	
	variable probe=2
	variable vlimit = 5
	variable nplc = 1
	variable delay = 1
	
	//Working
	variable step = (imax-imin)/( npoints-1 )
	make /o/d/n=(10) increment
	wave increment
	//wi=imin + step*x
	variable deviceID = getDeviceID ("K2600")
	
	clear_K2600 (deviceID)
	
	configK2600_GPIB(deviceID,2,channelI,probe,vlimit,nplc,delay) // 2 (2nd argument) = measure voltage
	
	configK2600_GPIB(deviceID,2,channelV,probe,vlimit,nplc,delay) // 2 (2nd argument) = measure voltage

	cmd="smu"+channelI+".source.output = smu"+channelI+".OUTPUT_ON"
	sendcmd_GPIB(deviceID,cmd)
	
	cmd="smu"+channelV+".source.output = smu"+channelV+".OUTPUT_ON"
	sendcmd_GPIB(deviceID,cmd)	
	
	string target
	for (i=0; i<(npoints); i+=1)
		inc=imin + step*	i
		cmd="smu"+channelI+".source.leveli = "+num2str(inc)
		sendcmd_GPIB(deviceID,cmd)
		
		cmd="smu"+channelV+".source.leveli = 0.00"
		sendcmd_GPIB(deviceID,cmd)
		
		
		cmd="print(smu"+channelV+".measure.v(smu"+channelV+".nvbuffer1))"
		sendcmd_GPIB(deviceID,cmd)
		GPIBRead2 /Q target
		ivResult[i]=str2num(target)
		increment[i] = inc
	endfor
	
	cmd="smu"+channelI+".source.output = smu"+channelI+".OUTPUT_OFF"
	sendcmd_GPIB(deviceID,cmd)

	cmd="smu"+channelV+".source.output = smu"+channelV+".OUTPUT_OFF"
	sendcmd_GPIB(deviceID,cmd)	
	
	sendcmd_GPIB(deviceID,"smu"+channelI+".reset()")
	sendcmd_GPIB(deviceID,"smu"+channelV+".reset()")
	
	GPIB2 InterfaceClear
	GPIB2 KillIO

	return ivResult
end

Function clear_K2600(deviceID)

	variable deviceID
	string channelI = "a"
	string channelV = "b"
	
	string cmd="smu"+channelI+".reset()"
	sendcmd_GPIB(deviceID,cmd)

	cmd="smu"+channelV+".reset()"
	sendcmd_GPIB(deviceID,cmd)	
	
	
	cmd="smu"+channelI+".nvbuffer1.clear()"  //Clear buffer, in case it contains something
	sendcmd_GPIB(deviceID,cmd)

	cmd="smu"+channelI+".nvbuffer2.clear()"  //Clear buffer, in case it contains something
	sendcmd_GPIB(deviceID,cmd)


	cmd="smu"+channelV+".nvbuffer1.clear()"  //Clear buffer, in case it contains something
	sendcmd_GPIB(deviceID,cmd)

	cmd="smu"+channelV+".nvbuffer2.clear()"  //Clear buffer, in case it contains something
	sendcmd_GPIB(deviceID,cmd)

end

//Measure IV. Sweep I and measure V
Function/wave IVmeas (nmax, npoints, [nmin])

	variable nmax, npoints
	variable nmin
	if (paramisdefault(nmin))
		nmin= 0
	endif
	if (nmin > nmax )
		string str = "Reestart the device and the program"
		DoAlert /T="Error. Nmin > Nmax.", 0, str
		Abort  "Execution aborted.... Restart IGOR"
	endif
	make /O/N = (npoints)	ivResult	
	
	init_K2600 (mode=0)	//Reset, to be as "clean" as possible
	sweepI_measV ( nmin, nmax, npoints, ivResult )	
	
	return ivResult
end

Function ButtonProcVDP(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar  npoints = root:VanDerPauw:K2600:npoints
			wave data = root:VanDerPauw:data
			
			strswitch (ba.ctrlname)			
			case "buttonMeas":
				VanDerPauws()
				break
			case "buttonClear":
					Clear()
				break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function Clear ()
	
	DFRef saveDFR=GetDataFolderDFR()
	string path = "root:VanDerPauw"
	DFRef dfr = $path
	SetDatafolder dfr
	wave fit, Resistance, Origin, V_r, data, ivResult
	nvar result
	variable i
	for (i=0; i<10; i+=1)
		RemoveAllTraces()
	endfor
		
	data = 0; resistance = 0; fit = 0; origin = 0; v_r= 0; ivResult = 0; result = 0; 
	Redimension /N=-1 data, resistance, fit
 	
	
End

function RemoveAllTraces ()
	string df = "root:VanDerPauw"
	String CurrentDF = GetDataFolder(1)
	SetDataFolder $df
	variable i
	do 
		string listatraces = tracenamelist("VDPanel#VDPGraph", ";", 1)
		string trace = stringfromlist (i, listatraces)
		if (strlen(trace)==0)
			break
		endif
		removefromgraph /W=VDPanel#VDPGraph $trace
		i+=1
	while(1)	
	SetdataFolder $CurrentDF
end

Function VDP_Panel ()
	
	string path = "root:VanDerPauw"
	string savedatafolder = GetDataFolder (1) 
	if(!DatafolderExists(path))
		string smsg = "You have to initialize first.\n"
		smsg += "Do you want to initialize?\n"
		DoAlert /T="Unable to open the program" 1, smsg
		if (V_flag == 2)		//Clock No
			Abort "Execution aborted.... Restart IGOR"
		elseif (V_flag == 1)	//Click yes
			init()
		endif
	endif
	SetDataFolder path
	
	//GetData
	svar	com =		 	:MagicBox:com	// Add Z in the future
	nvar	npoints = 	:K2600:npoints 
	nvar	nmin = 		:K2600:nmin
	nvar	nmax =		 	:K2600:nmax  
	
	make /d/o/n=(10) data
	make /d/o/n=(8) Resistance, Origin, V_r
	make /d/o fit, fitting
	make /d/o/n=2 coefs
	wave data, fitting, Resistance, Origin, V_r	//temporal Waves for the table
	variable/G result
	data = 0; resistance = 0; fitting = 0; fit = 0; origin = 0; v_r= 0; coefs=0;
	if (ItemsinList (WinList("VDPanel", ";", "")) > 0)
		SetDrawLayer /W=VDPanel Progfront
		DoWindow /F VDPanel
		return 0
	endif
	
	PauseUpdate; Silent 1		// building window...
	
	//Panel
	DoWindow /K VDPanel
	//NewPanel /K=0 /W=(773,53,1273,718) as "VDP Panel"
	NewPanel /K=0 /W=(750,53,1289,571) as "VDP Panel"
	DoWindow /C VDPanel
	
	//Buttons
	Button buttonClear, pos={278.00,318.00},size={80.00,30.00}, proc=ButtonProcVDP, title="Clean"
	Button buttonClear, fSize=12,fColor=(65535,49157,16385)
	Button buttonMeas, pos={250.00,449.00},size={118.00,47.00}, proc=ButtonProcVDP, title="Measure"
	Button buttonMeas, fSize=16,fColor=(1,16019,65535)
	
	//Table
	string name = "v_r"
	wave v_r2 = $name
	
	Edit/K=1/W=(28,328,224,497)/HOST=VDPanel Resistance, Origin, V_r2 
	ModifyTable format(Point)=1,width(Point)=34,format(Resistance)=3,width(Resistance)=60
	ModifyTable rgb(Resistance)=(65535,0,0),format(Origin)=3,width(Origin)=50,rgb(Origin)=(40000,10000,30000)
	ModifyTable format(v_r2)=3,width(v_r2)=50,rgb(v_r2)=(10000,50000,20000)
	ModifyTable showParts=0xa
	ModifyTable statsArea=85
	
	RenameWindow #,VDTable
	
	//SetVar
	SetVariable setvarmaxcurrent,pos={382.00,34.00},size={140.00,18.00},title="Max. Current"
	SetVariable setvarmaxcurrent,limits={0,0.01,0.001},value= root:VanDerPauw:K2600:nmax
	SetVariable setvarmincurrent,pos={382.00,58.00},size={140.00,18.00},disable=2,title="Min. Current"
	SetVariable setvarmincurrent,limits={-0.01,0.01,0.001},value= root:VanDerPauw:K2600:nmin
	SetVariable setvarpoints,pos={382.00,83.00},size={140.00,18.00},title="Nº of points"
	SetVariable setvarpoints,limits={0,1,120},value= root:VanDerPauw:K2600:npoints
	
	//Text
	DrawText 255,394,"Total Resistance:"
	
	ValDisplay valdisp0,pos={254.00,401.00}, size={89.00,17.00}
	ValDisplay valdisp0,barmisc={0,100}
	ValDisplay valdisp0,value=#"root:VanDerPauw:result"
	
	//Display	
	string nameDisplay="VDPanel#VDPGraph"
	Display/K=1/W=(25,27,360,306)/HOST=VDPanel data[*][0] vs data[*][1] 	
	RenameWindow #,VDPGraph
	Label /W=$nameDisplay bottom "Voltage (V)"
	Label /W=$nameDisplay left "Intensity (A)"	
	ModifyGraph  /W=$nameDisplay mirror=1, tick=2, zero=2, minor = 1, mode=3, standoff=0
	SetDataFolder savedatafolder
end

//Function/wave MedirUna (num)
//
//	variable num
//	svar com = root:VanDerPauw:MagicBox:com
//	nvar npoints = root:VanDerPauw:K2600:npoints
//	nvar nmin = root:VanDerPauw:K2600:nmin
//	nvar nmax = root:VanDerPauw:K2600:nmax
//	
//	SetDataFolder root:VanDerPauw
//	variable /G root:VanDerPauw:vr2
//	variable/G result
//	VDP_Panel()
//	wave data = root:VanDerPauw:data
//	wave fitting = root:VanDerPauw:fitting
//	wave resistance = root:VanDerPauw:resistance
//	wave origin = root:VanDerPauw:origin
//	wave v_r = root:VanDerPauw:V_r
//	variable i
//	
//	
//	for (i = num; i<num+1; i+=1) 
//		MBox_Change(com, i+1)
//		wave aux = IVmeas (nmax, npoints)
//
//		if (i<1)
//			concatenate/O {aux}, data	// /NP -> prevents promotion to higher dimension
//		else
//			concatenate {aux}, data
//		endif
//		
//		
//		CurveFit/Q line, data[][0][i] /X=data[][1][i] /D
//		//Appendtograph /W=VDPanel#VDPGraph root:VanDerPauw:fit_ivResult
//		
////		string wavefit = wavelist ("fit*", ";", "") + "_" + num2str (i)
////		wave fitting = $wavefit 
////		Appendtograph  /W=VDPanel#VDPGraph 	fitting
//		Resistance[i] = 1/V_Sigb
//		Origin[i]     = V_Siga
//		V_r[i] 		 = V_r2
//	//	ModifyTable /W=VDTable format(Point) = 1
//		
////		StatsLinearRegression
//	endfor
//	
//	//Appendtograph /W=VDPanel#VDPGraph root:VanDerPauw:fitting
//	MBox_Change(com, 0)	//Idle state. Disconnected.
//	
//	//Cálculo de VanDerPauws para las 8 pendients caculadas halolar su media 
//	//****/IMPLEMENTAR/****//
//	//result = V_avg
//	
//	return data
//End

Window VDPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(750,53,1289,571) as "VDP Panel"
	SetDrawLayer UserBack
	DrawText 255,394,"Total Resistance:"
	Button buttonClear,pos={278.00,318.00},size={80.00,30.00},proc=ButtonProcVDP,title="Clean"
	Button buttonClear,fSize=12,fColor=(65535,49157,16385)
	Button buttonMeas,pos={250.00,449.00},size={118.00,47.00},proc=ButtonProcVDP,title="Measure"
	Button buttonMeas,fSize=16,fColor=(1,16019,65535)
	ValDisplay valdisp0,pos={254.00,401.00},size={89.00,17.00}
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,100}
	ValDisplay valdisp0,value= #"root:VanDerPauws:result"
	SetVariable setvarmaxcurrent,pos={382.00,34.00},size={140.00,18.00},title="Max. Current"
	SetVariable setvarmaxcurrent,limits={0,0.01,0.001},value= root:VanDerPauw:K2600:nmax
	SetVariable setvarmincurrent,pos={382.00,58.00},size={140.00,18.00},disable=2,title="Min. Current"
	SetVariable setvarmincurrent,limits={-0.01,0.01,0.001},value= root:VanDerPauw:K2600:nmin
	SetVariable setvarpoints,pos={382.00,83.00},size={140.00,18.00},title="Nº of points"
	SetVariable setvarpoints,limits={-0.01,0.01,0.001},value= root:VanDerPauw:K2600:npoints
	Button buttonOneMeasure,pos={380.00,126.00},size={144.00,23.00},proc=ButtonProcVDP,title="OnlyOneMeasure"
	Button buttonOneMeasure,fSize=12,fColor=(32792,65535,1)
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:VanDerPauw:
	Edit/W=(28,328,224,497)/HOST=#  Resistance,Origin,V_r2
	ModifyTable format(Point)=1,width(Point)=34,format(Resistance)=3,width(Resistance)=60
	ModifyTable rgb(Resistance)=(65535,0,0),format(Origin)=3,width(Origin)=50,rgb(Origin)=(40000,10000,30000)
	ModifyTable format(V_r)=3,width(V_r)=50,rgb(V_r)=(10000,50000,20000)
	ModifyTable showParts=0xa
	ModifyTable statsArea=85
	SetDataFolder fldrSav0
	RenameWindow #,VDTable
	SetActiveSubwindow ##
	String fldrSav1= GetDataFolder(1)
	SetDataFolder root:VanDerPauw:
	Display/W=(25,27,360,306)/HOST=#  data[*][1][0] vs data[*][0][0]
	AppendToGraph data[*][0][1] vs data[*][1][1]
	AppendToGraph data[*][0][2] vs data[*][1][2]
	AppendToGraph data[*][0][3] vs data[*][1][3]
	AppendToGraph data[*][0][4] vs data[*][1][4]
	AppendToGraph data[*][0][5] vs data[*][1][5]
	AppendToGraph data[*][0][6] vs data[*][1][6]
	AppendToGraph data[*][0][7] vs data[*][1][7]
	AppendToGraph fit_data
	SetDataFolder fldrSav1
	ModifyGraph mode(data)=3,mode(data#1)=3,mode(data#2)=3,mode(data#3)=3,mode(data#4)=3
	ModifyGraph mode(data#5)=3,mode(data#6)=3,mode(data#7)=3
	ModifyGraph rgb(data#1)=(65535,65535,0),rgb(data#2)=(0,65535,65535),rgb(data#3)=(65535,0,52428)
	ModifyGraph rgb(data#4)=(39321,1,1),rgb(data#5)=(39321,39321,39321),rgb(data#6)=(0,65535,0)
	ModifyGraph rgb(data#7)=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph zero=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=-4
	Label left "Intensity (A)"
	Label bottom "Voltage (V)"
	RenameWindow #,VDPGraph
	SetActiveSubwindow ##
EndMacro


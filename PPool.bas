#include "PPool.bi"
#include "PPExtras.bas"
#include "PPhysics.bas"
#include "PTable.bas"
Screencontrol GET_DESKTOP_SIZE, DWidth, DHeight
if SWidth < 888 OR SHeight < 566 then
	SWidth = DWidth
	SHeight = DHeight
	
	applyScreenresSpecs
end if

'Define table settings based on screen resolution
if DWidth <= SWidth OR DHeight <= SHeight then
	screenres SWidth,SHeight,24,2,GFX_FULLSCREEN OR GFX_NO_FRAME OR GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
	Screencontrol SET_WINDOW_POS, 0, 0
elseif DWidth > SWidth AND DHeight > SHeight then
	screenres SWidth,SHeight,24,2,GFX_WINDOWED OR GFX_ALPHA_PRIMITIVES
else
	end -1
end if
width int(SWidth/8), int(SHeight/16)

GameCode = "default"

setmouse(,,0)
screenset 1,0
Table = ImageCreate(888,488)
Bload("gfx/table.bmp",Table)
Cursor = ImageCreate(40,40)
Bload("gfx/cursor.bmp",Cursor)
for PID as ubyte = 0 to 15
	BallPic(PID) = ImageCreate(19,19)
	Bload("gfx/"+GameCode+"/ball"+str(PID)+".bmp",BallPic(PID))
next PID
Background = ImageCreate(SWidth,SHeight)
Bload("gfx/back.bmp",Background)
ShotPic = ImageCreate(80,27)
Bload("gfx/shotclock.bmp",ShotPic)
FrameBig = ImageCreate(379,50)
Bload("gfx/scoreframeBig.bmp",FrameBig)
FrameSm = ImageCreate(254,50)
Bload("gfx/scoreframe.bmp",FrameSm)
AidMarkings = ImageCreate(SWidth,SHeight)

menu

sub menu
	dim as string HelpText
	Submenu = -1

	'Prep potential resolutions in advance
	dim as ubyte NumResolutions
	dim as uinteger ChoiceW(99), ChoiceH(99), smode
	
	smode = Screenlist(24)
	
	for ID as ubyte = 1 to 99
		ChoiceW(ID) = HiWord(smode)
		ChoiceH(ID) = LoWord(smode)
		smode = Screenlist
		if smode = 0 then
			NumResolutions = ID
			exit for
		end if
	
		if ChoiceW(ID) < 888 OR ChoiceH(ID) < 566 then
			ID -= 1
			continue for
		end if
	next
	
	do
		windowtitle TitleName+" 1.00"
		cls
		put(0,0),Background,pset
		gfxstring(TitleName,4,4,8,6,4,rgb(0,0,0))
		gfxstring(TitleName,6,4,8,6,4,rgb(0,0,0))
		gfxstring(TitleName,4,6,8,6,4,rgb(0,0,0))
		gfxstring(TitleName,6,6,8,6,4,rgb(0,0,0))
		gfxstring(TitleName,5,5,8,6,4,rgb(0,255,255))
		
		if Submenu = 0 then
			gfxstring("Start solo game",10,55,5,4,3,rgb(128,128,0))

			gfxstring("Practice",410,55,5,4,3,rgb(0,0,0))
			gfxstring("Nine Ball",410,95,5,4,3,rgb(0,0,0))
			gfxstring("Fifteen Ball",410,135,5,4,3,rgb(0,0,0))
			gfxstring("Eight Ball",410,175,5,4,3,rgb(0,0,0))
			gfxstring("Cribbage",410,215,5,4,3,rgb(0,0,0))
			gfxstring("Straight Pool",410,255,5,4,3,rgb(0,0,0))
		else
			gfxstring("Start solo game",10,55,5,4,3,rgb(0,0,0))
		end if
		if Submenu = 1 then
			gfxstring("Start party game",10,95,5,4,3,rgb(128,128,0))
			
			for GID as byte = 1 to GAME_MAX - 1
				gfxstring(GameName(GID),410,15+GID*40,5,4,3,rgb(0,0,0))
			next GID
		else
			gfxstring("Start party game",10,95,5,4,3,rgb(0,0,0))
		end if
		
		if QuickReset = 0 then
			gfxstring("Quick party play",10,135,5,4,3,rgb(128,128,128))
		else
			gfxstring("Quick party play",10,135,5,4,3,rgb(0,0,0))
		end if
		
		if Submenu = 8 then
			dim as string AidsLevels(0 to 4) => {"None", "Low", "Medium", "High", "V-High"}
			
			gfxstring("Engine Options",10,415,5,4,3,rgb(128,128,0))
			gfxstring("Sound Volume: "+str(SoundVolume)+"%",410,55,5,4,3,rgb(0,0,0))
			
			for BID as byte = 0 to 10
				if SoundVolume >= BID*10 then
					line(720+15*BID,55)-(729+15*BID,79),rgb(0,0,0),bf
				else
					line(720+15*BID,55)-(729+15*BID,79),rgb(0,0,0),b
				end if

				if MaxShot >= (BID+1)*15 OR BID = 0 then
					line(720+15*BID,95)-(729+15*BID,119),rgb(0,0,0),bf
				else
					line(720+15*BID,95)-(729+15*BID,119),rgb(0,0,0),b
				end if
			next BID
			
			if MaxShot = 0 then
				gfxstring("Shot Clock (off)",410,95,5,4,3,rgb(0,0,0))
			else
				gfxstring("Shot Clock ("+getTimeStr(MaxShot)+")",410,95,5,4,3,rgb(128,128,0))
			end if
			
			gfxstring("Aiming Aids: "+AidsLevels(PhysicsAids),410,135,5,4,3,rgb(0,0,0))
			
			for AID as byte = 0 to 4
				if PhysicsAids >= AID then
					line(720+30*AID,135)-(744+30*AID,159),rgb(0,0,0),bf
				else
					line(720+30*AID,135)-(744+30*AID,159),rgb(0,0,0),b
				end if
			next AID
			
			if NoSnapping = 0 then
				gfxstring("Snap to Rack: Enabled",410,175,5,4,3,rgb(0,0,0))
			else
				gfxstring("Snap to Rack: Disabled",410,175,5,4,3,rgb(128,128,0))
			end if
			if PhysicsDisp = 0 then
				gfxstring("Physics Details: Normal",410,215,5,4,3,rgb(0,0,0))
			else
				gfxstring("Physics Details: Rich",410,215,5,4,3,rgb(128,128,0))
			end if
		else
			gfxstring("Engine Options",10,415,5,4,3,rgb(0,0,0))
		end if
		
		if Submenu = 9 then
			dim as string ResName, ResRatio
			dim as string StringW, StringH
			
			gfxstring("Screen Resolution",10,455,5,4,3,rgb(128,128,0))

			for GID as ubyte = 1 to NumResolutions
				StringW = str(ChoiceW(GID))
				StringH = str(ChoiceH(GID))
				ResName = space(4-len(StringW))+StringW+"x"+space(4-len(StringH))+StringH
				ResRatio = dispThousandths(ChoiceW(GID)/ChoiceH(GID))
				
				if ChoiceW(GID) = SWidth AND ChoiceH(GID) = SHeight then
					gfxstring(ResName+" ("+ResRatio+")",410,15+GID*40,5,4,3,rgb(128,128,128))
				else
					gfxstring(ResName+" ("+ResRatio+")",410,15+GID*40,5,4,3,rgb(0,0,0))
					with Mouse(0)
						if .X >= 400 AND .Y >= 10+GID*40 AND .Y < 44+GID*40 then
							drawBox(400,10+GID*40,SWidth-1,44+GID*40)
							if .Buttons > 0 AND .HoldPress = 0 then
								.HoldPress = 1
								SWidth = valint(StringW)
								SHeight = valint(StringH)
								ImageDestroy(Background)
								ImageDestroy(AidMarkings)
								if DWidth = SWidth OR DHeight = SHeight then
									screenres SWidth,SHeight,24,2,GFX_FULLSCREEN OR GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
								elseif DWidth > SWidth AND DHeight > SHeight then
									screenres SWidth,SHeight,24,2,GFX_WINDOWED OR GFX_ALPHA_PRIMITIVES
								else
									end -1
								end if
								setmouse(,,0)
								screenset 1,0
								Background = ImageCreate(SWidth,SHeight)
								AidMarkings = ImageCreate(SWidth,SHeight)
								Bload("gfx/back.bmp",Background)
								applyScreenresSpecs
								width int(SWidth/8), int(SHeight/16)
							end if
						end if
					end with
				end if
			next GID
		else
			gfxstring("Screen Resolution",10,455,5,4,3,rgb(0,0,0))
		end if
		
		gfxstring("Exit",10,495,5,4,3,rgb(0,0,0))
		if Submenu <> 9 then
			gfxstring(HelpText,5,545,3,2,2,rgb(0,0,0))
		end if
		HelpText = "Copyright (C) 2026 Paul Ruediger"
		
		with Mouse(0)
			.ErrNum = getmouse(.BX,.BY,0,.Buttons)
			if .Loaded >= 0 then
				.Loaded = -1
			end if
			
			if .ErrNum = 0 then
				if .X < 400 then
					if .Y >= 50 AND .Y < 85 then
						HelpText = "Start a single player game. You can practice physics, or go for a High Score in a supported game."
						drawBox(0,50,399,84)
						if .Buttons > 0 AND .HoldPress = 0 then
							Submenu = iif(Submenu = 0,-1,0)
							.HoldPress = 1
						end if
					elseif .Y >= 90 AND .Y < 125 then
						HelpText = "Start a party game using one of the pre-designed rulesets. 2-3 players, unless specified otherwise."
						drawBox(0,90,399,124)
						if .Buttons > 0 AND .HoldPress = 0 then
							Submenu = iif(Submenu = 1,-1,1)
							.HoldPress = 1
						end if
					elseif .Y >= 130 AND .Y < 165 AND QuickReset > 0 then
						HelpText = "Quickly start a party game using the last chosen rule set."
						drawBox(0,130,399,164)
						if .Buttons > 0 AND .HoldPress = 0 then
							newRack(QuickReset)
							playTable
							.HoldPress = 1
						end if
					elseif .Y >= 410 AND .Y < 445 then
						HelpText = "Fine tune various engine settings"
						drawBox(0,410,399,444)
						if .Buttons > 0 AND .HoldPress = 0 then
							Submenu = iif(Submenu = 8,-1,8)
							.HoldPress = 1
						end if
					elseif .Y >= 450 AND .Y < 485 then
						HelpText = "Change the resolution of the engine. Automatically centers the table"
						drawBox(0,450,399,484)
						if .Buttons > 0 AND .HoldPress = 0 then
							Submenu = iif(Submenu = 9,-1,9)
							.HoldPress = 1
						end if
					elseif .Y >= 490 AND .Y < 525 then
						HelpText = "Exits the engine..."
						drawBox(0,490,399,524)
						if .Buttons > 0 then
							exit do
						end if
					end if
				end if
		
				if .X >= 400 then
					if Submenu = 0 then
						if .Y >= 50 AND .Y < 85 then
							HelpText = "Practice the physics by yourself. You can place billiard balls however way you like."
							drawBox(400,50,SWidth-1,84)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_TRAINING)
								playTable
							end if
						elseif .Y >= 90 AND .Y < 125 then
							HelpText = "Pocket the 9-ball in as few innings as possible. Points are lost for each inning (-1) and foul (-3)."
							drawBox(400,90,SWidth-1,124)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_9BALL_SOLO)
								playTable
							end if
						elseif .Y >= 130 AND .Y < 165 then
							HelpText = "Pocket the 15 object balls in as few innings as possible. Points are lost for each inning (-1) and foul (-3)."
							drawBox(400,130,SWidth-1,164)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_15BALL_SOLO)
								playTable
							end if
						elseif .Y >= 170 AND .Y < 205 then
							HelpText = "Pocket one suit + the 8-ball in as few innings as possible. Points are lost for each inning, foul, and opposing ball pocketed."
							drawBox(400,170,SWidth-1,204)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_8BALL_SOLO)
								playTable
							end if
						elseif .Y >= 210 AND .Y < 245 then
							HelpText = "Secure the 8 cribbages in as few innings as possible. Points are lost for each inning (-1) and foul (-3)."
							drawBox(400,210,SWidth-1,244)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_CRIBBAGE_SOLO)
								playTable
							end if
						elseif .Y >= 250 AND .Y < 285 then
							HelpText = "Score as many balls as you can in a single streak in this solo variant of Straight Pool."
							drawBox(400,250,SWidth-1,284)
							if .Buttons > 0 AND .HoldPress = 0 then
								newRack(GAME_STRAIGHT_POOL_SOLO)
								playTable
							end if
						end if
					elseif Submenu = 1 then
						for SID as ubyte = 1 to GAME_MAX - 1
							if .X >= 400 AND .Y >= SID * 40 + 10 AND .Y < SID * 40 + 45 then
								select case GameName(SID)
									case "Eight Ball"
										HelpText = "2-player game. Can you pocket your suit first, and then the titular money ball?"
									case "Six Ball", "Nine Ball", "Ten Ball"
										HelpText = "Think you can sneak in the money ball, while still hitting the lowest ball first?"
									case "Fifteen Ball"
										HelpText = "Score points by pocketing balls on legal shots. First to 61 points wins."
									case "Rotation"
										HelpText = "Score points while hitting the lowset ball in play. First to 61 points wins."
									case "Seven Ball"
										HelpText = "2-player game. Pocket the money ball in your designated long side, while still hitting the lowest ball first."
									case "One Pocket"
										HelpText = "2-player game. Score by pocketing balls in your designated pocket, on legal shots. First to 8 object balls wins."
									case "Cutthroat"
										HelpText = "3-player game. Pocket all of an opponent's object balls to eliminate them. Last player standing wins."
									case "Cribbage"
										HelpText = "2-player game. Pocket balls that add to 15 to score ''cribbage''s. First to 5 cribbages wins."
									case "Straight Pool"
										HelpText = "2-player game. Pocket balls to score. Multiple racks are used. First to 100 object balls wins."
								end select
								
								drawBox(400,(SID)*40+10,SWidth-1,(SID)*40+44)
								if .Buttons > 0 AND .HoldPress = 0 then
									newRack(SID)
									playTable
									QuickReset = SID
								end if
							end if
						next SID
					elseif Submenu = 8 then
						if .Y >= 50 AND .Y < 85 then
							HelpText = "Determines how loud to play the sound effects"
							
							if .Buttons > 0 AND .HoldPress = 0 AND .X >= 710 AND .X < 900 then
								SoundVolume = max(min(int((.X-718)/150*10),10),0) *10
								
								playClip(SFX_TURN)
								.HoldPress = 1
							end if
						elseif .Y >= 90 AND .Y < 125 then
							HelpText = "Limits the time a player may take to do each shot, adjusted by the foul combo. No effect in practice play"
							
							if .Buttons > 0 AND .HoldPress = 0 AND .X >= 710 AND .X < 900 then
								MaxShot = (1 + max(min(int((.X-718)/150*10),10),0)) *15
								if MaxShot > 150 then
									MaxShot = 180
								elseif MaxShot < 30 then
									MaxShot = 0
								end if
								
								.HoldPress = 1
							end if
						elseif .Y >= 130 AND .Y < 165 then
							HelpText = "Determines how much of an aid to give to the player when aiming their cue ball."
							
							if .Buttons > 0 AND .HoldPress = 0 AND .X >= 710 AND .X < 900 then
								PhysicsAids = max(min(int((.X-718)/150*5),4),0)
								
								.HoldPress = 1
							end if
						elseif .Y >= 170 AND .Y < 205 then
							HelpText = "Determines whether object balls should snap to the points of a rack. Only effective in practice play"
							drawBox(400,170,SWidth-1,204)
							if .Buttons > 0 AND .HoldPress = 0 then
								NoSnapping = 1 - NoSnapping
								.HoldPress = 1
							end if
						elseif .Y >= 210 AND .Y < 245 then
							HelpText = "Determines whether additional physics details should be displayed. Only effective in practice play"
							drawBox(400,210,SWidth-1,244)
							if .Buttons > 0 AND .HoldPress = 0 then
								PhysicsDisp = 1 - PhysicsDisp
								.HoldPress = 1
							end if
						end if
					end if
				end if
			end if
			
			dispMouse
			if .Buttons = 0 AND .HoldPress > 0 then
				.HoldPress = 0
			end if
		end with
		screencopy
		sleep 15
		InType = inkey
	loop until InType = EscKey OR InType = XBox
end sub

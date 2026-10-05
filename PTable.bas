sub playTable
	SelectedBall = -1
	Ticker = 128
	FramesRecorded = 0
	TickUpdate = timer + 1
	FrameTime = timer
	SelectedBall = -1
	Mouse(0).HoldPress = 1

	loadScores("solo"+str(UseRuleset))

	do
		FrameTime += 1/FrameRate
		if timer > TickUpdate then
			TickUpdate += 1
	
			ActualFPS = FramesRecorded
			FramesRecorded = 0
		end if
		FramesRecorded += 1
		put(0,0),Background,pset
		with Mouse(0)
			.ErrNum = getmouse(.BX,.BY,0,.Buttons)
	
			if .ErrNum <> 0 then
				ExertForce = 0
			end if
			if .Buttons = 0 AND .HoldPress <> 0 then
				.HoldPress = 0
			end if
		end with
	
		select case NumPlayers
			case 1
				put(5,5),FrameBig,trans
		
				with PlayerSlot(1)
					for BID as ubyte = 1 to 15
						if .Pocketed(BID) > 0 then
							put(10+(BID-1)*25,32),BallPic(.Pocketed(BID)),trans
						end if
					next BID
					
					if .MoneyScore >= 0 then
						gfxstring("Sc: "+string(4-len(str(.MoneyScore)),"0")+str(.MoneyScore),11,8,4,2,2,rgb(255,255,255))
					else
						gfxstring("Sc: -"+string(4-len(str(.MoneyScore)),"0")+str(abs(.MoneyScore)),11,8,4,2,2,rgb(255,255,255))
					end if
					
					if .MoneyScore > SessionBest AND Stationary >= 0 then
						SessionBest = .MoneyScore
					end if
					
					if UseRuleset = GAME_STRAIGHT_POOL then
						gfxstring("Sess: "+string(4-len(str(SessionBest)),"0")+str(SessionBest),131,8,4,2,2,rgb(255,255,255))
						
						if .MoneyScore > MachineBest AND Stationary >= 0 then
							MachineBest = .MoneyScore
							saveScores("solo"+str(UseRuleset))
						end if
					end if
				end with

				if UseRuleset <> GAME_TRAINING then
					gfxstring("High: "+string(4-len(str(MachineBest)),"0")+str(MachineBest),266,8,4,2,2,rgb(255,255,255))
					
					shotClockDisp(SWidth-85)
				end if
			case 2
				'Player 1
				playerFrameSm(5,1)
				shotClockDisp(SWidth/2-40,15)
				'Player 2
				playerFrameSm(SWidth-258,2)
				
			case 3
				'Player 1
				playerFrameSm(5,1)
				if Player = 1 then
					shotClockDisp(179,28)
				end if
				
				'Player 2
				playerFrameSm(SWidth/2-126,2)
				if Player = 2 then
					shotClockDisp(SWidth/2+48,28)
				end if

				'Player 3
				playerFrameSm(SWidth-258,3)
				if Player = 3 then
					shotClockDisp(SWidth-84,28)
				end if

		end select
		
		renderTable
		
		if SelectedBall >= 0 AND SelectedBall < 16 AND Unloading = 0 AND UseRuleset = GAME_TRAINING then
			with Ball(SelectedBall)
				dim as single CalcSpeedIns, CalcSpeedMs, CalcAngle
				dim as string SpeedStr, CalcMomentum, CalcEnergy, AngleStr
				CalcSpeedIns = .Speed/8^2
				CalcSpeedMs = CalcSpeedIns * 0.0254
				CalcAngle = remainder(radtodeg(.Angle) + 1800,360)
				if CalcSpeedIns < 1e-4 then
					CalcSpeedIns = 0
				end if
				if CalcSpeedMs < 1e-4 then
					CalcSpeedMs = 0
				end if
				if .Momentum < 1e-4 then
					.Momentum = 0
				end if
				if .Energy < 1e-4 then
					.Energy = 0
				end if
				if PhysicsDisp then
					SpeedStr = dispThousandths(CalcSpeedMs)
				else
					SpeedStr = dispThousandths(CalcSpeedIns)
				end if
				AngleStr = dispThousandths(CalcAngle)

				CalcMomentum = dispThousandths(.Momentum)
				CalcEnergy = dispThousandths(.Energy)

				trainingInfo(430,5,.Namee)

				if .Alive then
					gfxstring("("+str(int(.X+0.5))+","+str(int(.Y+0.5))+")",430,23,3,3,2,rgb(128,128,0))

					if PhysicsDisp then
						trainingInfo(575,5,"Speed: "+str(SpeedStr)+" m/s",7)
					else
						trainingInfo(575,5,"Speed: "+str(SpeedStr)+" in/s",7)
					end if
					trainingInfo(575,23,"Angle: "+str(AngleStr)+" deg",7)

					if PhysicsDisp then
						trainingInfo(800,5,"Momentum: "+CalcMomentum+" Ns",10)
						trainingInfo(800,23,"Energy: "+CalcEnergy+" J",8)
					end if
				else
					gfxstring("Pocketed",435,23,3,3,2,rgb(128,128,128))
				end if
			end with
		end if

		if ShotClock <= -5 * FrameRate AND MaxShot > 0 AND UseRuleset <> GAME_TRAINING AND Stationary = 0 then
			'Going five seconds or more over without shooting will forfeit the inning
			Stationary = 2
			ProperHit = -1
			playClip(SFX_FOUL)
		end if
	
		if Stationary > 0 then
			if PlayState = STATE_BREAK AND (InitialHits < InitialQuota OR InitialCue < CueRailReq) AND UseRuleset = GAME_1POCKET then
				PlayState = STATE_NORMAL
				ProperHit = -1
				playClip(SFX_FOUL)
			end if

			if ShotClock <= 0 AND MaxShot > 0 AND UseRuleset <> GAME_TRAINING then
				'Running out the shot clock constitutes a foul
				ProperHit = -1
			end if
			
			if ProperHit >= 3 AND UseRuleset = GAME_CUTTHROAT AND PlayerSlot(Player).CasualScore <= 0 then
				'If the shooting player pocketed their last object ball in Cutthroat, end their turn anyway.
				ProperHit = 2
			end if
				
			if PlayState = STATE_BREAK AND (InitialHits < InitialQuota OR InitialCue < CueRailReq) AND NumPlayers > 1 then
				with PlayerSlot(Player)
					.FoulCombo += 1
					if UseRuleset = GAME_STRAIGHT_POOL then
						.MoneyScore -= 1
					end if
				end with
				PlayState = STATE_ILLEGAL_BREAK
			elseif (ProperHit <= 1 OR MustScoreCribbage > 0) AND Player > 0 then
				PlayState = STATE_FOULED
				if ProperHit >= 0 then
					playClip(SFX_FOUL)
				end if
				PlayerSlot(Player).FoulCombo += 1
				Fouled = 1
				
				if UseRuleset = GAME_8BALL then
					if NumPlayers < 2 then
						PlayState = STATE_NORMAL
					end if
					
					if GameOver > 0 then
						'Pocketing the eight ball on a foul shot results in opponent winning
						Victor = 3 - Player
						PlayerSlot(Player).MoneyScore -= 200
					end if
					PlayerSlot(Player).MoneyScore -= 3
				elseif UseRuleset = GAME_9BALL OR UseRuleset = GAME_10BALL OR UseRuleset = GAME_6BALL then
					if NumPlayers < 2 then
						'Ball-in-hands are not available when playing a compatible game solo, EXCEPT when scratching.
						PlayState = STATE_NORMAL
						'Also deduct $3 on a foul shot.
						PlayerSlot(Player).MoneyScore -= 3
						RestrictedPlace = 1
						Mouse(0).Loaded = -1
						
						if GameOver = 1 then
							'Spot the money ball if it is pocketed in a fouled shot
							GameOver = 0
							spotBall(MoneyBall)
							
							with PlayerSlot(1)
								.MoneyScore -= 100
								.CasualScore -= 1
							end with
						end if
						
					elseif PlayerSlot(Player).FoulCombo >= 3 AND NumPlayers = 2 then
						'Instantly end the game if someone combos three or more fouls in a single streak
						GameOver = 3
						Victor = 3 - Player
					elseif GameOver = 1 then
						'Spot the money ball if it is pocketed in a fouled shot
						GameOver = 0
						spotBall(MoneyBall)
					end if
				elseif UseRuleset = GAME_15BALL then
					dim as byte FirstBall
					/'
					 ' A foul in Fifteen Ball reverts score, then deducts 3 points.
					 ' If scratched, then ball-in-hand. Ohterwise, no ball-in-hand
					 '/
					PlayState = STATE_NORMAL
					Mouse(0).Loaded = -1
					with PlayerSlot(Player)
						if .CasualScore > .PrevCasual then
							for Diff as short = .CasualScore to .PrevCasual + 1 step -1
								.MoneyScore -= .Pocketed(.CasualScore)
								spotBall(.Pocketed(.CasualScore))
								if Diff > 0 then
									.Pocketed(Diff) = 0
								end if
								.CasualScore -= 1
							next Diff
						end if
						.CasualScore = .PrevCasual
					
						.MoneyScore -= 3
					end with
				elseif UseRuleset = GAME_ROTATION then
					dim as byte FirstBall
					/'
					 ' A foul in Rotation Ball reverts score. If scratched, then ball-in-hand behind head string.
					 '
					 ' Assuming this foul did not eliminate a player, the incoming player has the option to
					 ' take their inning, *or* force the previous player to shoot again.
					 '/
					RestrictedPlace = 1
					Mouse(0).Loaded = -1
					with PlayerSlot(Player)
						if .FoulCombo < 3 then 
							PlayState = STATE_DECISION
						else
							PlayState = STATE_NORMAL
						end if
						
						if .CasualScore > .PrevCasual then
							for Diff as short = .CasualScore to .PrevCasual + 1 step -1
								.MoneyScore -= .Pocketed(.CasualScore)
								spotBall(.Pocketed(.CasualScore))
								if Diff > 0 then
									.Pocketed(Diff) = 0
								end if
								.CasualScore -= 1
							next Diff
						end if
						.CasualScore = .PrevCasual
					end with
				elseif UseRuleset = GAME_7BALL then
					if GameOver > 0 OR PlayerSlot(Player).FoulCombo >= 3 then
						/'
						 ' Pocketing the seven ball on a foul shot results in opponent winning,
						 ' even if it otherwise lands in the correct side.
						 '/
						Victor = 3 - Player
					end if
					
				elseif UseRuleset = GAME_1POCKET then
					dim as byte FirstBall
					/'
					 ' A foul in One Pocket reverts score, then deducts a point.
					 ' If scratched, then ball-in-hand behind head string.
					 ' Ohterwise, no ball-in-hand
					 '/
					PlayState = STATE_NORMAL
					RestrictedPlace = 1
					Mouse(0).Loaded = -1
					with PlayerSlot(Player)
						if .CasualScore > .PrevCasual then
							for Diff as short = .CasualScore to .PrevCasual + 1 step -1
								spotBall(.Pocketed(.CasualScore))
								if Diff > 0 then
									.Pocketed(Diff) = 0
								end if
								.CasualScore -= 1
							next Diff
						end if
						.CasualScore = .PrevCasual
						
						if .CasualScore > 0 then
							FirstBall = .Pocketed(1) 
							for BID as byte = 1 to 14
								.Pocketed(BID) = .Pocketed(BID+1)
							next BID
							.Pocketed(.CasualScore) = 0
							.CasualScore -= 1
							spotBall(FirstBall)
						else
							.CasualScore -= 1
						end if
					end with
					
					if PlayerSlot(Player).FoulCombo >= 3 then
						GameOver = 3
						Victor = 3 - Player
					end if
				elseif UseRuleset = GAME_CUTTHROAT then
					'Fouls in Cutthroat cause illegally pocketed balls belonging to opponents to be spotted
					for PID as byte = 1 to 3
						with PlayerSlot(PID)
							if PID <> Player AND .GroupAssigned > 0 then
								while .CasualScore < .PrevCasual
									spotForCutPlayer(PID)
								wend
							end if
						end with
					next PID
					Mouse(0).Loaded = -1

					if Ball(0).Alive = 0 then
						'Additionally; if scratched, then the two opponents get an object ball spotted back on the field.
						for PID as byte = 1 to 3
							if PID <> Player AND PlayerSlot(PID).GroupAssigned > 0 AND PlayerSlot(PID).CasualScore < 5 then
								spotForCutPlayer(PID)
							elseif PID <> Player AND ObjsNPlay < 15 then
								if PlayerSlot(Player).GroupAssigned = 1 then
									dim as byte RandomBall
									do
										RandomBall = irandom(6,15)
									loop until Ball(RandomBall).Alive = 0
									spotBall(RandomBall)
								elseif PlayerSlot(Player).GroupAssigned = 2 then
									dim as byte RandomBall
									do
										RandomBall = irandom(1,10)
										if RandomBall > 5 then
											RandomBall += 5
										end if
									loop until Ball(RandomBall).Alive = 0
									spotBall(RandomBall)
								elseif PlayerSlot(Player).GroupAssigned = 3 then
									dim as byte RandomBall
									do
										RandomBall = irandom(1,10)
									loop until Ball(RandomBall).Alive = 0
									spotBall(RandomBall)
								end if
							end if
						next PID
					end if
				elseif UseRuleset = GAME_CRIBBAGE then
					removeUnpairedBalls(PlayerSlot(Player))
					if NumPlayers > 1 AND Ball(0).Alive > 0 then
						PlayState = STATE_DECISION
					else
						PlayState = STATE_NORMAL
						RestrictedPlace = 1
					end if
					Mouse(0).Loaded = -1
					
					with PlayerSlot(Player)
						if NumPlayers < 2 then
							.MoneyScore -= 3
						end if
						
						if GameOver = 1 then
							'Spot the 15-ball if it is pocketed in a fouled shot
							GameOver = 0
							spotBall(15)
							
							.MoneyScore -= 1 * iif(NumPlayers > 1, 1, 100)
							.CasualScore -= 1
						end if
					
						if .FoulCombo >= 3 then
							'Instantly end the game if someone combos three or more fouls in a single streak
							GameOver = 3
							Victor = 3 - Player
						end if
					end with
				elseif UseRuleset = GAME_STRAIGHT_POOL then
					'Negate points gained and also subtract a point
					with PlayerSlot(Player)
						.MoneyScore -= (.CasualScore - .PrevCasual) + 1 

						if .CasualScore > .PrevCasual then
							for Diff as short = .CasualScore to .PrevCasual + 1 step -1
								spotBall(.Pocketed(.CasualScore))
								if Diff > 0 then
									.Pocketed(Diff) = 0
								end if
								.CasualScore -= 1
							next Diff
						end if
						
						'Combo of 3 fouls subtract 15 more points, but resets the combo
						if .FoulCombo >= 3 then
							.MoneyScore -= 15
							.FoulCombo = 0
						end if	
					end with
				end if

				dim as byte PlrsAlive = findAlivePlayers
				if ((PlrsAlive = 1 OR PlrsAlive = 2 OR PlrsAlive = 4) AND NumPlayers > 1) OR _
					(PlrsAlive = 0 AND NumPlayers < 2) then
					/'
					 ' Only one player left. End the game.
					 ' (Also end the game if playing solo and the foul combo was achieved)
					 '/
					GameOver = 3
					for PID as byte = 1 to NumPlayers
						with PlayerSlot(PID)
							if .FoulCombo < 3 then
								Victor = PID
								exit for
							end if
						end with
					next PID
				end if

				Mouse(0).Loaded = -1
			else
				with PlayerSlot(Player) 
					.FoulCombo = 0
					
					if .CasualScore >= 8 AND UseRuleset = GAME_1POCKET then
						'Capture the majority of the balls to win
						GameOver = 3
						Victor = Player
					elseif .MoneyScore >= 61 AND UseRuleset = GAME_15BALL AND NumPlayers > 1 then
						'Capture 61 points to win
						GameOver = 3
						Victor = Player
					elseif .MoneyScore >= 5 AND UseRuleset = GAME_CRIBBAGE AND NumPlayers > 1 then
						'Capture 5 cribbages to win
						GameOver = 3
						Victor = Player
					elseif .MoneyScore >= 100 AND UseRuleset = GAME_STRAIGHT_POOL AND NumPlayers > 1 then
						'Capture 100 balls to win
						GameOver = 3
						Victor = Player
					end if
				end with
				
				if findRotationRunaway > 0 AND UseRuleset = GAME_ROTATION AND NumPlayers > 1 then
					'Award the win to the player who has established a strong enough lead to be no longer conquerable by opposition.
					GameOver = 3
					Victor = findRotationRunaway
				elseif ObjsNPlay = 0 AND (UseRuleset = GAME_15BALL OR UseRuleset = GAME_ROTATION OR UseRuleset = GAME_CRIBBAGE) then
					'All object balls exhausted. End the game anyway.
					GameOver = 3
					if PlayerSlot(1).MoneyScore > max(PlayerSlot(2).MoneyScore, PlayerSlot(3).MoneyScore) then
						Victor = 1
					elseif PlayerSlot(2).MoneyScore > max(PlayerSlot(1).MoneyScore, PlayerSlot(3).MoneyScore) then
						Victor = 2
					elseif PlayerSlot(3).MoneyScore > max(PlayerSlot(1).MoneyScore, PlayerSlot(2).MoneyScore) then
						Victor = 3
					else
						Victor = Player
					end if
				elseif UseRuleset = GAME_CUTTHROAT then
					dim as byte PlayersLeft = findAlivePlayers
					
					'Check Cutthroat-unique victory conditions
					if PlayersLeft = 0 then
						'All balls pocketed. Spot one ball for each player
						for PID as byte = 1 to 3
							spotForCutPlayer(PID)
						next PID
					elseif PlayersLeft = 1 OR PlayersLeft = 2 OR PlayersLeft = 4 then
						'Only one player left. End the game
						GameOver = 3
						for PID as byte = 1 to 3
							with PlayerSlot(PID)
								if .CasualScore > 0 AND .GroupAssigned > 0 then
									Victor = PID
									exit for
								end if
							end with
						next PID
					end if
				elseif UseRuleset = GAME_STRAIGHT_POOL then
					if ObjsNPlay <= 1 then
						newStraightRack
					end if
				end if 
				
				PlayState = STATE_NORMAL
			end if
	
			if GameOver >= 1 then
				if Victor = 0 then
					Victor = Player
				end if
				
				GameOver = 3
				PlayState = STATE_OVER
				
				if NumPlayers = 1 then
					if UseRuleset = GAME_9BALL then
						PlayerSlot(1).MoneyScore += max(100 * (9 - PlayerSlot(1).CasualScore), 0) 
					elseif UseRuleset = GAME_10BALL then
						PlayerSlot(1).MoneyScore += max(100 * (10 - PlayerSlot(1).CasualScore), 0) 
					end if
				end if
			end if
	
			if UseRuleset = GAME_8BALL then
				'Assign the suits, except if there is a foul involved
				if PlayState = STATE_FOULED then
					Claimed(1) = 0
					Claimed(2) = 0
				end if

				if Claimed(1) > Claimed(2) then
					assign8Bsuit(3 - Player)
				elseif Claimed(2) > Claimed(1) then
					assign8Bsuit(Player)
				end if
				Claimed(1) = 0
				Claimed(2) = 0
				
			elseif UseRuleset = GAME_CUTTHROAT then
				if PlayState = STATE_FOULED then
					Claimed(1) = 0
					Claimed(2) = 0
					Claimed(3) = 0
				end if
				
				if PlayerSlot(Player).GroupAssigned <= 0 then
					if Claimed(1) > Claimed(3) AND Claimed(2) > Claimed(3) then
						assignCutSuit(Player,3)
					elseif Claimed(1) > Claimed(2) AND Claimed(3) > Claimed(2) then
						assignCutSuit(Player,2)
					elseif Claimed(2) > Claimed(1) AND Claimed(3) > Claimed(1) then
						assignCutSuit(Player,1)
					elseif Claimed(1) > 0 AND Claimed(2) = Claimed(3) then
						assignCutSuit(Player,-1)
						Claimed(1) = 9
					elseif Claimed(2) > 0 AND Claimed(1) = Claimed(3) then
						assignCutSuit(Player,-2)
						Claimed(2) = 9
					elseif Claimed(3) > 0 AND Claimed(1) = Claimed(2) then
						assignCutSuit(Player,-3)
						Claimed(3) = 9
					end if
				end if
				
				if ProperHit < 3 then
					Claimed(1) = 0
					Claimed(2) = 0
					Claimed(3) = 0
				end if
			end if
			
			spotObjectBalls

			for PID as byte = 1 to NumPlayers
				with PlayerSlot(PID)
					.PrevCasual = .CasualScore
				end with
			next PID
	
			if NumPlayers > 1 then
				if ProperHit < 3 OR Fouled > 0 then
					Player += 1
					if Player > NumPlayers then Player = 1
					
					if UseRuleset = GAME_CUTTHROAT then 
						with PlayerSlot(Player)
							if .GroupAssigned <= 0 then
								Claimed(abs(.GroupAssigned)) = 9
								for PID as byte = 1 to 3
									if PID <> Player AND PlayerSlot(PID).GroupAssigned > 0 then
										Claimed(PlayerSlot(PID).GroupAssigned) = 9
									end if
								next PID
							elseif .CasualScore <= 0 then
								'Skip players that have lost all of their object balls
								Player += 1
								if Player > NumPlayers then Player = 1
							end if
						end with
					elseif UseRuleset = GAME_9BALL OR UseRuleset = GAME_10BALL OR UseRuleset = GAME_6BALL OR UseRuleset = GAME_15BALL OR UseRuleset = GAME_ROTATION then 
						with PlayerSlot(Player)
							if .FoulCombo >= 3 then
								'Skip players that have been disqualified by the foul combo
								Player += 1
								if Player > NumPlayers then Player = 1
							end if
						end with
					end if
				elseif UseRuleset = GAME_7BALL AND TopChosen = 0 then
					RivalInterrupt = 1
				end if
			elseif UseRuleset = GAME_9BALL OR UseRuleset = GAME_10BALL OR UseRuleset = GAME_6BALL OR UseRuleset = GAME_15BALL OR UseRuleset = GAME_8BALL OR UseRuleset = GAME_CRIBBAGE then
				if ProperHit < 3 OR Fouled > 0 then
					PlayerSlot(1).MoneyScore -= 1
				end if
			elseif UseRuleset = GAME_STRAIGHT_POOL then
				if ProperHit < 3 then
					PlayerSlot(1).MoneyScore = 0 
				end if
			end if
			
			with PlayerSlot(Player)
				'Reset the shot clock, and adjust the cap based on the foul combo
				ShotClock = max(MaxShot*FrameRate*(10-.FoulCombo)/10, 15*FrameRate)
			end with

			CalledPocket = 0
			ProperHit = 0
			Fouled = 0
			Stationary = 0
		end if
		
		if Stationary = 0 then
			if TurnDing < 1 then
				if Ball(0).Alive = 0 then Mouse(0).Loaded = 0
				MustScoreCribbage = checkUnpairedBalls(PlayerSlot(Player))
				
				DebugCapture = 0
				
				playClip(SFX_TURN)
				TurnDing = 1
			end if
		else
			TurnDing = min(TurnDing, 0)
		end if

		dispMouse
		
		color rgb(255,0,255),rgb(0,0,0)
		if Mouse(0).Buttons = 0 AND Unloading > 0 then
			Unloading = 0
		elseif PlayState = STATE_OVER then
			if NumPlayers > 1 then
				DispString = "Game Over! Player "+str(Victor)+" wins! Press ESC to return to the main menu."
			else
				DispString = "Game Over! Press ESC to return to the main menu."
				
				if PlayerSlot(1).MoneyScore > MachineBest AND PlayerSlot(1).FoulCombo < 3 then
					MachineBest = PlayerSlot(1).MoneyScore
					saveScores("solo"+str(UseRuleset))
				end if
			end if
		elseif Stationary = 0 AND Mouse(0).Loaded >= 0 AND Mouse(0).Buttons > 0 AND Mouse(0).HoldPress = 0 AND _
			PlayState <> STATE_ILLEGAL_BREAK AND PlayState <> STATE_DECISION then
			
			dim as ubyte Illegal
			for BID as ubyte = 0 to 15
				with Ball(BID)
					if BID <> Mouse(0).Loaded then
						if .Alive = 1 AND sqr((Mouse(0).X - .X)^2 + (Mouse(0).Y - .Y)^2) < Diameter then
							Illegal = 1
							exit for
						end if
					end if
				end with
			next BID
	
			with Ball(Mouse(0).Loaded)
				.X = Mouse(0).X
				.Y = Mouse(0).Y
				.Angle = 0
				if pocketDetection(Ball(Mouse(0).Loaded)) then
					Illegal = 1
				end if
			end with
	
			if Illegal = 0 AND Mouse(0).X > LeftBorder AND Mouse(0).X < RightBorder AND Mouse(0).Y > TopBorder AND _
				Mouse(0).Y < BottomBorder AND (Mouse(0).X > HeadString OR (PlayState <> STATE_BREAK AND RestrictedPlace = 0)) then
				Unloading = 1
				if RestrictedPlace then
					if UseRuleset = GAME_ROTATION then
						MustCrossString = 1
					end if
					RestrictedPlace = 0
				end if
				if PlayState <> STATE_BREAK then
					PlayState = STATE_RECOVERED
				end if
				with Ball(Mouse(0).Loaded)
					.Speed = 0
					.Alive = 1
				end with
				Mouse(0).Loaded = -1
			end if
		elseif Mouse(0).Buttons > 0 AND Stationary = 0 AND Mouse(0).ErrNum = 0 AND _
			Unloading = 0 AND Ball(0).Alive = 1 AND PlayState <> STATE_FOULED AND _
			PlayState <> STATE_ILLEGAL_BREAK AND PlayState <> STATE_DECISION then
			ShotClock -= 1
			with Ball(0)
				ExertForce = ((Mouse(0).X - .X)^2 + (Mouse(0).Y - .Y)^2)^.75
				if multikey(SC_LSHIFT) then
					ExertForce ^= 0.7
				end if
				if multikey(SC_CONTROL) then
					ExertForce ^= 1.1
				end if
				if ExertForce < 50 then
					ExertForce = 0
				end if
				ExertForce = min(ExertForce, 16000)
				DispString = "Exerting "+dispThousandths(ExertForce)+"N on cue ball"
				
				drawAimAids
			end with
		elseif Stationary = 0 AND ExertForce > 0 AND PlayState <> STATE_FOULED then
			Stationary = 1
			with Ball(0)
				.Speed = ExertForce / (.Mass/1000) / 2.54
				.Angle = degtorad(extractAngle(Mouse(0).X - .X,Mouse(0).Y - .Y))
			end with
			
			playClip(SFX_CUE, ceil(ExertForce/50))
			ExertForce = 0
		elseif GameOver > 0 then
			DispString = "The money ball has been pocketed! Waiting for balls to stop..."
		elseif PlayState = STATE_DECISION then
			if NumPlayers = 0 then
				DispString = "Choose [2] or [3] players to start a new game."
				if InType = "2" then
					NumPlayers = 2
					PlayState = STATE_BREAK
				elseif InType = "3" then
					NumPlayers = 3
					PlayState = STATE_BREAK
				end if
				Player = irandom(1,NumPlayers)
			elseif UseRuleset = GAME_8BALL then
				if PlayerSlot(Player).CasualScore >= 7 then
					ShotClock -= 1
					DispString = "Call a pocket before hitting the cue ball. [1-6]"
					printgfx("1",BaseX+35,BaseY+31,4,rgb(255,255,255))
					printgfx("2",BaseX+35,BaseY+437,4,rgb(255,255,255))
					printgfx("3",BaseX+437,BaseY+31,4,rgb(255,255,255))
					printgfx("4",BaseX+437,BaseY+437,4,rgb(255,255,255))
					printgfx("5",BaseX+842,BaseY+31,4,rgb(255,255,255))
					printgfx("6",BaseX+842,BaseY+437,4,rgb(255,255,255))
					for CID as byte = 1 to 6
						if InType = str(CID) then
							CalledPocket = CID
							PlayState = STATE_NORMAL
						end if
					next CID
				end if
			elseif UseRuleset = GAME_ROTATION then
				ShotClock -= 1
				DispString = "Previous player fouled! You may [c]ontinue normally, or force the [p]revious player to shoot again."
				if InType = "c" then
					PlayState = STATE_NORMAL
					ShotClock = MaxShot*FrameRate
				elseif InType = "p" then
					PlayState = STATE_NORMAL
					do
						Player -= 1
						if Player < 1 then
							Player = NumPlayers 
						end if
					loop until PlayerSlot(Player).FoulCombo < 3
					ShotClock = MaxShot*FrameRate
				end if
			elseif UseRuleset = GAME_7BALL then
				ShotClock -= 1
				DispString = "Choose the [t]op or [b]ottom set of pockets before "
				if RivalInterrupt then
					DispString += "the opposition continues play."
				else
					DispString += "continuing play."
				end if
				if InType = "t" then
					TopChosen = Player
					if RivalInterrupt then
						Player = 3 - Player
					end if
					PlayState = STATE_NORMAL
					RivalInterrupt = 0
				elseif InType = "b" then
					TopChosen = 3 - Player
					if RivalInterrupt then
						Player = 3 - Player
					end if
					PlayState = STATE_NORMAL
					RivalInterrupt = 0
				end if
			elseif UseRuleset = GAME_1POCKET then
				DispString = "Choose the [t]op or [b]ottom foot pocket before beginning play."
				if InType = "t" then
					TopChosen = Player
					PlayState = STATE_BREAK
				elseif InType = "b" then
					TopChosen = 3 - Player
					PlayState = STATE_BREAK
				end if
			elseif UseRuleset = GAME_CRIBBAGE then
				ShotClock -= 1
				DispString = "Previous player fouled! You may [c]ontinue normally, or have ball-in-[h]and behihnd the head string."
				if InType = "c" then
					PlayState = STATE_NORMAL
					ShotClock = MaxShot*FrameRate
				elseif InType = "h" then
					PlayState = STATE_FOULED
					Mouse(0).Loaded = 0
					RestrictedPlace = 1
					ShotClock = MaxShot*FrameRate
				end if
			end if
		elseif Mouse(0).Loaded > 0 then
			DispString = "You have chosen to place a numbered ball on the table. Please place it, or clear it by pressing X."
			if InType = "x" then
				Mouse(0).Loaded = -1
			end if
		elseif Stationary = 0 AND PlayState = STATE_ILLEGAL_BREAK then
			ProperHit = 0
			ShotClock -= 1
			if UseRuleset = GAME_CRIBBAGE then
				DispString = "Illegal break! You may [r]ebreak, or force [p]revious player to rebreak."
			elseif UseRuleset = GAME_STRAIGHT_POOL then
				DispString = "Illegal break! You may place [c]ue ball, or force [p]revious player to rebreak."
			else
				DispString = "Illegal break! You may place [c]ue ball, [r]ebreak, or force [p]revious player to rebreak."
			end if
			if InType = "c" AND UseRuleset <> GAME_CRIBBAGE then
				PlayState = STATE_FOULED
				ShotClock += 15 * FrameRate
				RestrictedPlace = 1
			elseif InType = "r" AND UseRuleset <> GAME_STRAIGHT_POOL then
				newRack(UseRuleset,0)
				ShotClock += 30 * FrameRate
				Mouse(0).Loaded = 0
			elseif InType = "p" then
				newRack(UseRuleset,0)
				Player -= 1
				if Player < 1 then
					Player = NumPlayers 
				end if
				ShotClock = MaxShot*FrameRate
				Mouse(0).Loaded = 0
			end if
		elseif Stationary = 0 AND Ball(0).Alive = 0 AND PlayState <> STATE_BREAK then
			ShotClock -= 1
			DispString = "Cue ball "+chr(34)+"scratched"+chr(34)+". The cue ball must be placed before you can shoot."
		elseif Stationary = 0 AND Ball(0).Alive = 0 then
			DispString = "Position mouse over where you wish to place the cue ball, behind the head string, and click."
		elseif PlayState = STATE_FOULED AND Stationary = 0 AND Player > 0 AND UseRuleset <> GAME_TRAINING then
			Mouse(0).Loaded = 0
			ProperHit = 0
			ShotClock -= 1
			if RestrictedPlace then
				DispString = "Previous player fouled! Cue ball must be relocated behind the head string."
			else
				DispString = "Previous player fouled! Cue ball may be relocated anywhere."
			end if
		elseif PlayerSlot(Player).FoulCombo >= 2 AND UseRuleset <> GAME_8BALL AND UseRuleset <> GAME_CUTTHROAT AND UseRuleset <> GAME_TRAINING AND Stationary = 0 then
			ProperHit = 0
			ShotClock -= 1
			if UseRuleset = GAME_STRAIGHT_POOL then
				DispString = "Careful, player "+str(Player)+"! If you foul this shot, you will suffer a 15 point penalty."
			else
				DispString = "Careful, player "+str(Player)+"! If you foul this shot, you will lose the game!"
			end if
		elseif PlayState = STATE_NORMAL AND Stationary = 0 then
			ProperHit = 0
			ShotClock -= 1
			if MustScoreCribbage > 0 then
				DispString = "One or more loose balls are pocketed. Secure at one mate to prevent a foul."
			else
				DispString = "All balls are stationary. Hold the mouse down and point it to where you wish to shoot before releasing it."
			end if
		elseif Stationary = 0 then
			if UseRuleset = GAME_TRAINING then
				PlayState = STATE_NORMAL
			end if
			ProperHit = 0
			ShotClock -= 1
			DispString = "Cue ball placed. Hold the mouse down and point it to where you wish to shoot the cue ball before releasing it."
		else
			if ProperHit >= 0 then
				DispString = "Waiting for balls to approach a complete stop..."
			else
				DispString = "FOUL! Waiting for balls to approach a complete stop..."
				if TurnDing >= 0 then
					playClip(SFX_FOUL)
					TurnDing = -1
				end if
			end if
		end if

		with PlayerSlot(Player)
			if (PlayState = STATE_NORMAL OR PlayState = STATE_RECOVERED) AND Stationary >= 0 then
				if UseRuleset = GAME_7BALL AND TopChosen = 0 then
					if RivalInterrupt then
						Player = 3 - Player
					end if
					PlayState = STATE_DECISION
				elseif UseRuleset = GAME_8BALL AND .CasualScore = 7 AND .GroupAssigned > 0 AND CalledPocket = 0 then 
					PlayState = STATE_DECISION
				end if
			end if
		end with
		if ActualFPS < FrameRate * .9 then
			DispString = "Frame rate loss detected. ("+str(ActualFPS)+" FPS)"
		elseif ActualFPS > FrameRate * 1.1 then
			DispString = "Frame rate surge detected. ("+str(ActualFPS)+" FPS)"
		end if
		color rgb(0,0,0)
		draw string (SWidth/2 - len(DispString)*4,SHeight-16), DispString
		
		if UseRuleset = GAME_TRAINING then
			dim as string BallBinds(15) => {"`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "!", "@", "#", "$", "%"}
			if InType = "d" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed = irandom(0,10000)
						.Angle = rnd * 4 * pi
					end with
				next BID
			elseif InType = "D" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed = irandom(0,25000)
						.Angle = rnd * 4 * pi
					end with
				next BID
			elseif InType = "h" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed = irandom(0,50000)
						.Angle = rnd * 4 * pi
					end with
				next BID
			elseif InType = "H" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed = irandom(0,100000)
						.Angle = rnd * 4 * pi
					end with
				next BID
			elseif InType = "+" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed += 6.4
					end with
				next BID
			elseif InType = "-" then
				for BID as ubyte = 0 to 15
					with Ball(BID)
						.Speed -= 64
						if .Speed < 0 then
							.Speed = 0
						end if
					end with
				next BID
			elseif InType = "p" then
				PhysicsDisp = 1 - PhysicsDisp
			end if
			
			for BID as byte = 0 to 15
				if InType = BallBinds(BID) then
					Mouse(0).Loaded = BID
				end if
			next BID
			erase BallBinds
		end if
		screencopy
		while timer < FrameTime + 1/FrameRate:sleep 1:wend
		InType = inkey
		if InType = XBox then
			cleanSDL
			cleanUp
			end 0
		end if
	loop until InType = EscKey
	TurnDing = 0
	Mouse(0).HoldPress = 1
	Submenu = -1
end sub

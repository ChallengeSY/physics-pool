#include "PContact.bas"

sub spotObjectBalls
	if ProperHit < 3 OR Fouled > 0 OR ObjsNPlay = 0 then
		/'
		 ' Release holds on spots once an inning ends,
		 ' or if there are no object balls in play
		 '/
		for Billiard as byte = 1 to 15
			with Ball(Billiard)
				if .SpotTicket > 0 AND .DelaySpotting > 0 then
					.DelaySpotting = 0
				end if
			end with
		next
	end if

	'Spot object balls as needed
	for SpotOrder as short = 1 to 127
		for Billiard as byte = 1 to 15
			with Ball(Billiard)
				if .SpotTicket = SpotOrder AND .DelaySpotting = 0 then
					dim as ubyte Illegal
					dim as short PlaceY
					PlaceY = LongString
					for XID as short = FootString to LeftBorder + Diameter/2 step -1 'Start from foot string and work left
						Illegal = 0
						for BID as byte = 1 to 15 'Place as close to foot spot as possible while avoid contact with object balls
							with Ball(BID)
								if .Alive = 1 AND sqr(abs(XID - .X)^2 + abs(PlaceY - .Y)^2) < Diameter then
									Illegal = 1
									exit for
								end if
							end with
						next BID
		
						with Ball(0) 'Force an inch (8 pixels) of distance between cue ball and eight ball when spotting
							if .Alive = 1 AND sqr(abs(XID - .X)^2 + abs(PlaceY - .Y)^2) < Diameter + 8 then
								Illegal = 1
							end if
						end with
		
						if Illegal = 0 then
							with Ball(Billiard)
								.X = XID
								.Y = PlaceY
								.Speed = 0
								.SpotTicket = 0
								.Alive = 1
								exit for
							end with
						end if
					next XID
		
					if Ball(Billiard).Alive = 0 then
						'In case no suitable placement found, start from foot string, and work right
						for XID as short = FootString to RightBorder - Diameter/2
							Illegal = 0
							for BID as byte = 1 to 15 'Place as close to foot spot as possible while avoid contact with object balls
								with Ball(BID)
									if .Alive = 1 AND sqr((XID - .X)^2 + (PlaceY - .Y)^2) < Diameter then
										Illegal = 1
										exit for
									end if
								end with
							next BID
		
							with Ball(0) 'Force an inch (8 pixels) of distance between cue ball and eight ball when spotting
								if .Alive = 1 AND sqr((XID - .X)^2 + (PlaceY - .Y)^2) < Diameter + 8 then
									Illegal = 1
								end if
							end with
		
							if Illegal = 0 then
								with Ball(Billiard)
									.X = XID
									.Y = PlaceY
									.Speed = 0
									.SpotTicket = 0
									.Alive = 1
									exit for
								end with
							end if
						next XID
					end if
				end if
			end with
		next Billiard
	next SpotOrder
end sub

sub moveBallToCenterspot(BallObj as Sphere)
	with BallObj
		.X = RackSlot(SPECIAL_CENTER).X
		.Y = RackSlot(SPECIAL_CENTER).Y
	end with
end sub

sub moveBallToHeadspot(BallObj as Sphere)
	with BallObj
		.X = RackSlot(SPECIAL_HEAD).X
		.Y = RackSlot(SPECIAL_HEAD).Y
	end with
end sub

sub trainingInfo(XPos as short, YPos as short, PrintStr as string, NumericStart as short = 0)
	if len(PrintStr) > 0 then
		gfxstring(PrintStr,XPos,YPos,3,3,2,rgb(0,0,0))
		if NumericStart > 0 then
			gfxstring(space(NumericStart)+right(PrintStr,len(PrintStr)-NumericStart),XPos,YPos,3,3,2,rgb(128,128,0))
		end if
	end if
end sub

function findAlivePlayers as byte
	dim as byte PlayersFound
	if UseRuleset = GAME_TRAINING OR UseRuleset = GAME_8BALL OR UseRuleset = GAME_STRAIGHT_POOL then
		return 127
	end if
	
	for PID as byte = 1 to NumPlayers 
		with PlayerSlot(PID)
			if UseRuleset = GAME_CUTTHROAT then
				if .CasualScore > 0 then
					PlayersFound += 2^(PID-1)
				end if
			else
				if .FoulCombo < 3 then
					PlayersFound += 2^(PID-1)
				end if
			end if
		end with
	next PID
	
	return PlayersFound
end function

' -- Eight Ball extras --

sub assign8Bsuit(AssignStripes as byte)
	dim as byte UseBall, UsedBall(15), SeedBalls(15), Stripes, SeedIter, ScoringPlr
	Stripes = AssignStripes
	for PID as ubyte = 1 to 2
		Claimed(PID) = 0
		PlayerSlot(PID).CasualScore = 0
	next PID
	
	SeedIter = 1
	do
		SeedBalls(SeedIter) = irandom(1,15)

		if SeedIter > 1 then
			for PID as byte = 1 to SeedIter - 1
				if SeedBalls(SeedIter) = SeedBalls(PID) then
					continue do
				end if
			next
		end if
		
		SeedIter += 1
	loop until SeedIter > 15

	for BID as byte = 1 to 15
		UseBall = SeedBalls(BID)
		
		with Ball(UseBall)
			if .Alive = 0 then
				if UseBall < 8 then
					ScoringPlr = 3 - Stripes
				else
					ScoringPlr = Stripes
				end if
				with PlayerSlot(ScoringPlr)
					.CasualScore += 1
					.MoneyScore += 200
					.Pocketed(.CasualScore) = UseBall
				end with
				PlayerSlot(int(3-ScoringPlr)).MoneyScore -= 100
			end if
		end with
	next BID
	
	for PID as byte = 1 to 2
		with PlayerSlot(PID)
			if Stripes = PID then
				.GroupAssigned = SUIT_STRIPES
			else
				.GroupAssigned = SUIT_SOLIDS
			end if
		end with
	next
	erase UsedBall
end sub

' -- Rotation extras --

function findRotationRunaway as byte
	dim as short PointsAvail = 0, HighestScore, HighestPlr
	for BID as byte = 1 to 15
		if Ball(BID).Alive then
			PointsAvail += BID
		end if
	next BID
	
	for PID as byte = 1 to NumPlayers
		with PlayerSlot(PID)
			if .MoneyScore > HighestScore then
				HighestPlr = PID
				HighestScore = .MoneyScore
			end if
		end with
	next PID
	
	for OID as byte = 1 to NumPlayers
		with PlayerSlot(OID)
			if OID <> HighestPlr then
				if .MoneyScore + PointsAvail >= HighestScore then
					return 0
				end if
			end if
		end with
	next OID
	
	return HighestPlr
end function

' -- Cutthroat extras --

sub assignCutSuit(PlayerNum as byte, SuitID as byte)
	dim as byte PID, AssignedScoreSlot, AuxSuitFound, MissingSuit
	
	with PlayerSlot(PlayerNum)
		.GroupAssigned = SuitID
		if SuitID > 0 then
			for SuID as byte = 1 to 3
				.Pocketed(SuID) = 0
			next SuID
			
			.CasualScore = 0
			for BID as byte = SuitID*5-4 to SuitID*5
				AssignedScoreSlot = (BID-1) mod 5 + 1
				
				if Ball(BID).Alive then
					.CasualScore += 1
					.Pocketed(AssignedScoreSlot) = BID
				end if
			next BID
		end if
	end with
	
	if SuitID > 0 then
		for PID = 1 to 3
			if PlayerSlot(PID).GroupAssigned = -SuitID then
				PlayerSlot(PID).GroupAssigned = 0
			end if
			
			if PID <> PlayerNum AND PlayerSlot(PID).GroupAssigned <> 0 then
				AuxSuitFound = PlayerSlot(PID).GroupAssigned
			end if
		next PID
			
		if AuxSuitFound > 0 then
			do
				MissingSuit += 1
			loop until MissingSuit <> AuxSuitFound AND MissingSuit <> SuitID
			
			for PID = 1 to 3
				if PlayerSlot(PID).GroupAssigned = 0 then
					assignCutSuit(PID,MissingSuit)
					exit for
				end if
			next PID
		elseif AuxSuitFound < 0 then
			do
				MissingSuit += 1
			loop until MissingSuit <> abs(AuxSuitFound) AND MissingSuit <> SuitID
			
			for PID = 1 to 3
				if PlayerSlot(PID).GroupAssigned = AuxSuitFound then
					assignCutSuit(PID,MissingSuit)
					exit for
				end if
			next PID
		end if
	else
		for PID = 1 to 3
			if PlayerSlot(PID).GroupAssigned = -SuitID then
				PlayerSlot(PlayerNum).GroupAssigned = 0
				exit for
			end if
			
			if PID <> PlayerNum AND PlayerSlot(PID).GroupAssigned <> 0 then
				AuxSuitFound = PlayerSlot(PID).GroupAssigned
			end if
		next PID
			
		if AuxSuitFound = SuitID then
			for PID = 1 to 3
				if PlayerSlot(PID).GroupAssigned = 0 then
					PlayerSlot(PID).GroupAssigned = -SuitID
					exit for
				end if
			next PID
		end if
	end if
end sub

sub spotForCutPlayer(PlrID as byte)
	dim as byte RespawnBall, AssignScoreSlot
	
	with PlayerSlot(PlrID)
		do
			RespawnBall = irandom(1,5) + (PlayerSlot(PlrID).GroupAssigned-1)*5
			
			for SID as byte = 1 to 5
				if .Pocketed(SID) = RespawnBall then
					continue do
				end if
			next SID
			
			spotBall(RespawnBall)
			AssignScoreSlot = (RespawnBall - 1) mod 5 + 1
			.Pocketed(AssignScoreSlot) = RespawnBall
			exit do
		loop
		
		.CasualScore += 1
	end with
end sub

' -- Cribbage extras --

sub scoreCribbageBall(ActivePlr as PlrSpecs, BallID as byte)
	with ActivePlr
		if BallID = 15 then
			if PlayerSlot(1).CasualScore + PlayerSlot(2).CasualScore = 14 then
				'Allow this ball to be pocketed, once all other balls are pocketed
				.CasualScore += 1
				.Pocketed(.CasualScore) = BallID
				.MoneyScore += 1 * iif(NumPlayers > 1, 1, 100)
				GameOver = 1
			
				if ProperHit >= 0 then
					ProperHit = 3
				end if
			else
				'Otherwise, spot this ball
				spotBall(BallID,0)
			end if 
		else
			for CheckID as byte = 1 to 15 step 2
				if BallID + .Pocketed(CheckID) = 15 then
					'Cribbage completed. Both balls now count as scored
					.Pocketed(CheckID+1) = BallID
					.CasualScore += 2
					.MoneyScore += 1 * iif(NumPlayers > 1, 1, 100)
					
					MustScoreCribbage = 0
					exit for
				elseif .Pocketed(CheckID) = 0 then
					'Score this ball, but it does not complete a cribbage
					.Pocketed(CheckID) = BallID
					exit for
				end if
			next CheckID
			
			if ProperHit >= 0 then
				ProperHit = 3
			end if
		end if
	end with

end sub

function checkUnpairedBalls(ActivePlr as PlrSpecs) as byte
	if UseRuleset <> GAME_CRIBBAGE then
		return 0
	end if
	
	with ActivePlr
		for CheckID as byte = 1 to 15 step 2
			if .Pocketed(CheckID) > 0 AND .Pocketed(CheckID+1) = 0 then
				return 1
			end if
		next CheckID
	end with
	
	return 0
end function

sub removeUnpairedBalls(ActivePlr as PlrSpecs)
	with ActivePlr
		for CheckID as byte = 1 to 15 step 2
			if .Pocketed(CheckID+1) = 0 then
				spotBall(.Pocketed(CheckID))
				.Pocketed(CheckID) = 0
			end if
		next CheckID
	end with
end sub

' -- Straight Pool extras --

sub newStraightRack
	dim as byte UseSlot, LooseBall, HeadStrConf, LooseBallConf, CueBallConf
	
	for BID as byte = 1 to 15
		if Ball(BID).Alive then
			LooseBall = BID
			if Ball(BID).X > HeadString then
				HeadStrConf = 1
			end if
		end if
		RackSlot(BID).Used = 0
		RackSlot(BID).Restricted = 0
	next BID
	
	for PID as byte = 1 to NumPlayers
		with PlayerSlot(PID)
			.CasualScore = 0
			for SID as byte = 1 to 15
				.Pocketed(SID) = 0
			next SID
		end with
	next PID
	
	if LooseBall > 0 then
		RackSlot(RACK_FOOT).Used = 1
	end if
	
	'First, rerack the pocketed balls
	for NewBall as byte = 1 to 15
		with Ball(NewBall)
			if .Alive = 0 then
				'Distribute balls randomly
				UseSlot = randomDistribution
				
				.X = RackSlot(UseSlot).X
				.Y = RackSlot(UseSlot).Y
				.Speed = 0
				.Angle = 0
				.Alive = 1
				.Mass = 167
				
				RackSlot(UseSlot).Used = NewBall
			end if
		end with
	next NewBall
	
	'Check for conflicts
	for BID as byte = 1 to 15
		if LooseBall > 0 AND BID <> LooseBall then
			if ballsInContact(Ball(BID),Ball(LooseBall)) then
				LooseBallConf = 1
			end if
		end if

		if ballsInContact(Ball(BID),Ball(0)) then
			CueBallConf = 1
		end if
	next BID
	
	'Reposition balls based on conflict factors
	if LooseBallConf AND CueBallConf then
		'Both balls interfere? Rerack the last object ball as if it was pocketed, and give player ball in hand behind head string
		with Ball(LooseBall)
			.X = RackSlot(RACK_FOOT).X
			.Y = RackSlot(RACK_FOOT).Y
		end with

		with Ball(0)
			.Alive = 0
		end with
		RestrictedPlace = 1
	elseif LooseBallConf then
		'Only the loose object ball interferes? Position on head spot if possible; else center spot
		moveBallToHeadspot(Ball(LooseBall))
		
		if ballsInContact(Ball(LooseBall),Ball(0)) then
			moveBallToCenterspot(Ball(LooseBall))
		end if
	elseif CueBallConf then
		'Only cue ball interferes? Could be in hand, or on the head spot, or on the center spot
		if HeadStrConf = 0 then
			'If loose object ball is past head string, then ball in hand behind head string
			with Ball(0)
				.Alive = 0
			end with
			RestrictedPlace = 1
		else
			moveBallToHeadspot(Ball(0))
			
			if ballsInContact(Ball(LooseBall),Ball(0)) then
				moveBallToCenterspot(Ball(0))
			end if
		end if
	end if
end sub

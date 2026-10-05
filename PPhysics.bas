#include "PPhysics.bi"
function wallDetection(LocalObj as Sphere) as byte
	dim as byte BallBounce = 0
	with LocalObj
		'Vertical borders
		if .X < LeftBorder + (Diameter/2) then
			BallBounce = 1
		end if
		
		if .X > RightBorder - (Diameter/2) then
			BallBounce = 2
		end if
		
		'Horizontal borders
		if .Y < TopBorder + (Diameter/2) AND abs((LeftBorder+RightBorder)/2 - .X) > 26 then
			BallBounce = 3
		end if

		if .Y > BottomBorder - (Diameter/2) AND abs((LeftBorder+RightBorder)/2 - .X) > 26 then
			BallBounce = 4
		end if
	end with
	return BallBounce
end function

sub wallCollisions(Billiard as Sphere)
	dim as byte WallsHit = 0
	
	' Whenever a ball collides with a wall, it bounces back.
	with Billiard
		if wallDetection(Billiard) = 1 then
			.X = (LeftBorder + (Diameter/2))*2 - .X
			playClip(SFX_WALL, ceil(abs(cos(.Angle))) * .Speed / 32)
			.Speed *= Elasticity
			.Angle = pi - .Angle
			WallsHit += 1
			if .WallBounce = 0 then
				InitialHits += 1
				if Billiard.Namee = "Cue Ball" then InitialCue = 1
				.WallBounce = 1
			end if
		elseif wallDetection(Billiard) = 2 then
			.X = (RightBorder - (Diameter/2))*2 - .X
			playClip(SFX_WALL, ceil(abs(cos(.Angle))) * .Speed / 32)
			.Speed *= Elasticity
			.Angle = pi - .Angle
			WallsHit += 1
			if .WallBounce = 0 then
				InitialHits += 1
				if Billiard.Namee = "Cue Ball" then InitialCue = 1
				.WallBounce = 1
			end if
		end if
		
		if wallDetection(Billiard) = 3 then
			.Y = (TopBorder + (Diameter/2))*2 - .Y
			playClip(SFX_WALL, ceil(abs(sin(.Angle))) * .Speed / 32)
			.Speed *= Elasticity
			.Angle = -.Angle
			WallsHit += 1
			if .WallBounce = 0 then
				InitialHits += 1
				if Billiard.Namee = "Cue Ball" then InitialCue = 1
				.WallBounce = 1
			end if
		elseif wallDetection(Billiard) = 4 then
			.Y = (BottomBorder - (Diameter/2))*2 - .Y
			playClip(SFX_WALL, ceil(abs(sin(.Angle))) * .Speed / 32)
			.Speed *= Elasticity
			.Angle = -.Angle
			WallsHit += 1
			if .WallBounce = 0 then
				InitialHits += 1
				if Billiard.Namee = "Cue Ball" then InitialCue = 1
				.WallBounce = 1
			end if
		end if
	end with
	
	if WallsHit > 0 AND ProperHit = 1 then
		ProperHit = 2
	end if
end sub

function pocketDetection(LocalObj as Sphere) as byte
	dim as byte BallFall = 0
	with LocalObj
		'Test the foot corner pockets
		if sqr((LeftBorder - .X)^2 + (TopBorder - .Y)^2) < 24 then
			BallFall = 1
		end if

		if sqr((LeftBorder - .X)^2 + (BottomBorder - .Y)^2) < 24 then
			BallFall = 2
		end if

		'Test the side pockets
		if sqr((SidePockets - .X)^2 + ((TopBorder - .Y)*sqr(2))^2) < 26 then
			BallFall = 3
		end if

		if sqr((SidePockets - .X)^2 + ((BottomBorder - .Y)*sqr(2))^2) < 26 then
			BallFall = 4
		end if

		'Test the head corner pockets
		if sqr((RightBorder - .X)^2 + (TopBorder - .Y)^2) < 24 then
			BallFall = 5
		end if

		if sqr((RightBorder - .X)^2 + (BottomBorder - .Y)^2) < 24 then
			BallFall = 6
		end if
	end with
	return BallFall
end function

/' -------------------------------------------------------------------------- '/

sub drawTrails(Billiard as byte)
	with Ball(Billiard)
		for TID as byte = 1 to ubound(.TrailX)
			if .TrailX(TID) > 0 then
				put(.TrailX(TID)-int(Diameter/2),.TrailY(TID)-int(Diameter/2)),BallPic(0),alpha,16
			end if
		next TID
	end with
end sub
sub drawBall(Billiard as byte)
	drawTrails(Billiard)
	
	with Ball(Billiard)
		if .Alive > 0 then
			put(.X-int(Diameter/2),.Y-int(Diameter/2)),BallPic(Billiard),trans
		end if
	end with
end sub

sub bounceCollisions overload(Billiard as byte, ApplyResponse as byte = 1)
	dim as single Fastest
	dim as byte LowestAlive = lowestFirst

	with Ball(Billiard)
		for CID as ubyte = 0 to 15
			if CID <> Billiard then
				if ballsInContact(Ball(Billiard),Ball(CID)) AND (.Speed > 1e-6 OR Ball(CID).Speed > 1e-6) AND Ball(CID).Alive = 1 then

					' Break these into components. We will need them later.
					.SpeedX = .Speed*cos(.Angle)
					.SpeedY = -.Speed*sin(.Angle)
					Ball(CID).SpeedX = Ball(CID).Speed*cos(Ball(CID).Angle)
					Ball(CID).SpeedY = -Ball(CID).Speed*sin(Ball(CID).Angle)

					' Some checking is done to determine if a player fouls. It varies from one game to another
					if cueInvolved(Billiard,CID) AND ProperHit = 0 then
						if MustCrossString = 1 then
							/'
							 ' If this rarely used setting is enabled, hitting any ball 
							 ' *before* crossing the head string is an automatic foul.
							 '/
							ProperHit = -1
						else
							select case UseRuleset
								case GAME_TRAINING
									if ProperHit >= 0 then
										ProperHit = 1
									end if
								case GAME_8BALL
									if PlayerSlot(Player).GroupAssigned > 0 then
										if cueContact(Billiard,CID) = 8 then
											/'
											 ' Hitting the Eight-Ball constitutes a foul, unless
											 ' a player has already pocketed all balls of his suit
											 '/
											if PlayerSlot(Player).CasualScore < 7 then
												ProperHit = -1
											else
												ProperHit = 1
											end if
										elseif (PlayerSlot(Player).GroupAssigned = SUIT_STRIPES AND cueContact(Billiard,CID) > 8) OR _
											(PlayerSlot(Player).GroupAssigned = SUIT_SOLIDS AND cueContact(Billiard,CID) < 8) then
											'Hitting a ball of matching suit as the first ball of a shot is legal
											ProperHit = 1
										else
											'Hitting a ball of opposing suits first is considered a foul
											ProperHit = -1
										end if
									elseif PlayerSlot(Player).GroupAssigned = 0 then
										'When suits are unassigned, all balls are legal, except the 8-ball.
										if cueContact(Billiard,CID) = 8 then
											ProperHit = -1
										else
											ProperHit = 1
										end if
									end if
									
								case GAME_9BALL, GAME_10BALL, GAME_6BALL, GAME_ROTATION, GAME_7BALL
									'Hitting the lowest ball in play first is legal.
									if cueContact(Billiard,CID) = LowestAlive then
										ProperHit = 1
									else
										ProperHit = -1
									end if
								case GAME_CUTTHROAT
									'Hitting any ball first that does not belong to the active player is legal.
									if ceil(cueContact(Billiard,CID)/5) <> PlayerSlot(Player).GroupAssigned then
										ProperHit = 1
									else
										ProperHit = -1
									end if
								case GAME_15BALL, GAME_STRAIGHT_POOL, GAME_1POCKET, GAME_CRIBBAGE
									'All numbered balls are legal to hit
									ProperHit = 1
							end select
						end if
					end if

					if ApplyResponse then
						collisionResponse(Ball(Billiard),Ball(CID))
						
						if DebugCapture = 1 then
							DebugCapture = 2
							for BID as byte = 0 to 15
								drawball(BID)
							next BID
							
							line(Ball(Billiard).X,Ball(Billiard).Y)-(Ball(CID).X,Ball(CID).Y),rgb(64,64,64)
							line(Ball(Billiard).X,Ball(Billiard).Y)-_
								(Ball(Billiard).X+cos(Ball(Billiard).Angle)*Ball(Billiard).Speed/8^2,Ball(Billiard).Y-sin(Ball(Billiard).Angle)*Ball(Billiard).Speed/8^2),_
								rgb(255,128,128)
							line(Ball(CID).X,Ball(CID).Y)-_
								(Ball(CID).X+cos(Ball(CID).Angle)*Ball(CID).Speed/8^2,Ball(CID).Y-sin(Ball(CID).Angle)*Ball(CID).Speed/8^2),_
								rgb(128,128,255)

							screencopy
							sleep
							FrameTime = timer
						end if
					end if
				end if
			end if
		next CID
	end with
end sub
sub bounceCollisions overload(LocalObj as Sphere, ApplyResponse as byte = 1)
	dim as single Fastest
	dim as byte LowestAlive = lowestFirst

	with LocalObj
		for CID as ubyte = 1 to 15
			if ballsInContact(LocalObj,Ball(CID)) AND (.Speed > 1e-6 OR Ball(CID).Speed > 1e-6) AND Ball(CID).Alive = 1 then

				' Break these into components. We will need them later.
				.SpeedX = .Speed*cos(.Angle)
				.SpeedY = -.Speed*sin(.Angle)
				Ball(CID).SpeedX = Ball(CID).Speed*cos(Ball(CID).Angle)
				Ball(CID).SpeedY = -Ball(CID).Speed*sin(Ball(CID).Angle)

				if ApplyResponse then
					collisionResponse(LocalObj,Ball(CID),1)
				end if
			end if
		next CID
	end with
end sub


sub renderBall(Billiard as byte)
	dim as ubyte AlphaFormula, PocketFallen, SuitPocketed
	with Ball(Billiard)
		if .Alive = 1 then
			PocketFallen = pocketDetection(Ball(Billiard))

			if PocketFallen > 0 then
				/'
				 ' Checks for whether a ball falls within the bound of a pocket,
				 ' and eliminates the ball if this is the case. This is referred
				 ' to as "pocketing" the ball.
				 '/
				if Billiard = 0 then
					/'
					 ' Cue ball "scratched". Constitutes a foul. If scratched during
					 ' the break shot, then opponent has ball-in-hand behind the head
					 ' string, instead of anywhere.
					 '/
					ProperHit = -1
					if PlayState = STATE_BREAK then
						RestrictedPlace = 1
					end if
				else
					select case UseRuleset
						case GAME_TRAINING
							with PlayerSlot(Player)
								.CasualScore += 1
								.MoneyScore += .CasualScore^2 + Billiard^2
								if .CasualScore <= 15 then
									.Pocketed(.CasualScore) = Billiard
								else
									for BID as short = 1 to 14
										.Pocketed(BID) = .Pocketed(BID+1)
									next BID
									.Pocketed(15) = Billiard
								end if
							end with

							if ProperHit >= 0 then
								ProperHit = 3
							end if
						case GAME_8BALL
							if Billiard = 8 then
								/'
								 ' Normally, the eight ball ends the game. However, if the eight
								 ' ball is pocketed during the break shot, then it is spotted instead
								 ' at the foot spot. The shooter (assuming no foul) can
								 ' either accept this configuration, or request a rerack
								 '/
								if PlayState = STATE_BREAK then
									spotBall(Billiard)
								else
									with PlayerSlot(Player)
										.CasualScore += 1
										.Pocketed(.CasualScore) = Billiard
										
										GameOver = 2

										if .PrevCasual < 7 OR .GroupAssigned = 0 OR PocketFallen <> CalledPocket then
											'If the eight ball was pocketed illegally, then the opponent wins
											Victor = 3 - Player
											if NumPlayers < 2 then
												ProperHit = -1
											end if
											.FoulCombo = max(.FoulCombo, 3)
										else
											'Otherwise, give the victor $200
											.MoneyScore += 200
											ProperHit = 3
										end if
									end with
								end if
							elseif Billiard > 0 then
								if PlayState = STATE_BREAK then
									/'
									 ' No scoring during the break shot. The field remains open
									 ' Counts as a legal break, even if fewer than four balls hit
									 ' the rails
									 '/
									if ProperHit >= 0 then
										ProperHit = 3
									end if
									with PlayerSlot(Player)
										.CasualScore += 1
									end with
								elseif PlayerSlot(Player).GroupAssigned = 0 then
									/'
									 ' Suits have not yet been claimed. If balls from both suits get
									 ' pocketed, the pocketing player will get the majority suit.
									 '
									 ' In the case of a tie, the last ball pocketed is factored out.
									 '/
									if Billiard < 8 then
										if int(Claimed(1)) >= int(Claimed(2)) then
											Claimed(1) = int(Claimed(1)) + 1.5
											Claimed(2) = int(Claimed(2))
										else 
											Claimed(1) = int(Claimed(1)) + 1
										end if
									elseif Billiard > 8 then
										if int(Claimed(2)) >= int(Claimed(1)) then
											Claimed(2) = int(Claimed(2)) + 1.5
											Claimed(1) = int(Claimed(1))
										else 
											Claimed(2) = int(Claimed(2)) + 1
										end if
									end if
									if ProperHit >= 0 then
										ProperHit = 3
									end if
									with PlayerSlot(Player)
										.CasualScore += 1
									end with
								elseif Billiard < 8 then
									' Scores the ball to the solid player.
									for PID as byte = 1 to 2
										with PlayerSlot(PID)
											if .GroupAssigned = SUIT_SOLIDS then
												.CasualScore += 1
												.MoneyScore += 200
												.Pocketed(.CasualScore) = Billiard
												
												if Player = PID AND ProperHit >= 0 then
													ProperHit = 3
												end if
											else
												.MoneyScore -= 100
											end if
										end with
									next
								else
									' Scores the ball to the stripes player.
									for PID as byte = 1 to 2
										with PlayerSlot(PID)
											if .GroupAssigned = SUIT_STRIPES then
												.CasualScore += 1
												.MoneyScore += 200
												.Pocketed(.CasualScore) = Billiard
												
												if Player = PID AND ProperHit >= 0 then
													ProperHit = 3
												end if
											else
												.MoneyScore -= 100
											end if
										end with
									next
								end if
							end if
						case GAME_9BALL, GAME_10BALL, GAME_6BALL
							'All billiard balls (including the money ball) are legally pocketable, unless fouled
							with PlayerSlot(Player)
								.CasualScore += 1
								.MoneyScore += 100
								.Pocketed(.CasualScore) = Billiard
							end with

							if ProperHit >= 0 then
								ProperHit = 3
							end if

							if Billiard = MoneyBall then
								'Whenever the money ball becomes pocketed, there is a possibility of the game ending.
								GameOver = 1

								if Billiard = 10 AND PlayState = STATE_BREAK then
									'Exception, if the 10-ball becomes pocketed during its game's break shot, it becomes spotted.
									GameOver = 0
									spotBall(10)
									
									if NumPlayers = 1 then
										with PlayerSlot(1)
											.CasualScore -= 1
											.MoneyScore -= 100
										end with
									end if
								end if
							end if
						case GAME_15BALL, GAME_ROTATION
							'All billiard balls are legally pocketable
							with PlayerSlot(Player)
								.CasualScore += 1
								.MoneyScore += Billiard
								.Pocketed(.CasualScore) = Billiard
							end with
							
							if ProperHit >= 0 then
								ProperHit = 3
							end if
						case GAME_CUTTHROAT
							SuitPocketed = ceil(Billiard/5)
							for PID as byte = 1 to 3
								with PlayerSlot(PID)
									if .GroupAssigned = SuitPocketed then
										.CasualScore -= 1
										for SID as byte = 1 to 5
											if .Pocketed(SID) = Billiard then
												.Pocketed(SID) = 0
												exit for
											end if
										next SID
									end if
								end with
							next
							
							if PlayerSlot(Player).GroupAssigned <= 0 then
								Claimed(SuitPocketed) += 1
							end if
							
							if ProperHit >= 0 then
								ProperHit = 3
							end if
							
						case GAME_7BALL
							'Most billiard balls are legally pocketable
							with PlayerSlot(Player)
								.CasualScore += 1
								.MoneyScore += 100
								.Pocketed(.CasualScore) = Billiard
							end with

							if ProperHit >= 0 then
								ProperHit = 3
							end if

							if Billiard = MoneyBall then
								if PlayState = STATE_BREAK then
									'If the money ball is pocketed during the break shot, it becomes spotted
									spotBall(Billiard)
								else
									'Beyond the break shot, check to verify that it was pocketed in the correct side
									GameOver = 2
									
									if PocketFallen < 4 then
										'In the top pockets? The victor by default goes to the player assigned to the top side
										Victor = TopChosen
									else
										'Otherwise, to the player assigned to the bottom side
										Victor = 3 - TopChosen
									end if
								end if
							end if
							
						case GAME_1POCKET
							dim as byte PlayerRef
							/'
							 ' All billiard balls are legally pocketable. However, who gets
							 ' credit is dependent on the pocket in question
							 '/
							if PocketFallen = 1 then
								PlayerRef = TopChosen
							elseif PocketFallen = 2 then
								PlayerRef = 3 - TopChosen
							else
								'If the ball falls into a neutral pocket, it is queued for spotting
								PlayerRef = 0
								spotBall(Billiard,1)
							end if

							if PlayerRef = Player AND ProperHit >= 0 then
								ProperHit = 3
							end if


							if PlayerRef > 0 then
								with PlayerSlot(PlayerRef)
									.CasualScore += 1
									.MoneyScore += .CasualScore^2 + Billiard^2
									if .CasualScore > 0 then
										.Pocketed(.CasualScore) = Billiard
									else
										/'
										 ' If the credited player owes points due to excessive fouls,
										 ' then the ball is queued for spotting
										 '/
										spotBall(Billiard,1)
									end if
								end with
							end if
						case GAME_CRIBBAGE
							'Because Cribbage has a unique scoring mechanism, it gets a corresponding function.
							scoreCribbageBall(PlayerSlot(Player), Billiard)

						case GAME_STRAIGHT_POOL
							'All billiard balls are legally pocketable. There is no money ball
							with PlayerSlot(Player)
								.CasualScore += 1
								.MoneyScore += 1
								.Pocketed(.CasualScore) = Billiard
							end with

							if ProperHit >= 0 then
								ProperHit = 3
							end if
					end select
				end if
				.Alive = 0
				playClip(SFX_POCKET)
				if Stationary >= 0 then
					Stationary = 0
				end if

				'Pocketed object balls automatically meet break requirements
				if Billiard > 0 then
					InitialHits = InitialQuota
					InitialCue = CueRailReq
				end if
				if ProperHit = 1 then
					ProperHit = 2
				end if
			else
				dim as double FrictionForce
				if Billiard = 0 AND .X < HeadString then
					'Head string crossed, clear flag
					MustCrossString = 0
				end if

				' Checks for collisions and applies friction.
				wallCollisions(Ball(Billiard))
				bounceCollisions(Billiard)

				.X += .Speed*cos(.Angle)/FrameRate/InternalUpdateRate/8
				.Y -= .Speed*sin(.Angle)/FrameRate/InternalUpdateRate/8
				FrictionForce = 9.8 * Friction / FrameRate / InternalUpdateRate  * .Speed
				.Speed -= FrictionForce

				if .Speed > MinSpeed then
					/'
					 ' Due to computation math, the balls only need to reach
					 ' a small speed to be no longer counted as moving
					 '/
					Stationary = -1
				end if
			end if
		end if
		.Energy = .Mass/1000 * (.Speed*.0254)^2 / 2
		.Momentum = .Mass/1000 * .Speed*.0254
	end with
end sub

sub renderTable
	'Animate the head string
	if FramesRecorded mod 2 = 0 then
		if (KitchenPattern AND (1 SHL 3)) then
			KitchenPattern = KitchenPattern * 2
		else
			KitchenPattern = KitchenPattern * 2 + 1
		end if
		if KitchenPattern >= 2^16 then
			KitchenPattern -= 2^16
		end if
	end if
	
	put(BaseX,BaseY),Table,pset
	'Display head string situationally
	if (PlayState = STATE_BREAK AND Ball(0).Alive = 0 AND Stationary = 0) OR (RestrictedPlace AND (Mouse(0).Loaded >= 0)) OR MustCrossString then
		line (BaseX+644,BaseY+44)-(BaseX+644,BaseY+443),rgb(255,255,255),,KitchenPattern
	end if
	if Stationary < 0 then
		Stationary = 1
	end if
	TotalE = 0
	TotalV = 0

	ObjsNPlay = 0
	for IUT as short = 1 to InternalUpdateRate
		for BID as ubyte = 0 to 15
			with Ball(BID)
				if .Alive > 0 then
					if IUT = 1 then
						if BID > 0 then ObjsNPlay += 1
						TotalE += .Momentum
						TotalV += .Speed

						if sqr(abs(Mouse(0).X - .X)^2 + abs(Mouse(0).Y - .Y)^2) < Diameter/2 then
							SelectedBall = BID
						end if
					end if
					renderBall(BID)
					if IUT = InternalUpdateRate then
						drawBall(BID)
					elseif IUT mod 45 = 1 then
						for TID as byte = ubound(.TrailX) to 2 step -1
							.TrailX(TID) = .TrailX(int(TID-1)) 
							.TrailY(TID) = .TrailY(int(TID-1)) 
						next TID 
						
						if .Speed > MinSpeed then
							.TrailX(1) = .X
							.TrailY(1) = .Y
						else
							.TrailX(1) = 0
							.TrailY(1) = 0
						end if
					end if
				else
					if IUT = InternalUpdateRate then
						drawTrails(BID)
					elseif IUT mod 45 = 1 then
						for TID as byte = ubound(.TrailX) to 2 step -1
							.TrailX(TID) = .TrailX(int(TID-1)) 
							.TrailY(TID) = .TrailY(int(TID-1)) 
						next TID 
						
						.TrailX(1) = 0
						.TrailY(1) = 0 
					end if	
				end if
			end with
		next BID
	next IUT
end sub

/' -------------------------------------------------------------------------- '/

sub drawAimAids
	dim as double WorkAngle
	line AidMarkings,(0,0)-(SWidth,SHeight),rgb(255,0,255),bf
	
	with Ball(0)
		WorkAngle = degtorad(extractAngle(Mouse(0).X - .X,Mouse(0).Y - .Y))
		
		'A simple line from cue ball to aim point is common among all aid levels
		line(.X,.Y)-(Mouse(0).X,Mouse(0).Y),rgb(64,64,255)
	end with
	
	GhostAid = Ball(0)
	GhostAid.Angle = WorkAngle
	
	if Mouse(0).X = Mouse(1).X AND Mouse(0).Y = Mouse(1).Y then
		if PhysicsAids > 0 then
			dim as byte FinishLoop = 0, WallBounces = 0
			dim as byte HitsPreview(15) => {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			
			with GhostAid
				.Speed = 16
				
				do
					put AidMarkings,(.X-int(Diameter/2),.Y-int(Diameter/2)),BallPic(0),trans
					
					.X += cos(.Angle) * 0.75
					.Y -= sin(.Angle) * 0.75
					
					for OID as byte = 1 to 15
						if ballsInContact(GhostAid,Ball(OID)) then
							if PhysicsAids < 2 then
								FinishLoop = 1
							elseif HitsPreview(OID) = 0 then
								bounceCollisions(GhostAid)
								HitsPreview(OID) = 1
							end if
						end if
					next OID
					
					if pocketDetection(GhostAid) then
						FinishLoop = 1
					end if
					
					if wallDetection(GhostAid) then
						if WallBounces + 2 < PhysicsAids then
							WallBounces += 1
							wallCollisions(GhostAid)
						else
							FinishLoop = 1
						end if 
					end if
				loop until FinishLoop
			end with
		end if
	
		put (0,0), AidMarkings, alpha, 128
	end if
	Mouse(1) = Mouse(0)
end sub

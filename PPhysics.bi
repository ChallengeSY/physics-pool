/' 
 ' Fetch the most appropriate angle based on direction.
 ' (ArcTangent has its limitations, as useful as it otherwise tends to be.)
 '/
function extractAngle overload(BallA as Sphere, BallB as Sphere) as double
	dim as double FindAngle
	with BallA
		FindAngle = radtodeg(atn((.Y - BallB.Y)/(BallB.X - .X)))
		if .X > BallB.X then
			FindAngle += 180
		elseif .X = BallB.X then
			if .Y < BallB.Y then
				return 270
			else
				return 90
			end if
		end if
	end with
	return remainder(FindAngle + 720,360)
end function
function extractAngle overload(VectorX as double, VectorY as double) as double
	dim as double FindAngle
	FindAngle = radtodeg(atn(-VectorY/VectorX))
	if VectorX < 0 then
		FindAngle += 180
	elseif VectorX = 0 then
		if VectorY < 0 then
			return 270
		else
			return 90
		end if
	end if
	
	return remainder(FindAngle + 720,360)
end function

sub collisionResponse(BallA as Sphere, BallB as Sphere, SourceOnly as byte = 0)
	dim as double CollideAngle(2), XferMult(2), Amplibounce
	dim as Sphere OrgA = BallA, OrgB = BallB

	' Determine the angles that the opposing balls would be influcenced by	
	CollideAngle(1) = extractAngle(OrgA, OrgB)
	CollideAngle(2) = extractAngle(OrgB, OrgA)
	
	' How much momentum to transfer to the target? 
	XferMult(1) = cos(OrgA.Angle - degtorad(CollideAngle(1)))
	XferMult(2) = cos(OrgB.Angle - degtorad(CollideAngle(2)))
	
	if XferMult(1) > 0.001 OR XferMult(2) > 0.001 then
		' Apply collision response, but try to also prevent balls from getting stuck
		BallB.SpeedX += (cos(degtorad(CollideAngle(1))) * OrgA.Speed * XferMult(1) * elasticity) - (cos(degtorad(CollideAngle(2))) * OrgB.Speed * XferMult(2))
		BallB.SpeedY -= (sin(degtorad(CollideAngle(1))) * OrgA.Speed * XferMult(1) * elasticity) - (sin(degtorad(CollideAngle(2))) * OrgB.Speed * XferMult(2))
		BallA.SpeedX += (cos(degtorad(CollideAngle(2))) * OrgB.Speed * XferMult(2) * elasticity) - (cos(degtorad(CollideAngle(1))) * OrgA.Speed * XferMult(1))
		BallA.SpeedY -= (sin(degtorad(CollideAngle(2))) * OrgB.Speed * XferMult(2) * elasticity) - (sin(degtorad(CollideAngle(1))) * OrgA.Speed * XferMult(1))
		
		if SourceOnly = 0 then
			Amplibounce = ceil(max(OrgA.Speed * XferMult(1), OrgB.Speed * XferMult(2)) / 32)
			playClip(SFX_BALL, Amplibounce)
		end if
	
		' Update parameters based on changes to the components
		with BallA
			.Speed = sqr((.SpeedX)^2 + (.SpeedY)^2)
			.Angle = degtorad(extractAngle(.SpeedX, .SpeedY))
		end with
		if SourceOnly = 0 then  
			with BallB
				.Speed = sqr((.SpeedX)^2 + (.SpeedY)^2)
				.Angle = degtorad(extractAngle(.SpeedX, .SpeedY))
			end with
		
			' Some debug info
			if DebugCapture = 0 AND UseRuleset = GAME_TRAINING then
				DebugCapture = 1
				DispString = "Paused at the first collision of the shot. Press any key to continue..."
				color rgb(0,0,0)
				draw string (SWidth/2 - len(DispString)*4,SHeight-16), DispString
			end if
		end if
	end if
end sub

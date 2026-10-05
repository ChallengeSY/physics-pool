function ballsInContact(BallA as Sphere, BallB as Sphere) as integer
	return sqr((BallA.X - BallB.X)^2 + (BallA.Y - BallB.Y)^2) <= Diameter
end function

function cueInvolved(BallA as byte, BallB as byte) as integer
	return (BallA = 0 OR BallB = 0)
end function

function cueContact(BallA as byte, BallB as byte) as byte
	return iif(BallA = 0,BallB,BallA)
end function

function lowestFirst as byte
	for BallID as ubyte = 1 to 15
		with Ball(BallID)
			if .Alive > 0 then
				return BallID
			end if
		end with
	next BallID

	return 0
end function

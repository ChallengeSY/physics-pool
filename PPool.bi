/'
 ' Sample collected from a set of billard balls
 '
 ' Universal ball diameter: 2.25"
 ' Cue ball: 168.66g
 ' 1 ball: 170.77g
 ' 2 ball: 166.28g
 ' 3 ball: 166.80g
 ' 4 ball: 167.76g
 ' 5 ball: 167.05g
 ' 6 ball: 168.84g
 ' 7 ball: 166.77g
 ' 8 ball: 166.59g
 ' 9 ball: 167.35g
 ' 10 ball: 168.13g
 ' 11 ball: 167.44g
 ' 12 ball: 167.81g
 ' 13 ball: 168.83g
 ' 14 ball: 169.23g
 ' 15 ball: 168.15g
 ' Average: 167.853g
 '
 ' Pool Table: Tournament Size (100" + 11" by 50" + 11")
 '/
randomize timer
#include "vbcompat.bi"
#include "fbgfx.bi"
#include "ABCgfx.bi"
#include "PPSDL.bas"
#include "CSYMath.bi"
using FB
type Sphere
	' Ball data is grouped here
	Namee as string 'Name of the ball
	X as double 'Position
	Y as double
	Speed as double 'Speed, breakable into components
	SpeedX as double
	SpeedY as double
	Momentum as double 'Momentum, as above
	MomentumX as double
	MomentumY as double
	Energy as double

	Angle as double
	Alive as ubyte 'Is the ball in play?
	Mass as double 'Mass in grams

	/'
	 ' When a ball is queued for spotting, it gets a ticket number. Lowest ticket
	 ' goes first in case of multiple spots. This can optionally be delayed until
	 ' the end of an inning, or if there are no more object balls
	 '/
	SpotTicket as byte
	DelaySpotting as byte
	
	TrailX(50) as double 'Attention to detail
	TrailY(50) as double

	WallBounce as byte
end type

type CursorSpecs
	ErrNum as integer
	BX as integer
	BY as integer
	X as double
	Y as double
	Buttons as integer
	HoldPress as byte
	Loaded as byte
end type

type RackSpecs
	X as double
	Y as double
	Used as byte
	Restricted as byte
end type

type PlrSpecs
	CasualScore as short
	PrevCasual as short
	MoneyScore as short
	FoulCombo as byte
	GroupAssigned as byte
	Pocketed(15) as byte
end type

enum GameCollection
	GAME_TRAINING = -5
	GAME_9BALL_SOLO
	GAME_15BALL_SOLO
	GAME_8BALL_SOLO
	GAME_CRIBBAGE_SOLO
	GAME_STRAIGHT_POOL_SOLO
	GAME_9BALL
	GAME_10BALL
	GAME_6BALL
	GAME_15BALL
	GAME_ROTATION
	GAME_8BALL
	GAME_CUTTHROAT
	GAME_7BALL
	GAME_1POCKET
	GAME_CRIBBAGE
	GAME_STRAIGHT_POOL
	GAME_MAX
end enum

dim shared as double FrameTime, TickUpdate, ExertForce, TotalE, TotalV, Claimed(3)
dim shared as integer DWidth, DHeight, SWidth, SHeight
dim shared as longint KitchenPattern
dim shared as integer BoxGlow, TrailCount, Ticker, ShotClock, MaxShot, MachineBest, SessionBest
dim shared as ushort NumPlayers, FramesRecorded, ActualFPS
dim shared as byte TurnDing, TopChosen, RivalInterrupt, Unloading, Player, PlayState, GameOver, Stationary, Fouled, _
	SelectedBall, MoneyBall, ProperHit, InitialHits, InitialQuota, InitialCue, CueRailReq, _
	CalledPocket, RestrictedPlace, PhysicsAids, PhysicsDisp, Submenu, ObjsNPlay, _
	DebugCapture, MustScoreCribbage, MustCrossString, UseRuleset, QuickReset, NoSnapping, Victor
dim shared as string InType, NullStr, DispString, GameCode, GameName(GAME_MAX)
dim shared as Sphere Ball(15), GhostAid
dim shared as RackSpecs RackSlot(24)
dim shared as PlrSpecs PlayerSlot(3)
dim shared as CursorSpecs Mouse(1)
dim shared as any ptr Table, BallPic(15), Cursor, FrameBig, FrameSm, ShotPic, Background, AidMarkings

'Table variables, based on screen resolution
dim shared as integer PaddingX, PaddingY, BaseX, BaseY, LeftBorder, RightBorder, SidePockets, TopBorder, BottomBorder, LongString, FootString, HeadString

declare sub menu

const TitleName = "Physics Pool"

GameName(0) = "None"
GameName(GAME_8BALL) = "Eight Ball"
GameName(GAME_9BALL) = "Nine Ball"
GameName(GAME_10BALL) = "Ten Ball"
GameName(GAME_6BALL) = "Six Ball"
GameName(GAME_15BALL) = "Fifteen Ball"
GameName(GAME_ROTATION) = "Rotation"
GameName(GAME_7BALL) = "Seven Ball"
GameName(GAME_1POCKET) = "One Pocket"
GameName(GAME_CUTTHROAT) = "Cutthroat"
GameName(GAME_CRIBBAGE) = "Cribbage"
GameName(GAME_STRAIGHT_POOL) = "Straight Pool"

enum StateCollection
	STATE_NORMAL
	STATE_FOULED
	STATE_RECOVERED
	STATE_BREAK
	STATE_ILLEGAL_BREAK
	STATE_DECISION
	STATE_OVER
end enum

enum SuitCollection
	'Eight-ball suits
	SUIT_SOLIDS = 1
	SUIT_STRIPES
	'Cutthroat suits
	SUIT_LOW = 1
	SUIT_MID
	SUIT_HIGH
end enum

'Some physics constants
const Diameter = 19
const friction = .125
const elasticity = .99
const MinSpeed = 1

'Engine-based constants
const Adjust = 20 * cos(30*pi/180)
const basedist = 140
const InternalUpdateRate = 200
const FrameRate = 60

'Important keybnoard shortcuts
const EscKey = chr(27)
const XBox = chr(255,107)

'Rack positions and other key positions
enum RackPositions
	RACK_CENTER = 11
	RACK_FOOT = 15
	SPECIAL_CENTER
	SPECIAL_HEAD
	RACK_OFFSET
end enum

sub applyScreenresSpecs
	dim as byte UseX = 1, UseY = 1

	PaddingX = (SWidth - 888) / 2
	PaddingY = (SHeight - 566) / 2
	BaseX = 0 + PaddingX
	BaseY = 60 + PaddingY 
	LeftBorder = 44 + BaseX
	RightBorder = LeftBorder + 800
	SidePockets = LeftBorder + 400
	TopBorder = 44 + BaseY
	BottomBorder = TopBorder + 400
	LongString = TopBorder + 200
	FootString = LeftBorder + 200
	HeadString = RightBorder - 200

	for RackPos as byte = 1 to 15
		with RackSlot(RackPos)
			.X = BaseX + basedist + ((UseX + 1) * Adjust)
			.Y = 244 + BaseY + ((UseY - 3) * Diameter) + ((UseX-1)/2 * Diameter)
		end with
		
		UseY += 1
		if UseY > 6 - UseX then
			UseX += 1
			UseY = 1
		end if
	next RackPos
	
	with RackSlot(SPECIAL_CENTER)
		.X = BaseX + (RightBorder - LeftBorder) / 2
		.Y = RackSlot(RACK_FOOT).Y
	end with
	with RackSlot(SPECIAL_HEAD)
		.X = HeadString 
		.Y = RackSlot(RACK_FOOT).Y
	end with
	
	RackSlot(RACK_OFFSET) = RackSlot(RACK_FOOT)
	
	UseX = 1
	UseY = 1

	for RackPos as byte = RACK_OFFSET + 1 to RACK_OFFSET + 6
		with RackSlot(RackPos)
			.X = RackSlot(RACK_OFFSET).X + Adjust/2 * (UseY mod 2) - UseX * Diameter  
			.Y = RackSlot(RACK_OFFSET).Y + (UseY - 2) * Adjust
		end with
		
		UseX += 1
		if UseX > 2 then
			UseY += 1
			UseX = 1
		end if
	next RackPos
end sub

sub setupSpecs constructor
	Mouse(0).Loaded = -1
	
	SoundVolume = 100
	PhysicsAids = 3
	
	open "ppool.ini" for input as #1
	do
		input #1, NullStr
		
		select case NullStr
			case "width"
				input #1, SWidth
			case "height"
				input #1, SHeight
			case "shotclock"
				input #1, MaxShot
			case "nosnapping"
				input #1, NoSnapping
			case "physics"
				input #1, PhysicsDisp
			case "soundfx"
				input #1, SoundVolume
			case "aids"
				input #1, PhysicsAids
		end select
	loop until eof(1)
	close #1
	
	applyScreenresSpecs
end sub

function dispThousandths(Amt as double) as string
	return left(str(Amt),len(str(int(Amt)))+4)
end function

sub drawBox(StartX as short,StartY as short,EndX as short,EndY as short)
	BoxGlow -= 8
	if BoxGlow <= -128 then
		BoxGlow += 255
	end if

	dim as uinteger DrawColor
	dim as short PaintStr
	
	for BID as short = 0 to 4
		PaintStr = BoxGlow - (BID*24)
		while PaintStr <= -128
			PaintStr += 255
		wend
		DrawColor = rgba(0,0,64,128+abs(PaintStr))
		
		line(StartX+BID,StartY+BID)-(EndX-BID,StartY+BID),DrawColor
		line(StartX+BID,StartY+BID+1)-(StartX+BID,EndY-BID),DrawColor
		line(EndX-BID,StartY+BID+1)-(EndX-BID,EndY-BID),DrawColor
		line(StartX+BID+1,EndY-BID)-(EndX-BID-1,EndY-BID),DrawColor
	next BID
end sub

sub cleanUp destructor
	open "ppool.ini" for output as #1
	print #1, "width,"& SWidth
	print #1, "height,"& SHeight
	print #1, "shotclock,"& MaxShot
	print #1, "nosnapping,"& NoSnapping
	print #1, "physics,"& PhysicsDisp
	print #1, "soundfx,"& SoundVolume
	print #1, "aids,"& PhysicsAids
	close #1

	for PID as ubyte = 0 to 15
		ImageDestroy(BallPic(PID))
	next PID
	ImageDestroy(Table)
	ImageDestroy(Cursor)
	ImageDestroy(FrameBig)
	ImageDestroy(FrameSm)
	ImageDestroy(Background)
	ImageDestroy(ShotPic)
	ImageDestroy(AidMarkings)
end sub

sub dispMouse
	with Mouse(0)
		if .ErrNum = 0 then
			.X = .BX
			.Y = .BY
			
			if .Loaded > 0 AND .Loaded <= 15 AND NoSnapping = 0 then
				for RID as byte = 1 to 15
					if sqr(abs(.X - RackSlot(RID).X)^2 + abs(.Y - RackSlot(RID).Y)^2) < 9 then
						.X = RackSlot(RID).X
						.Y = RackSlot(RID).Y
					end if
				next RID
			end if
			
			put (.X,.Y),Cursor,trans
			if .Loaded >= 0 AND .Loaded <= 15 then
				put (.X+25,.Y+25),BallPic(.Loaded),alpha,128
			end if
		end if
	end with
end sub

function randomDistribution as byte
	dim as byte TestSlot
	do
		TestSlot = irandom(1,15)
	loop until RackSlot(TestSlot).Used = 0
	
	return TestSlot
end function

declare sub assignCutSuit(PlayerNum as byte, SuitID as byte)

sub newRack(GameType as byte = 0, NewGame as byte = -1)
	'Starts a new game, and creates a new rack
	dim as byte XID, YID, UseSlot
	dim as single StartLoop, CurTime

	FrameTime = timer
	for PID as ubyte = 1 to 3
		with PlayerSlot(PID)
			Claimed(PID) = 0
			.CasualScore = 0
			.PrevCasual = 0
			.MoneyScore = 0
			.FoulCombo = 0
			.GroupAssigned = 0
			for BID as ubyte = 1 to 15
				.Pocketed(BID) = 0
			next BID
		end with
	next
	ShotClock = MaxShot*FrameRate
	TopChosen = 0
	InitialHits = 0
	InitialQuota = 2
	InitialCue = 0
	CueRailReq = 0
	Stationary = 0
	MustScoreCribbage = 0
	SessionBest = 0
	UseRuleset = GameType
	PlayState = STATE_BREAK
	select case UseRuleset
		case GAME_TRAINING
			NumPlayers = 1
		case GAME_9BALL_SOLO
			NumPlayers = 1
			UseRuleset = GAME_9BALL
			exit select
		case GAME_15BALL_SOLO
			NumPlayers = 1
			UseRuleset = GAME_15BALL
			exit select
		case GAME_8BALL_SOLO
			NumPlayers = 1
			UseRuleset = GAME_8BALL
			exit select
		case GAME_CRIBBAGE_SOLO
			NumPlayers = 1
			UseRuleset = GAME_CRIBBAGE
			exit select
		case GAME_STRAIGHT_POOL_SOLO
			NumPlayers = 1
			UseRuleset = GAME_STRAIGHT_POOL
			exit select
		case GAME_9BALL, GAME_10BALL, GAME_6BALL, GAME_15BALL, GAME_ROTATION
			PlayState = STATE_DECISION
			if NewGame then
				NumPlayers = 0
			end if
		case GAME_8BALL, GAME_7BALL, GAME_CRIBBAGE, GAME_STRAIGHT_POOL
			NumPlayers = 2
		case GAME_CUTTHROAT
			NumPlayers = 3
		case GAME_1POCKET
			PlayState = STATE_DECISION
			NumPlayers = 2
	end select
	if NewGame then
		Player = irandom(1,NumPlayers)
	end if
	Victor = 0
	Fouled = 0
	ProperHit = 0
	GameOver = 0
	Mouse(0).Loaded = 0
	for BID as ubyte = 0 to 15
		with Ball(BID)
			if BID > 0 then
				.Namee = str(BID)+"-ball"
			else
				.Namee = "Cue Ball"
			end if
			.Speed = 0
			.Angle = 0
			.Speed = 0
			.SpeedX = 0
			.SpeedY = 0
			.Mass = 167
			.Alive = 0
			.WallBounce = 0
		end with
		RackSlot(BID).Used = 0
		RackSlot(BID).Restricted = 0
	next BID
	if GameType = GAME_TRAINING then
		UseRuleset = QuickReset
	end if
	select case UseRuleset
		case GAME_8BALL
			RackSlot(RACK_CENTER).Used = 1
			StartLoop = timer
			InitialQuota = 4
			MoneyBall = 8
			
			for NewBall as byte = 1 to 15
				CurTime = timer - StartLoop
				
				if CurTime > 0.5 then
					'Sometimes the simulation fails to establish a valid rack. Restart if this is the case
					newRack(GameType)
					exit sub
				end if
				
				select case Newball
					case 8
						'Force 8-ball in the center
						UseSlot = RACK_CENTER
					case else
						UseSlot = randomDistribution
				end select
				
				'The vertices opposite the foot spot must have opposite suits
				if UseSlot = 1 OR UseSlot = 5 then
					dim as byte AltSlot = 6 - UseSlot
					
					if RackSlot(UseSlot).Restricted = 0 then
						RackSlot(AltSlot).Restricted = 1
					elseif (RackSlot(AltSlot).Used < 8 AND NewBall < 8) OR _
						(RackSlot(AltSlot).Used > 8 AND NewBall > 8) then
						NewBall -= 1
						continue for
					end if
				end if
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
		case GAME_9BALL
			for RID as byte = 1 to 6
				if RID <> 3 then
					RackSlot(RID).Used = 1
				end if
			next RID
			RackSlot(9).Used = 1
			RackSlot(RACK_CENTER).Used = 1
			RackSlot(RACK_FOOT).Used = 1
			MoneyBall = 9
			
			for NewBall as byte = 1 to 9
				select case Newball
					case 1
						'Force 1-ball on foot spot (makes it easy to perform a legal shot)
						UseSlot = RACK_FOOT
					case 9
						'Force 9-ball in center
						UseSlot = RACK_CENTER
					case else
						'Distribute other object balls randomly
						UseSlot = randomDistribution
				end select
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
		case GAME_10BALL
			for RID as byte = 1 to 5
				RackSlot(RID).Used = 1
			next RID
			RackSlot(RACK_CENTER).Used = 1
			RackSlot(RACK_FOOT).Used = 1
			MoneyBall = 10
			
			for NewBall as byte = 1 to 10
				select case Newball
					case 1
						'Force 1-ball on foot spot (makes it easy to perform a legal shot)
						UseSlot = RACK_FOOT
					case 10
						'Force 10-ball in center
						UseSlot = RACK_CENTER
					case else
						'Distribute other object balls randomly
						UseSlot = randomDistribution
				end select
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
		case GAME_6BALL
			for RID as byte = 1 to 9
				RackSlot(RID).Used = 1
			next RID
			RackSlot(RACK_CENTER).Used = 1
			RackSlot(RACK_FOOT).Used = 1
			MoneyBall = 6
			
			for NewBall as byte = 1 to 6
				select case Newball
					case 1
						'Force 1-ball on foot spot (makes it easy to perform a legal shot)
						UseSlot = RACK_FOOT
					case 6
						'Force 6-ball in center
						UseSlot = RACK_CENTER
					case else
						'Distribute other object balls randomly
						UseSlot = randomDistribution
				end select
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
			
		case GAME_15BALL
			RackSlot(RACK_FOOT).Used = 1
			CueRailReq = 1
			
			for NewBall as byte = 1 to 15
				select case Newball
					case 15
						'Force 15-ball on the foot spot
						UseSlot = RACK_FOOT
					case else
						UseSlot = randomDistribution
				end select
				
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
		case GAME_ROTATION
			RackSlot(1).Used = 1
			RackSlot(5).Used = 1
			RackSlot(RACK_CENTER).Used = 1
			RackSlot(RACK_FOOT).Used = 1
			CueRailReq = 1
			
			for NewBall as byte = 1 to 15
				select case Newball
					case 1
						'Force 1-ball on the foot spot
						UseSlot = RACK_FOOT
					case 2
						'Force 2-ball in the far left corner (relative to head)
						UseSlot = 5
					case 3
						'Force 3-ball in the far right corner (relative to head)
						UseSlot = 1
					case 15
						'Force fifteen ball in the center
						UseSlot = RACK_CENTER
					case else
						UseSlot = randomDistribution
				end select
				
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
		case GAME_CUTTHROAT
			dim as byte FirstCorner
			RackSlot(1).Used = 1
			RackSlot(5).Used = 1
			RackSlot(RACK_FOOT).Used = 1
			
			for NewBall as byte = 1 to 15
				select case Newball
					case 1
						'Force the one ball on the foot spot
						UseSlot = RACK_FOOT
					case 6
						'Force the six ball on one of the other corners
						FirstCorner = irandom(1,2)
						if FirstCorner > 1 then
							FirstCorner = 5
						end if
						UseSlot = FirstCorner
					case 11
						'The eleven ball is placed on the left-ovder corner
						UseSlot = 6 - FirstCorner
					case else
						'Distribute other object balls randomly
						UseSlot = randomDistribution
				end select
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
			PlayerSlot(1).GroupAssigned = 0
			PlayerSlot(2).GroupAssigned = 0
			PlayerSlot(3).GroupAssigned = 0
			
			for PID as byte = 1 to 3
				with PlayerSlot(PID)
					.CasualScore = 5
					
					if PID = 1 then
						assignCutSuit(PID, irandom(1,3))
					elseif PID = 2 then
						dim as byte NewSuit
						do
							NewSuit = irandom(1,3)
						loop until NewSuit <> PlayerSlot(1).GroupAssigned
						
						assignCutSuit(PID, NewSuit)
					end if
				end with
			next PID
			
		case GAME_7BALL
			MoneyBall = 7
			dim as byte FixedAlignment(1 to 7) => {0, 5, 6, 4, 1, 2, 3}
			
			for BID as byte = 1 to 7
				with Ball(BID)
					.X = RackSlot(RACK_OFFSET + FixedAlignment(BID)).X
					.Y = RackSlot(RACK_OFFSET + FixedAlignment(BID)).Y
					
					.WallBounce = 0
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
			next BID
			
		case GAME_1POCKET
			CueRailReq = 1
			for NewBall as byte = 1 to 15
				'Distribute all object balls randomly
				UseSlot = randomDistribution
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.WallBounce = 0
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
		case GAME_STRAIGHT_POOL
			RackSlot(1).Used = 1
			RackSlot(5).Used = 1
			CueRailReq = 1
			
			for NewBall as byte = 1 to 15
				select case Newball
					case 1, 5
						'Force the one and five balls on vertices opposite the foot spot
						UseSlot = 6 - NewBall
					case else
						'Distribute other object balls randomly
						UseSlot = randomDistribution
				end select
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
			
		case GAME_CRIBBAGE
			RackSlot(RACK_CENTER).Used = 1
			StartLoop = timer
			InitialQuota = 4
			MoneyBall = 15
			
			for NewBall as byte = 1 to 15
				CurTime = timer - StartLoop
				
				if CurTime > 0.5 then
					'Sometimes the simulation fails to establish a valid rack. Restart if this is the case
					newRack(GameType)
					exit sub
				end if
				
				select case Newball
					case 15
						'Force 15-ball in the center
						UseSlot = RACK_CENTER
					case else
						UseSlot = randomDistribution
				end select
				
				'The vertices opposite the foot spot must have opposite suits
				if UseSlot = 1 OR UseSlot = 5 OR UseSlot = RACK_FOOT then
					if NewBall + RackSlot(1).Used = 15 OR NewBall + RackSlot(5).Used = 15 OR _
						NewBall + RackSlot(RACK_FOOT).Used = 15 then
						NewBall -= 1
						continue for
					end if
				end if
					
				with Ball(NewBall)
					.X = RackSlot(UseSlot).X
					.Y = RackSlot(UseSlot).Y
					.Speed = 0
					.Angle = 0
					.Alive = 1
					.Mass = 167
				end with
				RackSlot(UseSlot).Used = NewBall
			next NewBall
	end select
	if GameType = GAME_TRAINING then
		PlayerSlot(1).CasualScore = 0
		UseRuleset = GAME_TRAINING
	end if
end sub

sub playerFrameSm(XPos as short, PlayerNum as byte)
	dim as short ShiftCounter, PocketRef
	dim as string PlrStr, ScoreStr, FoulStr
	
	with PlayerSlot(PlayerNum)
		put(XPos,5),FrameSm,pset
		if PlayerNum = Player then
			drawBox(XPos-5,0,XPos+258,59)
		end if
		PlrStr = str(PlayerNum)+"P"
		if UseRuleset = GAME_7BALL OR UseRuleset = GAME_1POCKET then
			if TopChosen = PlayerNum then
				PlrStr = "Top"
			elseif TopChosen = 3 - PlayerNum then
				PlrStr = "Btm"
			end if
		end if
		gfxstring(PlrStr,XPos+128-len(PlrStr)*7,8,4,4,2,rgb(255,255,255))

		for SID as byte = 15 to 1 step -1
			if .Pocketed(SID) > 0 then
				ShiftCounter = SID - 10
				exit for
			end if
		next SID
		
		if ShiftCounter < 0 then
			ShiftCounter = 0
		end if
		
		for BID as ubyte = 1 to 10
			PocketRef = BID + ShiftCounter
			
			if .Pocketed(PocketRef) > 0 then
				put(XPos+5+(BID-1)*25,32),BallPic(.Pocketed(PocketRef)),trans
			elseif .CasualScore <= -1 * BID then
				put(XPos+5+(BID-1)*25,32),BallPic(0),alpha,128
			end if
		next BID

		if UseRuleset = GAME_15BALL OR UseRuleset = GAME_ROTATION OR UseRuleset = GAME_CRIBBAGE OR UseRuleset = GAME_STRAIGHT_POOL then
			if len(str(.MoneyScore)) > 2 then
				ScoreStr = "Sc:"+str(.MoneyScore)
			elseif len(str(.MoneyScore)) > 1 then
				ScoreStr = "Sc: "+str(.MoneyScore)
			else
				ScoreStr = "Sc: 0"+str(.MoneyScore)
			end if
		else
			if len(str(.CasualScore)) > 1 then
				ScoreStr = "Sc: "+str(.CasualScore)
			else
				ScoreStr = "Sc: 0"+str(.CasualScore)
			end if
		end if
		gfxstring(ScoreStr,XPos+9,8,4,3,2,rgb(255,255,255))

		if .FoulCombo > 9 then
			FoulStr = "Fouls: +"
		else
			FoulStr = "Fouls: "+str(.FoulCombo)
		end if
		gfxstring(FoulStr,XPos+172,8,4,2,2,rgb(255,128,128))
	end with
end sub

sub saveScores(File as string)
	open File+".hs" for output as #7
	print #7, ""& MachineBest
	close #7
end sub

sub loadScores(File as string)
	if FileExists(File+".hs") then
		open File+".hs" for input as #13
		input #13, MachineBest
		close #13
	else
		MachineBest = 0
	end if
end sub

function getTimeStr(Value as integer) as string
	if Value <= 0 then
		return " :00"
	elseif Value < 10 then
		return " :0"+str(Value)
	elseif Value < 60 then
		return " :"+str(Value)
	else
		if Value mod 60 < 10 then
			return str(int(Value/60))+":0"+str(Value mod 60)
		else
			return str(int(Value/60))+":"+str(Value mod 60)
		end if
	end if
		
	return ""
end function

'Shot clock
sub shotClockDisp(XPos as short, YPos as short = 5)
	dim as uinteger DigitsClr
	dim as short SecondsWorth
	dim as single FracRemain 
	dim as string TimeRem
	
	FracRemain = ShotClock / (MaxShot * FrameRate)
	
	for DID as ubyte = 4 to 32
		if FracRemain < 2 / DID AND MaxShot > 0 then
			Ticker += 1
		end if
	next DID
	Ticker += 8
	if Ticker > 255 then
		Ticker = -255
	elseif Ticker > -128 AND Ticker < 128 AND 0 then
		Ticker = 128
	end if

	if MaxShot > 0 then
		put(XPos,YPos),ShotPic,pset
		TimeRem = getTimeStr(ceil(ShotClock/FrameRate))
		
		if ShotClock < 10*FrameRate then
			DigitsClr = rgb(255,127+abs(Ticker/2),127+abs(Ticker/2))
		else
			DigitsClr = rgb(abs(Ticker),255,abs(Ticker))
		end if
		gfxstring(TimeRem,XPos+11,YPos+3,4,4,2,DigitsClr)
	end if
end sub

'Blocks a ticket from being assigned to two different balls
function duplicateTickets as byte
	dim as byte DuplicateFound = 0
	
	for XID as byte = 0 to 14
		for YID as byte = XID + 1 to 15
			if Ball(XID).SpotTicket = Ball(YID).SpotTicket AND Ball(XID).SpotTicket > 0 then
				DuplicateFound = 1
				exit for,for
			end if
		next YID
	next XID
	
	return DuplicateFound
end function

'Queues a ball for spotting
sub spotBall(Billiard as byte, Delayed as byte = 0)
	with Ball(Billiard)
		do
			.SpotTicket = irandom(1,127)
		loop until duplicateTickets = 0
		.DelaySpotting = Delayed
	end with
	if Delayed = 0 then
		ObjsNPlay += 1
	end if
end sub

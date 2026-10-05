enum SoundFX
	SFX_TURN = 0
	SFX_CUE
	SFX_BALL
	SFX_WALL
	SFX_POCKET
	SFX_FOUL
	SFX_MAX
end enum

/'
SDL add-on

Libraries needed (5):
* SDL
* SDL_mixer
* LibOGG
* LibVorbis
* LibVorbisFile
'/

dim shared as double LastVolume
dim shared as ubyte MusicActive
dim shared as short SoundVolume, MusicLoaded = 0
const clipCount = SFX_MAX - 1
#include "SDL\SDL.bi"
#include "SDL\SDL_mixer.bi"
dim shared as Mix_Chunk ptr clip(clipCount)
dim shared as integer clipChannel(clipCount), clipPause(clipCount)
dim shared music as Mix_Music ptr
dim as string SFXNames(clipCount)
for CID as ubyte = 0 to clipCount
	clip(CID) = NULL
	clipChannel(CID) = -1
next CID
dim video as SDL_Surface ptr
dim event as SDL_Event
dim audio_rate as integer
dim audio_format as Uint16
dim audio_channels as integer
dim audio_buffers as integer
audio_rate = 44100
audio_format = AUDIO_S16
audio_channels = 2
audio_buffers = 4096/2
SDL_Init(SDL_INIT_AUDIO)
if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) then
	open "stderr.txt" for output as #1
	print #1, "Unable to open audio!"
	close #1
	end 1
end if

Mix_QuerySpec(@audio_rate, @audio_format, @audio_channels)

SFXNames(SFX_TURN) = "turn"
SFXNames(SFX_CUE) = "cue"
SFXNames(SFX_BALL) = "ball"
SFXNames(SFX_WALL) = "wall"
SFXNames(SFX_POCKET) = "pocket"
SFXNames(SFX_FOUL) = "foul"

for PID as short = 0 to clipCount
	clip(PID) = Mix_LoadWAV("sfx/"+SFXNames(PID)+".wav")
next PID
music = NULL

sub playClip(ID as byte, Amplitude as short = 128)
	if ID >= 0 then
		if clipPause(ID) = 0 then
			Mix_VolumeChunk(clip(ID), int(min(Amplitude, 128) * SoundVolume / 100))
			
			clipChannel(ID) = Mix_PlayChannel(-1, clip(ID), 0)
		end if
	end if
end sub
sub cleanSDL destructor
	Mix_CloseAudio
	SDL_Quit
end sub

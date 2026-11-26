extends RefCounted

# Original eight-bar adventure theme, rendered as a layered stereo score.
const RATE := 22050
const BEAT := 0.64
const BARS := 80
const CHORDS := [[50,57,62,65],[46,53,58,62],[53,60,65,69],[48,55,60,64],[50,57,62,65],[46,53,58,62],[43,55,58,62],[45,52,57,61]]
const MELODY := [[69,72,74,77,76,74],[72,70,69,65,67,69],[69,72,77,81,79,77],[76,74,72,67,69,72],[74,77,81,84,81,77],[77,74,72,70,69,65],[67,70,74,77,74,70],[69,73,76,81,76,73]]
const STARTS := [0.0,0.75,1.5,2.5,3.0,3.5]
const LENGTHS := [0.72,0.72,0.95,0.48,0.48,0.48]

static func hz(note: int) -> float:
	return 440.0*pow(2.0,float(note-69)/12.0)

static func voice(buffer: PackedFloat32Array,note: int,start: float,duration: float,volume: float,pan: float,kind: int) -> void:
	var frequency := hz(note)
	var frames := buffer.size()/2
	var offset := int(start*RATE)
	var release := 0.65 if kind==0 else 0.28
	var count := int((duration+release)*RATE)
	var left := sqrt((1.0-pan)*0.5)
	var right := sqrt((1.0+pan)*0.5)
	for i in range(count):
		var t := float(i)/RATE
		var phase := TAU*frequency*t
		var envelope := minf(t/(0.32 if kind==0 else 0.045),1.0)*exp(-maxf(0.0,t-duration)/(release*0.26))
		var wave := 0.0
		match kind:
			0: # warm bowed ensemble with gentle detuning
				wave = (sin(phase*0.997)+sin(phase*1.003))*0.32+sin(phase*2.0)*0.19+sin(phase*3.0)*0.09
				wave *= 0.88+0.12*sin(TAU*4.1*t)
			1: # breathy woodwind melody
				var vibrato := 0.12*sin(TAU*5.2*t)*minf(t*2,1.0)
				wave = sin(phase+vibrato)*0.78+sin(phase*2+vibrato)*0.16+sin(phase*3)*0.06
			2: # plucked harp
				envelope *= exp(-t*3.5)
				wave = sin(phase)*0.58+sin(phase*2)*0.24+sin(phase*3)*0.12+sin(phase*5)*0.06
			3: # soft low orchestral pulse
				envelope *= exp(-t*8)
				wave = sin(TAU*(frequency*t+1.8*(1.0-exp(-t*18))))*0.85+sin(phase*1.49)*0.15
			4: # broad brass-like harmonic voice
				wave = sin(phase)*0.48+sin(phase*2)*0.25+sin(phase*3)*0.15+sin(phase*4)*0.08
				wave *= minf(t*8,1.0)
		var sample := wave*envelope*volume
		var index := ((offset+i)%int(frames))*2
		buffer[index] += sample*left
		buffer[index+1] += sample*right

static func render(style: int = 0) -> AudioStreamWAV:
	var bars := BARS if style==0 else 16
	var beat := BEAT if style==0 else 0.43 if style==1 else 0.36
	var frames := int(float(bars)*4*beat*RATE)
	var buffer := PackedFloat32Array()
	buffer.resize(frames*2)
	for bar in range(bars):
		var start := float(bar)*4*beat
		var section := int(bar/8)%5
		var motif := bar%8
		var chord: Array = CHORDS[motif]
		for j in range(4):
			voice(buffer,int(chord[j]),start,4*beat,0.055,float(j-1)*0.28,0)
		voice(buffer,int(chord[0])-12,start,4*beat,0.075,0.0,0)
		for j in range(8):
			voice(buffer,int(chord[j%4])+12,start+float(j)*beat*0.5,beat*0.65,0.045,-0.55,2)
		for j in range(6):
			voice(buffer,int(MELODY[motif][j])+(12 if section==3 else -12 if section==1 else 0),start+float(STARTS[j])*beat,float(LENGTHS[j])*beat,(0.08 if section==1 else 0.13),0.18,1)
		voice(buffer,36,start,0.18,0.09,0.0,3)
		voice(buffer,36,start+2*beat,0.18,0.065,0.0,3)
		if style>0 or section==3:
			for j in range(4):
				voice(buffer,int(chord[j])+12,start+float(j)*beat,beat*0.85,0.07,0.4,4)
				voice(buffer,36,start+float(j)*beat,0.15,0.12 if style==2 else 0.07,0,3)
	var bytes := PackedByteArray()
	bytes.resize(frames*4)
	var delay := int(0.17*RATE)*2
	for i in range(frames*2):
		var echo := buffer[posmod(i-delay,frames*2)]*0.16+buffer[posmod(i-delay*2,frames*2)]*0.08
		bytes.encode_s16(i*2,int(clampf((buffer[i]+echo)*1.45,-0.95,0.95)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	return stream

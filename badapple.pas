
//
// BADAPPLE Loader (Tebe / Madteam)
// changes: 24.10.2018 ; 06.06.2025
//

uses crt, atari, sysutils, misc, highmem, graph, graphics, types;

{$r badapple.rc}

const
	frames = $110000;
	sample = $580000;

	pmgdata = $9800+$300;

	version = '1.83';

type
	TRLEAnim = packed record

	ChunkID,			// Contains the letters "RANM" in ASCII form

	ChunkSize: cardinal;		// This is the size of the
					// entire file in bytes minus 8 bytes
	end;


	TWave = packed record

	// The canonical WAVE format starts with the RIFF header:

	ChunkID,			// Contains the letters "RIFF" in ASCII form
					// (0x52494646 big-endian form).

	ChunkSize,			// 36 + SubChunk2Size, or more precisely:
					// 4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
					// This is the size of the rest of the chunk
					// following this number.  This is the size of the
					// entire file in bytes minus 8 bytes for the
					// two fields not included in this count:
					// ChunkID and ChunkSize.

	Format,				// Contains the letters "WAVE"
					// (0x57415645 big-endian form).

	// The "WAVE" format consists of two subchunks: "fmt " and "data":
	// The "fmt " subchunk describes the sound data's format:

	Subchunk1ID,			// Contains the letters "fmt "
					// (0x666d7420 big-endian form).

	Subchunk1Size: cardinal;	// 16 for PCM.  This is the size of the
					// rest of the Subchunk which follows this number.

	AudioFormat,			// PCM = 1 (i.e. Linear quantization)
					// Values other than 1 indicate some
					// form of compression.

	NumChannels: word;		// Mono = 1, Stereo = 2, etc.

	SampleRate,			// 8000, 44100, etc.

	ByteRate: cardinal;		// == SampleRate * NumChannels * BitsPerSample/8

	BlockAlign,			// == NumChannels * BitsPerSample/8
					// all channels. I wonder what happens when
					// The number of bytes for one sample including
					// this number isn't an integer?

	BitsPerSample: word;		// 8 bits = 8, 16 bits = 16, etc.
					// if PCM, then doesn't exist
					// space for extra parameters

	// The "data" subchunk contains the size of the data and the actual sound:

	Subchunk2ID,			// Contains the letters "data"
					// (0x64617461 big-endian form).

	Subchunk2Size: cardinal;	// == NumSamples * NumChannels * BitsPerSample/8
					// This is the number of bytes in the data.
					// You can also think of this as the size
					// of the read of the subchunk following this
					// number.

					// The actual sound data.
	end;

var
   hmem: THighMemoryStream;

   canvas: TCanvas;

   buf: array [0..$3e00-1] of byte absolute $5200;

   wav: TWave;
   anm: TRLEAnim;

   px, barsize: byte;
   py: word;

   rec: TRect;

   brush: TBrushBitmap;

   s: string;

   f: file;


procedure ClearScreen;
begin
 fillchar(@hposp0, 32, 0);

 clrscr;

 sdmctl:=ord(normal)+ord(enable);

 gprior:=$04;
end;


procedure LoadPart(fn: TString; ps: cardinal; part: byte);
var sx: byte;
    NumRead: word;
    Total, len: cardinal;


 procedure UnknownFile;
 begin
  ClearScreen;

  writeln('''',fn,'''', ', unknown file format');

  halt;
 end;


begin


if not FileExists(fn) then begin
  ClearScreen;

  writeln('File ''',fn,''' not found');
  halt;
 end;

 assign(f, fn);

 FileMode:=fmOpenRead;

 reset(f, 1);


 case part of

  1: begin
      blockread(f, anm, sizeof(anm));

      if anm.ChunkID <> $4d4e4152 then UnknownFile;

      len:=anm.ChunkSize;

     // writeln;
     // write('Video: ');

     end;

  2: begin
      blockread(f, wav, sizeof(wav));

      if wav.ChunkID <> $46464952 then UnknownFile;
      if wav.Format <> $45564157 then UnknownFile;
      if wav.Subchunk1ID <> $20746d66 then UnknownFile;

      len:=wav.ChunkSize-36;

      //write('Audio: ');

     end;

 end;

// x:=WhereX; y:=WhereY;

 hmem.position := ps;

 sx:=0;

 Total:=0;

 Repeat
    BlockRead (f,buf,Sizeof(buf), NumRead);

    hmem.WriteBuffer(buf, NumRead);

    inc(Total, NumRead);

    if part <> 0 then begin
     canvas.TextOut(px + sx,py,'|');
     sx:=trunc( (single(Total) / single(len) )*barsize);
    end;

 Until (NumRead=0) or (NumRead <> sizeof(buf));

 close(f);

 //writeln;

end;



procedure DetectHardware;
var	a: Boolean;
	p: word;
	cpu, passed: byte;

	speed: real;

procedure Status(b: Boolean; t: TString);
begin

 canvas.TextOut(px+6, py, s);

 if b then
  s:='Pass'
 else
  s:='Fail';

 canvas.TextOut(180, py, s);

 if not b then canvas.TextOut(220, py, t);

 inc(passed, ord(b));

end;

procedure Section(a: TString);
begin

 inc(py, 8);
 canvas.TextOut(px-canvas.TextWidth(a), py, a);

end;


begin

(*------------------ CPU  --------------------*)

 Section('CPU:');

 cpu:=DetectCPU;

 case cpu of
  0: s:='6502';
  1: s:='65c02';
 else
  s:='65816';
 end;

 a:=cpu > 127; Status(a, '65816');

(*----------------- Speed  -------------------*)

 Section('Speed:');

 speed:=DetectCPUSpeed;

 s:=concat(FloatToStr(speed), ' MHz');

 a:=speed > 12.0; Status(a, '12 MHz');

(*--------------- PAL / NTSC -----------------*)

 Section('Video:');

 case Pal of
   1: s:='PAL';
  15: s:='NTSC';
 else
  s:='UNKNOWN'
 end;

 a:=Pal=1; Status(a, 'PAL');

(*--------------- High memory ----------------*)

 Section('HighMem:');

 if cpu>127 then
  p:=(DetectHighMem and $00ff) shl 6
 else
  p:=0;

 s:=concat(IntToStr(p), ' KB');

 a:=p > 14336; Status(a, '15360 KB');

(*----------------- Stereo  ------------------*)

 Section('Stereo:');

 a:=DetectStereo;

 if a then
  s:='TRUE'
 else
  s:='FALSE';

 cpu:=passed;
 Status(not a, 'Switch to Mono');
 passed:=cpu;


 if passed<>4 then begin

  inc(py, 16);

  s:='System does not meet minimum requirements';
  canvas.TextOut((320 - canvas.TextWidth(s)) shr 1,py, s);

  for cpu:=0 to 31 do begin
	Click; Pause;
  end;

  repeat until keypressed;

  ClearScreen;

  halt;

 end;

end;


procedure doText(dy: byte; const s: TString);
begin

 inc(py, dy); canvas.TextOut(0, py, s);

end;


begin

 px:=90;
 py:=-8;

 InitGraph(8+16);

 color4:=0;

 color0:=0;
 color1:=0;
 color2:=14;
 color3:=6;

 canvas.create;

 canvas.brush.color:=1;
 canvas.pen.color:=0;

 rec:=Rect(0,0,319,191);
 canvas.FillRect(Rec);

 canvas.TextOut(292, 184, version);

 DetectHardware;

 pmbase:=hi(pmgData-$300);
 sdmctl:=ord(normal)+ord(missiles)+ord(players)+ord(oneline)+ord(enable);

 gprior:=$11;
 gractl:=3;

 sizep0:=3;
 sizep1:=3;
 sizep2:=3;
 sizep3:=3;

 sizem:=$ff;

 pcolr0:=10;
 pcolr1:=10;
 pcolr2:=10;
 pcolr3:=6;

 hposp0:=$43;
 hposp1:=$63;
 hposp2:=$83;
 hposp3:=$30;

 hposm0:=$65;
 hposm1:=$5B;
 hposm2:=$53;
 hposm3:=$4B;

 hmem.create;

 LoadPart('D:BADAPPLE.FNT', cardinal(@canvas.fdata), 0);
 canvas.FontInitialize;

 s:='BAD APPLE!!';
 inc(py, 16); canvas.TextOut((320-canvas.TextWidth(s)) shr 1, py, s);

 s:='SV2K18';

 inc(py, 12);

 canvas.brush.mode:=bmXor;

 rec:=Rect(0,py,319,py+6);
 canvas.FillRect(Rec);

 canvas.Pen.Color:=1;
 canvas.TextOut((320-canvas.TextWidth(s)) shr 1, py, s);

 rec:=Rect(134,py,184,py+6);
 canvas.FillRect(Rec);

 canvas.Pen.Color:=0;

 doText(16, 'CODE: TEBE');
 doText(9,  'SUPPORT: ROCKY');
 doText(12, 'ORIGINAL VIDEO BY ANIRA');
 doText(9,  'MUSIC BY M. MINOSHIMA');
 doText(9,  'VOCALS: NOMICO');
 doText(12, 'SOUND: POKEY 6-BIT 44KHZ');
 doText(9,  'GRAPHICS: ANTIC 160x240 4C 25FPS');

 s:='LOADING: ';
 px:=canvas.TextWidth(s);
 doText(16, s);

 brush[0]:=$55;
 brush[2]:=$55;
 brush[4]:=$55;
 brush[6]:=$55;

 brush[1]:=$aa;
 brush[3]:=$aa;
 brush[5]:=$aa;
 brush[7]:=$aa;

 canvas.brush.bitmap:=@brush;

 inc(px);

 rec:=Rect(px,py,px+166,py+7);
 canvas.FillRect(rec);

 rec:=Rect(px,py,px,py+8);

 barsize:=83;

 Canvas.Brush.Color:=0;

// repeat until keypressed;

 LoadPart('D:BADAPPLE.RLE', frames, 1);

 inc(px, barsize);

 LoadPart('D:BADAPPLE.WAV', sample, 2);
 LoadPart('D:BADAPPLE.EXO', $8000, 0);


 asm
 {	ldy #0
mv	lda .adr(move),y
	sta $0600,y
	iny
	bne mv
	jmp $0600

.local	move,$0600
	ldx #16
	ldy #0
src	lda $8000+6,y
dst	sta $2000,y
	iny
	bne src
	inc src+2
	inc dst+2
	dex
	bne src

	lda #0
	sta sdmctl
	sta dmactl

	ldx #$1f
	sta:rpl $d000,x-

	jmp $2000
.endl
  };

end.
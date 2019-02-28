// new module header
// Licence:
//
//   PALGorithms script module.
//   FADE & COLOR8 (C) Scavenger 2010-2011
//
//
//   CLUT Generation code (C) Steve McCrea
//   
//   CLUTTER Rendering uses code from CustomDialogGui AGS script module
//   Copyright (C) 2008 - 2010 Dirk Kreyenberg
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to 
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
#define REAL_PALETTE -1

enum PalBlockingStyle {
  ePalBlock, 
  ePalNoBlock
};

enum PalColourMode {
  ePalColour, 
  ePalHalfBrite
};
struct PALgorithms {
  
import static function ProcessPalette (int, int[]);
import static function Tint(char R, char G, char B, char p, int palstart=0, int palend=255);
import static function Fadeout(char R, char G, char B, char speed);
import static function Fadein (char R, char G, char B, char speed);
import static function GenerateCLUTForRoom ();
import static function SetRandomColour (char,  PalColourMode);
import static function CyclePaletteEx (int start, int end);
import static function DrawPalette (DynamicSprite* sprite, int size);
import static function FadeOutEx(int palnum, int r, int g, int b, float speed, int palstart=0, int palend=255);
import static function FadeInEx (int palnum, int r, int g, int b, float speed, int num=-1, int num2=-1, int amount=-1, int palstart=0, int palend=255);
import static function MultiplyPalette (int num, int r, int b, int g,int p, int palstart=0, int palend=255);
import static function InterpolatePalette (int targetnum, int num, int p, int palstart=0, int palend=255);
import static function InterpolateBetweenPalettes (int targetnum, int num,int num2,  int p, int palstart=0, int palend=255);
import static function BlankPalette(int num, char R, char G, char B, char p, int palstart=0, int palend=255);
import static function ThresholdPalette (int num, int p, int palstart=0, int palend=255);
};
import function SetTransparency (this Object*, char alpha, int mask=0,  BlendingMode blend=0);
import function ColouriseArea (this DynamicSprite*, int,  int,  int,  int);
import function CreateColourisedSprite (this DynamicSprite*,  int);
import function SetGraphic (this Object*,  int graphic);
import function CreateBackgroundSilhouette (this DynamicSprite*, int spriteslot, int x, int y);
import function BackupPalette ();

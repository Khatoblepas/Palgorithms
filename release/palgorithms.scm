AGSScriptModule    Scavenger 8-Bit Indexed Effects PALgorithms 0.01 �   /*****************************************            PALgorithms             ********************v0.01*/
//* A set of effects you can do with 8-Bit Colour Depth.                                                 *
//* Contains:                                                                                            *
//*           COLOR8 (A function for creating Discworld-style colourised areas)                          *
//*           CLUT Translucent Entity Rendering (CLUTTER): Translucent objects.                          *
//*           FADE (Full screen tinting and fading functions)                                            *
//*  Notes (COLOR8):                                                                                     *
//*       - Palindex must be arranged from darkest to lightest, with the darkest colour at palindex[0]   *
//*         This will continue until I implement a sorting algorithm. I don't understand them yet.       *
//*         Using a palette that isn't arranged this way is likely to crash the engine.                  *
//*        (CLUTTER):                                                                                    *
//*       - Uses Code written by SteveMcCrea. CLUT generation code is (c) SteveMcCrea 2010               *
//*       - Uses Background Buffer Rendering Code from Astauber's CustomDialogGui module.                *
 /*******************************************************************************************************/

 /******************            How to Use PALgorithms 
//*
//*  COLOR 8 FUNCTIONS
//* ProcessPalette (int palsiz, int palindex[])
//*   Creates a new colourisation palette and sets it to the current room palette. For instance, for a discworld inventory effect, you need
//*   a series of the colour blue, from lightest to darkest. here is the example. PALsiz would be 7, palindex would be bluearray:
//*      bluearray = new int [7];
//*      bluearray [0] = 46;
//*      bluearray [1] = 47;
//*      bluearray [2] = 48;
//*      bluearray [3] = 49;
//*      bluearray [4] = 50;
//*      bluearray [5] = 51;
//*      bluearray [6] = 52;
//*   While this can be declared in Game_Start, the game will crash horribly if Process_Palette is called before a room is loaded.
//*   Put it in On_event for before room fades in, and you'll get a colourisation palette you can use in every room.
//*   Multiple minipalettes at once aren't supported in this version, unfortunately. DO NOT sort these out of luminescience order, or
//*   freaky stuff happens.
//*   
//* ColouriseArea (this DynamicSprite*, int x1,  int y1,  int w,  int h);
//*   Places a colourised version of the selected area (x1,y1 are the top left coordinates, w+h are width and height) and places it inside
//*   the selected Dynamic Sprite. Useful for GUI backgrounds. WARNING: Generating a realtime colourised area that is too large may
//*   slow down your game!
//*   
//* CreateColourisedSprite (this DynamicSprite*,  int oldsprite);
//*   Creates a colourised version of a sprite (oldsprite is the ID of the sprite in question) and places it in the selected Dynamic Sprite.
//*   Palette Index 0 is ignored.
//*   
//*  FADE FUNCTIONS
//*   Tint(char R, char G, char B, char p);
//*    Tints the entire palette that particular RGB value, with an intensity of P. P is 0-63 in range. Leaving a room will restore the palette.
//*   
//*   Fadeout(char R, char G, char B, char speed);
//*    Fades out the entire palette to that RGB value, where P is the speed at which it happens. P is 0-63. 
//*   
//*   Fadein (char R, char G, char B, char speed);
//*    Fades out the entire palette from that RGB value, where P is the speed at which it happens. P is 0-63.
//*   
//*   
//*   CLUTTER FUNCTIONS
//*    Clutter is the most complex of the PALgorithms, since it requires being set up from outside the game. 
//*
//*   GenerateCLUTForRoom ();
//*    Generates a CLUT from the room's palette for 10 levels of transparency and saves it in CLUTROOMX.BMP, where X is the Room number.
//*    This takes an inordinately long time, and the game may appear to hang, but a display box will pop up when it is finished. It should
//*    take around 5 minutes for the generation to complete, so be patient. Once you have the image file, import it into AGS (exact palette import only, room specific)
//*    and make a new property for your room: TransCLUTSlot. Set that value to the sprite ID of the CLUT file, and you've finished setting up.
//*
//*   SetTransparency (this Object*, char alpha);
//*    Replaces Object.Transparency. Anything below 90 or above 10 will register on the renderer (I don't suggest breaking these bounds with
//*    a transparent sprite) and render it translucent. Values divisible by 10 are completely smoothly translucent, ones divisible by 5 are evenly
//*    dithered between the value +5 and the value -5. Values imbetween that are diffusion dithered, and will look like static.
//*    This is a limitation to keep down generation time and file sizes. 
//*
//*   SetGraphic (this Object*,  int graphic);
//*    Replaces Object.Graphic. Use this when you want to actually change a translucent sprites appearance for animation et al.
//*    Views for animated objects are not supported.
//*/





struct PALSTRUCT {
  char r;
  char b;
  char g;
};

PALSTRUCT backuppal[256];
PALSTRUCT RandomColours [2];
char randompalslot [2];
DynamicSprite *CLUTSPR;

//Colourise8 Global Variables
char _C8palgorithm [256];
char _C8PaletteMap [256];
bool _C8Init;

//CLUTTER Global Variables
int objecttransparent [];
int objecttruesprite  [];
int objecttranssprite [];
int objectblending    [];
int objectmask        [];

 /* The RGB color structure */
struct gfxRgb_t {
          char r;        /* Red color value */
          char g;        /* Green color value */
          char b;        /* Blue color value */
          char a;        /* Alignment byte (not used as an alpha) */
          };

     /* 256 color palette */
gfxRgb_t gfxPalette_t[256];
DynamicSprite *origspr [];
 /* The Color Look-Up Table (CLUT) structure. This can be used for
        alpha blending using color indirection (256 color modes). It can
        also be used for lighting and other special effects, but I haven't
        included that in this package. Perhaps another time =).
     */

struct gfxClut_t {
          char data[65536];     /* Pointer to CLUT color info. */
          };
          
gfxClut_t clut[9];

int AbsInt(int value) { //Returns the Absolute Value of value.
  if (value<0) {value=value*(-1);}
  return value;
}

int largest_digit (int n) 
{ 
int last, tmp; 

if (n<10) return n; 
last= n/10; 
tmp= largest_digit (n/10); 
if (last>tmp) tmp= last; 
return tmp; 
}

int smallest_digit (int n)
{
  int last, tmp;
  tmp = n%10;
  return tmp;
}

static function PALgorithms::DrawPalette (DynamicSprite* sprite, int size)
{
    sprite = DynamicSprite.Create (16, 16);
    int x = 0;
    int y = 0;
    DrawingSurface *surf = sprite.GetDrawingSurface ();
    int i = 0;
    while (y < 16)
    {
      while (x < 16)
      {
        surf.DrawingColor = i;
        surf.DrawPixel (x, y);
        x++;
        i++;
      }
      y++;
      x=0;
    }
    surf.Release ();
    sprite.Resize (size, size);
    //Then display test by any means you want.
}
     



/***********************************************************************
 * EXTENDER FUNCTION
 * DrawCharacter()
 *  
 * this function is called by DrawBackground
 ***********************************************************************/
function DrawCharacter(this DrawingSurface*, Character *theCharacter) {
  if (theCharacter == null) return;
  ViewFrame *frame = Game.GetViewFrame(theCharacter.View, theCharacter.Loop, theCharacter.Frame);
  DynamicSprite *sprite;
  int graphic = frame.Graphic;
  if (frame.Flipped) {
    sprite = DynamicSprite.CreateFromExistingSprite(graphic, true);
    sprite.Flip(eFlipLeftToRight);
  }
  if (theCharacter.Scaling != 100) {
    int scale = theCharacter.Scaling;
    if (sprite == null) sprite = DynamicSprite.CreateFromExistingSprite(graphic, true);
    sprite.Resize((Game.SpriteWidth[graphic] * scale) / 100, (Game.SpriteHeight[graphic] * scale) / 100);
  }
  Region *rat = Region.GetAtRoomXY(theCharacter.x, theCharacter.y);
  if ((rat != null) && (rat != region[0]) && (rat.TintEnabled)) {
    if (sprite == null) sprite = DynamicSprite.CreateFromExistingSprite(graphic, true);
    sprite.Tint(rat.TintRed, rat.TintGreen, rat.TintBlue, rat.TintSaturation, 100);
  }
  if (sprite != null) graphic = sprite.Graphic;
  this.DrawImage(theCharacter.x - (Game.SpriteWidth[graphic] / 2), theCharacter.y - Game.SpriteHeight[graphic] - theCharacter.z, graphic, theCharacter.Transparency);
  if (sprite != null) sprite.Delete();
}

/***********************************************************************
 * EXTENDER FUNCTION
 * DrawObject()
 * 
 * this function is called by DrawBackground
 ***********************************************************************/
function noloopcheck DrawObject(this DrawingSurface*, Object *theObject) {
  if ((theObject == null) || (!theObject.Graphic) || (!theObject.Visible)) return;
  DynamicSprite *sprite;
  int graphic;
  if (objecttransparent [theObject.ID] > 0 && objecttransparent [theObject.ID] < 256)
  {
    graphic = objecttruesprite [theObject.ID];
  }
  else graphic = theObject.Graphic;
  if (theObject.View) {
    ViewFrame *frame = Game.GetViewFrame(theObject.View, theObject.Loop, theObject.Frame);
    if (frame.Flipped) {
      sprite = DynamicSprite.CreateFromExistingSprite(frame.Graphic, true);
      sprite.Flip(eFlipLeftToRight);
    }
  }
  int scale = GetScalingAt(theObject.X, theObject.Y);
  if ((!theObject.IgnoreScaling) && (scale != 100)) {
    if (sprite == null) sprite = DynamicSprite.CreateFromExistingSprite(graphic, true);
    sprite.Resize((Game.SpriteWidth[graphic] * scale) / 100, (Game.SpriteHeight[graphic] * scale) / 100);
  }
  if (sprite != null) graphic = sprite.Graphic;
  if (objecttransparent [theObject.ID] > 0 && objecttransparent [theObject.ID] < 256)
  {
  int ox = theObject.X;
  int oy = theObject.Y - Game.SpriteHeight[graphic];
  //Display ("%d,%d,%d,%d,%d",theObject.ID, ox, oy, Game.SpriteWidth [graphic], Game.SpriteHeight [graphic]);
  int xoffset;
  if (ox < 0) xoffset = ox * (-1);
  if (ox > this.Width) xoffset = this.Width - ox;
  int yoffset;
  if (oy < 0) yoffset = oy * (-1);
  if (oy > this.Width) yoffset = this.Width - ox;
  
  DynamicSprite *bgcopy = DynamicSprite.CreateFromDrawingSurface (this, ox+xoffset, oy+yoffset, Game.SpriteWidth [graphic], Game.SpriteHeight [graphic]);
  if (xoffset != 0 || yoffset !=0)
  {
    DynamicSprite *bgcopy2 = DynamicSprite.Create (Game.SpriteWidth [graphic], Game.SpriteHeight[graphic]);
    DrawingSurface *surf = bgcopy2.GetDrawingSurface ();
    surf.DrawImage (xoffset, yoffset, bgcopy.Graphic);
    surf.Release ();
    bgcopy = DynamicSprite.CreateFromExistingSprite(bgcopy2.Graphic);
    bgcopy2.Delete ();
    
  }
  //DrawingSurface *Surface = bgcopy.GetDrawingSurface ();
  origspr[theObject.ID] = DynamicSprite.CreateFromExistingSprite (graphic);
  Translucence.DrawTransSprite (origspr[theObject.ID].Graphic, bgcopy.Graphic, objecttransparent[theObject.ID], objectmask[theObject.ID], objectblending[theObject.ID], 0);
  graphic = origspr[theObject.ID].Graphic;
  //DrawingSurface *OSSurface = origspr[theObject.ID].GetDrawingSurface ();
  //int i;
  //int j;
  //int sd = smallest_digit (objecttransparent[theObject.ID]);
  //int ld = largest_digit  (objecttransparent[theObject.ID]);
  //int OSpixel;
  //int BGpixel;
  /*while (j < origspr[theObject.ID].Height)
  {
    while (i < origspr[theObject.ID].Width)
    {
      OSpixel = OSSurface.GetPixel (i, j);
      if (OSpixel != COLOR_TRANSPARENT)
      {
      OSpixel = AbsInt (OSpixel); 
       BGpixel = AbsInt (Surface.GetPixel (i, j));
                if (objecttransparent[theObject.ID] > 90)
                {
                  
                  bool alternate = true;
                  if (alternate == false)
                  {

                            OSSurface.DrawingColor = clut [ld -1].data[(BGpixel << 8) + OSpixel];
                            OSSurface.DrawPixel (i, j);
                            alternate = true;
                  }
                  else if (alternate == true)
                  {
                    OSSurface.DrawingColor = OSpixel;
                    OSSurface.DrawPixel (i, j);
                    alternate = false;
                  }
                }
                else if (objecttransparent[theObject.ID] > 10) 
               {

                    if (Random (sd) < sd)
                        {
                                      OSSurface.DrawingColor = clut [ld].data[(BGpixel <<8) + OSpixel];
                                      OSSurface.DrawPixel (i, j);
                        }
                    else 
                        {
                
                                      OSSurface.DrawingColor = clut [ld-1].data[(BGpixel <<8) + OSpixel];
                                      OSSurface.DrawPixel (i, j);
                        }
               }
               else     {
                            if (Random (sd) < sd)
                            {
                  
                                            OSSurface.DrawingColor = clut [0].data[(BGpixel <<8) + OSpixel];
                                            OSSurface.DrawPixel (i, j);
                            }
                            else {
                                            OSSurface.DrawingColor = COLOR_TRANSPARENT;
                                            OSSurface.DrawPixel (i, j);
                                 }
                        }
      }
      i++;
    }
    i = 0;
    j++;
  } 
  Surface.Release ();
  OSSurface.Release ();
  */
  
  }
  this.DrawImage(theObject.X, theObject.Y - Game.SpriteHeight[graphic], graphic, theObject.Transparency);
  if (theObject.IgnoreScaling && objecttransparent [theObject.ID] > 0 && objecttransparent [theObject.ID] < 256) { theObject.Graphic = origspr[theObject.ID].Graphic; objecttranssprite[theObject.ID] = origspr[theObject.ID].Graphic; }
}








function BackupPalette () 
{
  int i;
  while (i <256)
  {
    backuppal[i].r = palette[i].r;
    backuppal[i].b = palette[i].b;
    backuppal[i].g = palette[i].g;
    PALInternal.WriteObjectivePalette (i, palette[i].r, palette[i].b, palette[i].g);
    i++;
  }
}

function ReloadPalette () 
{
    int i;
  while (i <256)
  {
    palette[i].r = backuppal[i].r;
    palette[i].b = backuppal[i].b;
    palette[i].g = backuppal[i].g;
    i++;
  }
  PALInternal.ResetRemapping ();
}


PALSTRUCT paleffect [65536];
PALSTRUCT fadepalette [256];

static function PALgorithms::FadeOutEx(int palnum, int r, int g, int b, float speed, int palstart, int palend)
{
  int i=palstart;
  while (i<palend) 
  {
    if (palnum == -1)
    {
      int ir = PALInternal.GetRemappedSlot (i);
      fadepalette[i].r = palette[ ir].r;
      fadepalette[i].b = palette[ ir].b;
      fadepalette[i].g = palette[ ir].g;
    }
    else
    {
      fadepalette[i].r = paleffect[palnum*256+i].r;
      fadepalette[i].b = paleffect[palnum*256+i].b;
      fadepalette[i].g = paleffect[palnum*256+i].g;
    }
    i++;
    
  }
  int p = 0;
  float fp = 0.0;
  while (p < 63)
  {
    p = FloatToInt(fp, eRoundNearest);
    if (p > 63) p = 63;
    else if (p < 0) p = 0;
    i=palstart;
    while (i < palend)
    {
    int ir = PALInternal.GetRemappedSlot (i);
    if (palnum == -1)
    {
      palette[ ir].r = (fadepalette[i].r*(63-p) + r*p)/63;
      palette[ ir].g = (fadepalette[i].g*(63-p) + g*p)/63;
      palette[ ir].b = (fadepalette[i].b*(63-p) + b*p)/63;
    }
    else
    {
      paleffect[palnum*256+i].r = (fadepalette[i].r*(63-p) + r*p)/63;
      paleffect[palnum*256+i].g = (fadepalette[i].g*(63-p) + g*p)/63;
      paleffect[palnum*256+i].b = (fadepalette[i].b*(63-p) + b*p)/63;
    }
    i++;
    }
    fp += speed;
    Wait (1);
  }
}

static function PALgorithms::FadeInEx (int palnum, int r, int g, int b, float speed, int num, int num2, int amount, int palstart, int palend)
{
  if (num == -1)
  {
    int i=0;
    while (i<256)
    {
    fadepalette[ i].r = backuppal [i].r;
    fadepalette[ i].g = backuppal [i].g;
    fadepalette[ i].b = backuppal [i].b;
    i++;
    }
  } 
  else if (num2 == -1)
  {
    int i = 0;
   while (i<256) 
   {
    int ir = PALInternal.GetRemappedSlot (i);
    fadepalette[ ir].r = (backuppal[ i].r*(63-amount) + paleffect[(num*256)+i].r*amount)/63;
    fadepalette[ ir].g = (backuppal[ i].g*(63-amount) + paleffect[(num*256)+i].g*amount)/63;
    fadepalette[ ir].b = (backuppal[ i].b*(63-amount) + paleffect[(num*256)+i].b*amount)/63;
    i++;
   }
  }
  else
  {
    int i=0;
    while (i<256)
    {
     int ir = PALInternal.GetRemappedSlot (i);
     fadepalette[ ir].r = (paleffect[(num*256)+i].r*(63-amount) + paleffect[(num2*256)+i].r*amount)/63;
     fadepalette[ ir].g = (paleffect[(num*256)+i].g*(63-amount) + paleffect[(num2*256)+i].g*amount)/63;
     fadepalette[ ir].b = (paleffect[(num*256)+i].b*(63-amount) + paleffect[(num2*256)+i].b*amount)/63;
     i++;
    }
  }
  int p = 0;
  float fp = 0.0;
  int i=0;
  Wait (20);
  while (p < 63)
  {
    p = FloatToInt(fp, eRoundNearest);
    if (p > 63) p = 63;
    else if (p < 0) p = 0;
    i=palstart;
    while (i < palend)
    {
    int ir = PALInternal.GetRemappedSlot (i);
    if (palnum == -1)
    {
      palette[ ir].r = (fadepalette[i].r*p + r*(63-p))/63;
      palette[ ir].g = (fadepalette[i].g*p + g*(63-p))/63;
      palette[ ir].b = (fadepalette[i].b*p + b*(63-p))/63;
    }
    else
    {
      paleffect[palnum*256+i].r = (fadepalette[i].r*p + r*(63-p))/63;
      paleffect[palnum*256+i].g = (fadepalette[i].g*p + g*(63-p))/63;
      paleffect[palnum*256+i].b = (fadepalette[i].b*p + b*(63-p))/63;
    }
    i++;
    }
    fp += speed;
    UpdatePalette ();
    Wait (1);
  }
  
}

static function PALgorithms::MultiplyPalette (int num, int r, int b, int g, int p, int palstart, int palend)
{
  int i=0;
  while (i<256) 
  {
    if (i > palstart && i<palend)
      {
        paleffect[(num*256)+i].r = ((backuppal[i].r * r)/64);
        paleffect[(num*256)+i].b = ((backuppal[i].b * b)/64);
        paleffect[(num*256)+i].g = ((backuppal[i].g * g)/64);
        paleffect[(num*256)+i].r = (backuppal[ i].r*(63-p) + paleffect[(num*256)+i].r*p)/63;
        paleffect[(num*256)+i].g = (backuppal[ i].g*(63-p) + paleffect[(num*256)+i].g*p)/63;
        paleffect[(num*256)+i].b = (backuppal[ i].b*(63-p) + paleffect[(num*256)+i].b*p)/63;
      }
    else
      {
        paleffect[(num*256)+i].r = (backuppal[i].r);
        paleffect[(num*256)+i].g = (backuppal[i].g);
        paleffect[(num*256)+i].b = (backuppal[i].b);
      }
    i++;
  }
  
  
}

static function PALgorithms::ThresholdPalette (int num, int p, int palstart, int palend)
{
  int i=0;
  while (i<256) 
  {
    if (i > palstart && i<palend)
      {
        int blackwhite;
        if ((backuppal[i].r + backuppal[i].b + backuppal[i].g)/3 > p) blackwhite = 63;
        else blackwhite = 0;
        paleffect[(num*256)+i].r = blackwhite;
        paleffect[(num*256)+i].b = blackwhite;
        paleffect[(num*256)+i].g = blackwhite;
      }
    else
      {
        paleffect[(num*256)+i].r = (backuppal[i].r);
        paleffect[(num*256)+i].g = (backuppal[i].g);
        paleffect[(num*256)+i].b = (backuppal[i].b);
      }
    i++;
  }
  
  
}


static function PALgorithms::InterpolatePalette (int targetnum, int num, int p, int palstart, int palend)
{
  if (p > 63) p = 63;
  if (p <0 ) p = 0;
  int i=0;
  while (i<256) 
  {
    int ir = PALInternal.GetRemappedSlot (i);
    if (i > palstart && i<palend)
    {
      if (targetnum == -1)
      {
        palette[ ir].r = (backuppal[ i].r*(63-p) + paleffect[(num*256)+i].r*p)/63;
        palette[ ir].g = (backuppal[ i].g*(63-p) + paleffect[(num*256)+i].g*p)/63;
        palette[ ir].b = (backuppal[ i].b*(63-p) + paleffect[(num*256)+i].b*p)/63;
      }
      else
      {
        paleffect[(targetnum*256)+i].r = (backuppal[ i].r*(63-p) + paleffect[(num*256)+i].r*p)/63;
        paleffect[(targetnum*256)+i].g = (backuppal[ i].g*(63-p) + paleffect[(num*256)+i].g*p)/63;
        paleffect[(targetnum*256)+i].b = (backuppal[ i].b*(63-p) + paleffect[(num*256)+i].b*p)/63;
      }
    }
    else
    {
      if (targetnum == -1)
      {
        palette[ ir].r = (backuppal[ i].r);
        palette[ ir].g = (backuppal[ i].g);
        palette[ ir].b = (backuppal[ i].b);
      }
      else
      {
        paleffect[(targetnum*256)+i].r = (backuppal[ i].r);
        paleffect[(targetnum*256)+i].g = (backuppal[ i].g);
        paleffect[(targetnum*256)+i].b = (backuppal[ i].b);
      }
    }
    i++;
  }
  UpdatePalette();
}

static function PALgorithms::InterpolateBetweenPalettes (int targetnum, int num,int num2,  int p, int palstart, int palend)
{
  if (p > 63) p = 63;
  if (p <0 ) p = 0;
  int i=0;
  while (i<palend) 
  {
    int ir = PALInternal.GetRemappedSlot (i);
    if (i > palstart && i<palend)
      {
        if (targetnum == -1)
        {
          palette[ ir].r = (paleffect[(num*256)+i].r*(63-p) + paleffect[(num2*256)+i].r*p)/63;
          palette[ ir].g = (paleffect[(num*256)+i].g*(63-p) + paleffect[(num2*256)+i].g*p)/63;
          palette[ ir].b = (paleffect[(num*256)+i].b*(63-p) + paleffect[(num2*256)+i].b*p)/63;
        }
        else
        {
          paleffect[(targetnum*256)+i].r = (paleffect[(num*256)+i].r*(63-p) + paleffect[(num2*256)+i].r*p)/63;
          paleffect[(targetnum*256)+i].g = (paleffect[(num*256)+i].g*(63-p) + paleffect[(num2*256)+i].g*p)/63;
          paleffect[(targetnum*256)+i].b = (paleffect[(num*256)+i].b*(63-p) + paleffect[(num2*256)+i].b*p)/63;
        }
      }
    else
      {
        if (targetnum == -1)
        {
          palette[ ir].r = (backuppal[ i].r);
          palette[ ir].g = (backuppal[ i].g);
          palette[ ir].b = (backuppal[ i].b);
        }
        else
        {
          paleffect[(targetnum*256)+i].r = (backuppal[ i].r);
          paleffect[(targetnum*256)+i].g = (backuppal[ i].g);
          paleffect[(targetnum*256)+i].b = (backuppal[ i].b);
        }
      }
    i++;
  }
  UpdatePalette();
}


static function PALgorithms::BlankPalette(int num, char R, char G, char B, char p, int palstart, int palend) {
  if (p > 63) p = 63;
  if (p <0 ) p = 0;
  int i=0;
  while (i<palend) 
  {
    if (i > palstart && i<palend)
      {
        paleffect[(num*256)+i].r = R;
        paleffect[(num*256)+i].g = G;
        paleffect[(num*256)+i].b = B;
      }
    else
      {
        paleffect[(num*256)+i].r = (backuppal[ i].r);
        paleffect[(num*256)+i].g = (backuppal[ i].g);
        paleffect[(num*256)+i].b = (backuppal[ i].b);
      }
    i++;
  }
  UpdatePalette();
}


static function PALgorithms::Tint(char R, char G, char B, char p, int palstart, int palend) {
  if (p > 63) p = 63;
  if (p <0 ) p = 0;
  int i;
  while (i<256) 
  {
    //palette[ i].r = backuppal[ i].r + (R - backuppal[ i].r)*p/256;
    //palette[ i].g = backuppal[ i].g + (G - backuppal[ i].g)*p/256;
    //palette[ i].b = backuppal[ i].b + (B - backuppal[ i].b)*p/256;
    int ir = PALInternal.GetRemappedSlot (i);
    if (i > palstart && i < palend)
    {
    palette[ ir].r = (backuppal[ i].r*(63-p) + R*p)/63;
    palette[ ir].g = (backuppal[ i].g*(63-p) + G*p)/63;
    palette[ ir].b = (backuppal[ i].b*(63-p) + B*p)/63;
    }
    else 
    {
      palette[ ir].r = backuppal[ i].r;
      palette[ ir].g = backuppal[ i].g;
      palette[ ir].b = backuppal[ i].b;
    }
    i++;
  }
  UpdatePalette();
}

static function PALgorithms::CyclePaletteEx (int start, int end)
{
  CyclePalette (start, end);
  PALInternal.CycleRemap (end, start);
}

static function PALgorithms::Fadeout(char R, char G, char B, char speed) 
{ 
  int i;
  int speedtimer;
  int speeddelay;
  if (speed < 0) speeddelay = AbsInt (speed);
  else if (speed == 0) speed = 1;
  int actualspeed = AbsInt (speed);
  while (palette[22].r != R &&palette[22].g != G && palette[22].b != B) 
  {
    PALgorithms.Tint (R, G, B, i);
    if (speeddelay == speedtimer) 
    {
      Wait (actualspeed);
      speedtimer = 0;
    }
    else speedtimer++;
    i++;
  }
}
  
  
static function PALgorithms::Fadein(char R, char G, char B, char speed) 
{ 
  int i;
  int speedtimer;
  int speeddelay;
  if (speed < 0) speeddelay = AbsInt (speed);
  else if (speed == 0) speed = 1;
  int actualspeed = AbsInt (speed);
  /*remake this function*/
}

int noloopcheck GFX_FindBestColor(int R1, int G1, int B1)
{  
int index;  
int best;  
int bestCost = 3*256*256; // the max the diff can get to
while (index < 256)  
{
  int dr = R1 - palette[index].r;
  int dg = G1 - palette[index].g;
  int db = B1 - palette[index].b;
  int cost = dr*dr + dg*dg + db*db;
  if (cost < bestCost)
  {
    best = index;
    bestCost = cost;
    }    
    index++;  
  }  
  return best;
  }
  
  
function noloopcheck GFX_CreateTransTable(int clutnum, int alpha)
{  
  int index;  
  int oma = 100-alpha;  
  while (index < 256)  
  {    
       int index2 = 0;    
       while (index2 < 256)   
       {      // this is the correct way to blend the colors
              // no need to go from float to int and back
              // the +50 is to make sure it rounds to the nearest
              int idealr = (oma*palette[index].r + alpha*palette[index2].r + 50)/100;
              int idealg = (oma*palette[index].g + alpha*palette[index2].g + 50)/100;
              int idealb = (oma*palette[index].b + alpha*palette[index2].b + 50)/100;
              //rgblbl.Text = String.Format ("%d %d %d",idealr, idealb, idealg);
              clut[clutnum].data[256*index + index2] = GFX_FindBestColor(idealr, idealg, idealb);
              index2++;
       }
       index++;
   }
}

function SetGraphic (this Object*,  int graphic)
{
  objecttruesprite [this.ID] = graphic;
}

function SetTransparency (this Object*, char alpha,int mask, BlendingMode blend)
{
  if (this == null) AbortGame ("Clutter Error: Invalid Object!");
  if (alpha == 0)
  {
    this.Visible = false;
  }
  else 
  {
    this.Visible = true;
  }
  if (alpha < 255) objecttransparent [this.ID] = alpha;
  else if (alpha > 256) objecttransparent [this.ID] = 256;
  objectblending [this.ID] = blend;
  objectmask[this.ID]= mask;
}

static function noloopcheck PALgorithms::GenerateCLUTForRoom ()
{
  /*
 int i = 1;
 while (i < 9)
 {
   GFX_CreateTransTable (i-1, i * 10);
   Wait (1);
   i++;
 }
 int x;
 int y;
 i=0;
 int cdata = 0;
 DynamicSprite *CLUTSPR = DynamicSprite.Create (256, 2048);
 DrawingSurface *surface = CLUTSPR.GetDrawingSurface ();
 while (i < 8)
 {
   while (cdata < 65536)
   {
   surface.DrawingColor = clut[i].data [cdata];
   surface.DrawPixel (x, y);
   if (x == 255 && y <2047) y++;
   if (x < 255) x++;
   else x = 0;
   cdata ++;
   }
   i++;
   cdata = 0;
 }
 surface.Release ();
 CLUTSPR.SaveToFile (String.Format("CLUTROOM%d.BMP",player.Room));
 CLUTSPR.Delete ();
 Display ("DONE!");
 */
  int x = 0;
  int y = 0;
  int r = 0;
  int g = 0;
  int b = 0;
  CLUTSPR = DynamicSprite.Create (256, 256);
  DrawingSurface *surf = CLUTSPR.GetDrawingSurface ();
  while (y < 256)
  {
    while (x < 256)
    {
        int c = x + 256*y;
        b = (c % 32);    // The lower 5 bits of c
        c = c/32;
        g = (c % 64);    // The next 6 bits of c
        r = (c/64);      // The remaining (upper) 5 bits of c
 
        surf.DrawingColor = Game.GetColorFromRGB (r*8, g*4, b*8);
        surf.DrawPixel(x,y);
        x++;
    }
    x=0;
    y++;
  }
  surf.Release ();
  String filename = String.Format ("clutforroom%d.bmp",player.Room);
  CLUTSPR.SaveToFile (filename);
  PALInternal.LoadCLUT (CLUTSPR.Graphic);
}


function noloopcheck GetCLUTForRoom () 
{
  /*
  int i;
  int x;
 int y;
 i=0;
 int cdata = 0;
 //DynamicSprite *CLUTSPR = DynamicSprite.CreateFromExistingSprite (GetRoomProperty ("TransCLUTSlot"), false);
 DrawingSurface *surface = CLUTSPR.GetDrawingSurface ();
 while (i < 8)
 {
   while (cdata < 65536)
   {
   clut[i].data [cdata] = surface.GetPixel (x, y);
   if (x == 255 && y <2047) y++;
   if (x < 255) x++;
   else x = 0;
   cdata ++;
   }
   i++;
   cdata = 0;
 }
 surface.Release ();
 CLUTSPR.Delete ();
 */
 PALInternal.LoadCLUT (GetRoomProperty ("TransCLUTSlot"));
}

static function PALgorithms::ProcessPalette (int palsiz, int palindex[])
{
  int paltemp [];
  paltemp = new int [palsiz];
  char i = 0;
  int i2 = 1;
  int upperboundary;
  while (i < palsiz)
  {
    paltemp [i] = (palette[palindex[i]].r +  // This algorithm produces an accurate, fast approximation of
                   palette[palindex[i]].r +  // The luminescence value of each of our palette slots.
                   palette[palindex[i]].r +  //
                   palette[palindex[i]].b +  // This ensures that when we colourise the final product, there 
                   palette[palindex[i]].g +  // will be little to no weird artifacts or lightness shifts.
                   palette[palindex[i]].g +  //
                   palette[palindex[i]].g +  // By using addition and bit shifts instead of multiplication, 
                   palette[palindex[i]].g    // the code will run a lot faster and more efficiently.
                   )>>3;
                   //Display ("%d", paltemp [i]);
    i++;
  }
  i = 0;
  while (i < palsiz)
  {
      //Display ("%d , %d", i,  i+1);
      if (i > palsiz -2) upperboundary = 255;
      else upperboundary = (paltemp [i] + paltemp [i + 1])/2;
      //Display ("%d",upperboundary);

      while (i2 < upperboundary)
      {
        String output;
        _C8palgorithm [i2] = palindex[i];
        //lblGameTitle.Text = String.Format ("%d", _C8palgorithm [i2]);
        i2++;
        //Wait (5);
        //lblGameTitle.Text = "";
        //Wait (1);
      }
    i++;
    }
    
    i= 0;
    paltemp = new int [256];
    while (i < 255)
      {
       paltemp [i] = (palette[i].r +  // This algorithm produces an accurate, fast approximation of
                      palette[i].r +  // The luminescence value of each of our palette slots.
                      palette[i].r +  //
                      palette[i].b +  // This ensures that when we colourise the final product, there 
                      palette[i].g +  // will be little to no weird artifacts or lightness shifts.
                      palette[i].g +  //
                      palette[i].g +  // By using addition and bit shifts instead of multiplication, 
                      palette[i].g    // the code will run a lot faster and more efficiently.
                      )>>3;
                      i++;
      }
    i = 0;
    while (i < 255)
      {
       _C8PaletteMap [i] = _C8palgorithm [paltemp[i]];
       i++;
      }
  } 
  
  
function ColouriseArea (this DynamicSprite*, int x1,  int y1,  int w,  int h)
{
  DrawingSurface *Surface;
  DynamicSprite *Area;
  //Display ("Init C8");
  mouse.Visible = false;
  Wait (1);
  Area = DynamicSprite.CreateFromScreenShot (320, 200);
  //Display ("Screenshot created.");
  mouse.Visible = true;
  if (Area.ColorDepth != 8) AbortGame ("Error in COLOR8: Isn't an indexed image!");
  Area.Crop (x1, y1, w, h);
  Surface = Area.GetDrawingSurface ();
  int i;
  int j;
  int cpixel;
  while (j < h)
  {
    while (i < w)
    {
      cpixel = Surface.GetPixel (i, j);
      //Display ("Coordinates: %d, %d. Colour: %d",i, j,  Surface.GetPixel (i, j));
      if (cpixel == COLOR_TRANSPARENT) Surface.DrawingColor = COLOR_TRANSPARENT;
      else Surface.DrawingColor = _C8PaletteMap [cpixel];
      Surface.DrawPixel (i, j);
      i++;
    }
    i = 0;
    j++;
  } 
  this.Crop (x1, y1, w, h);
  Surface.Release ();
  Surface = this.GetDrawingSurface ();
  Surface.DrawImage (0, 0, Area.Graphic);
  Surface.Release ();
  Area.Delete ();
  return this.Graphic;
}

function CreateColourisedSprite (this DynamicSprite*,  int oldsprite)
{
  DrawingSurface *Surface;
  DynamicSprite *C8Sprite = DynamicSprite.CreateFromExistingSprite (oldsprite);
  if (C8Sprite.ColorDepth != 8) AbortGame ("Not an indexed sprite!");
  Surface = C8Sprite.GetDrawingSurface ();
  int i;
  int j;
  int c8pixel;
  while (j < C8Sprite.Height)
  {
    while (i < C8Sprite.Width)
    {
      c8pixel = Surface.GetPixel (i, j);
      //Display ("Coordinates: %d, %d. Colour: %d",i, j,  Surface.GetPixel (i, j));
      if (c8pixel == COLOR_TRANSPARENT) Surface.DrawingColor = 255;
      else if (c8pixel == 0) Surface.DrawingColor = 0;
      else Surface.DrawingColor = _C8PaletteMap [c8pixel];
      Surface.DrawPixel (i, j);
      i++;
    }
    i = 0;
    j++;
  }
  this.Resize (1, 1);
  this.ChangeCanvasSize (C8Sprite.Width, C8Sprite.Height, 0, 0);
  Surface.Release ();
  Surface = this.GetDrawingSurface ();
  Surface.DrawImage (0, 0, C8Sprite.Graphic);
  Surface.Release ();
  C8Sprite.Delete ();
  return this.Graphic;
}

static function PALgorithms::SetRandomColour (char palnum, PalColourMode mode)
{
  if (mode == ePalColour)
    {
      RandomColours[0].b =  0 + Random (63);
      RandomColours[0].r =  0 + Random (63);
      RandomColours[0].g =  0 + Random (63);
      randompalslot[0] = palnum;
    }
  else 
    {
      randompalslot [1] = palnum;
    }
}


function noloopcheck on_key_press (eKeyCode KeyCode)
{
  if(KeyCode == eKeyCtrlP)
  {
    PALgorithms.GenerateCLUTForRoom ();
    CLUTSPR.SaveToFile (String.Format ("CLUT#%d.bmp",player.Room));
  }
}


function game_start ()
{
}

function on_event(EventType event, int data) 
{
  if (event == eEventEnterRoomBeforeFadein)
  {
    int i;
    GetCLUTForRoom ();
    if (Room.ObjectCount)
    {
      objecttransparent = new int [Room.ObjectCount];
      objecttruesprite  = new int [Room.ObjectCount];
      objecttranssprite = new int [Room.ObjectCount];
      objectblending = new int [Room.ObjectCount];
      objectmask = new int [Room.ObjectCount];
      origspr = new DynamicSprite [Room.ObjectCount];
      //if (GetRoomProperty ("TransCLUTSlot")) GetCLUTForRoom ();
      while (i < Room.ObjectCount) 
      {
        objecttransparent [i] = 256;
        objecttruesprite  [i] = object[i].Graphic;
        objecttranssprite [i] = 0;
        objectmask [i] = 0;
        i++;
      }
    }
    else 
    {
      objecttransparent = new int [1];
      objecttruesprite  = new int [1];
      objecttranssprite = new int [1];
    }
    BackupPalette ();
  }
  else if (event == eEventLeaveRoom)
  {
    
  int k;
  while (k < Room.ObjectCount)
  {
    object[k].Graphic = objecttruesprite [k];
    if (origspr[k] != null) origspr[k].Delete ();
    k++;
  }
  int l=0;
  while (l < 128)
  {
    Translucence.DeleteOverlay (l);
    l++;
  }
  ReloadPalette ();
  }
  
}

function repeatedly_execute_always ()
{
  int transcheck;
  bool transrender;
  char randomcheck = 0;
  if (randompalslot[0] != 0)
  {
    //Red
    if (palette[randompalslot[0]].r > RandomColours[0].r)
      {
        palette[randompalslot[0]].r  -= 1;
      }
    else if (palette[randompalslot[0]].r < RandomColours[0].r)
      {
        palette[randompalslot[0]].r += 1;
      }
    else if (palette[randompalslot[0]].r == RandomColours[0].r)
    {
      randomcheck ++;
    }
    //Green
    if (palette[randompalslot[0]].g > RandomColours[0].g)
      {
        palette[randompalslot[0]].g -= 1;
      }
    else if (palette[randompalslot[0]].g < RandomColours[0].g)
      {
        palette[randompalslot[0]].g += 1;
      }
    else if (palette[randompalslot[0]].g == RandomColours[0].g)
    {
      randomcheck ++;
    }
    //Blue
        if (palette[randompalslot[0]].b > RandomColours[0].b)
      {
        palette[randompalslot[0]].b -= 1;
      }
    else if (palette[randompalslot[0]].b < RandomColours[0].b)
      {
        palette[randompalslot[0]].b += 1;
      }
    else if (palette[randompalslot[0]].b == RandomColours[0].b)
    {
      randomcheck ++;
    }
    
    if (randomcheck == 3)
    {
      PALgorithms.SetRandomColour (randompalslot[0], ePalColour);
    }
    else randomcheck = 0;
    if (randompalslot[1] != 0)
  {
    palette[randompalslot[1]].r = palette[randompalslot[0]].r /2;
    palette[randompalslot[1]].b = palette[randompalslot[0]].b /2;
    palette[randompalslot[1]].g = palette[randompalslot[0]].g /2;
  }
  }

  
  if (Room.ObjectCount)
  {
  while (transcheck < Room.ObjectCount)
  {
    if (objecttransparent[transcheck] < 256 && objecttransparent[transcheck] > 0) transrender = true;
    transcheck++;
  }
  if (transrender == true)
  {
  DynamicSprite *sprite = DynamicSprite.CreateFromBackground();
  DrawingSurface *surface = sprite.GetDrawingSurface();
  int i = 0;
  while ((i < Game.CharacterCount) || (i < Room.ObjectCount)) {
    if ((i < Game.CharacterCount) && (character[i].Room == player.Room)) surface.DrawCharacter(character[i]);
    if (i < Room.ObjectCount) {
      if (object[i].Visible) surface.DrawObject(object[i]);
      if (object[i].Graphic && object[i].Visible) {
        int scale = GetScalingAt(object[i].X, object[i].Y);
        int ow = (Game.SpriteWidth[object[i].Graphic] * scale) / 100;
        int oh = (Game.SpriteHeight[object[i].Graphic] * scale) / 100;
        if (object[i].IgnoreScaling) {
          ow = Game.SpriteWidth[object[i].Graphic];
          oh = Game.SpriteHeight[object[i].Graphic];
        }
        int ox1 = object[i].X;
        int ox2 = ox1 + ow;
        int j = 0;
        while (j < Game.CharacterCount) {
          if (character[j].Room == player.Room) {
            ViewFrame *frame = Game.GetViewFrame(character[j].View, character[j].Loop, character[j].Frame);
            int cw = (Game.SpriteWidth[frame.Graphic] * character[j].Scaling) / 100;
            int cx1 = character[j].x - (cw / 2);
            if ((((cx1 + cw) >= ox1) && (cx1 <= ox2)) && (character[j].y > object[i].Baseline) && ((character[j].y - character[j].z) >= (object[i].Y - oh))) surface.DrawCharacter(character[j]);
          }
          j++;
        }
      }
    }
    i++;
  }
  surface.Release();
  sprite.Delete();
  }
  }
  UpdatePalette ();
}


function CreateBackgroundSilhouette (this DynamicSprite*, int spriteslot, int x, int y)
{
  DynamicSprite* sprite = DynamicSprite.CreateFromExistingSprite (spriteslot);
  DynamicSprite* temp = DynamicSprite.CreateFromBackground (GetBackgroundFrame (), x, y, sprite.Width, sprite.Height);
  temp.CopyTransparencyMask (sprite.Graphic);
  sprite.Delete ();
  DrawingSurface* surface = this.GetDrawingSurface ();
  surface.DrawImage (0, 0, temp.Graphic);
  surface.Release ();
  temp.Delete ();
  return this.Graphic;
}   // new module header
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
 -=�!        ej��
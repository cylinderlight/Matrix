

/**
 * Marco Brianza
 * CylinderLight Movie streamer
 * Tested on Processing 2.0
 * June 24th 2013
 */

import oscP5.*;
import netP5.*;

import processing.video.*;

OscP5 oscP5;
NetAddress OSCRemoteLocation;
String REMOTE_IP="192.168.1.3";
int REMOTE_PORT=10000;
int LOCAL_PORT=11000;

Movie mov;
PImage movFrame;

int X_LEDS=6;
int Y_LEDS=15;
int DISPLAY_SCALE=50; //screen scale factor
int FRAMES_PER_SECOND=5;

String movieFile="clouds.mp4";

void setup() {
  noStroke(); 

  oscP5 = new OscP5(this, LOCAL_PORT);
  OSCRemoteLocation = new NetAddress(REMOTE_IP, REMOTE_PORT);

  size(X_LEDS*DISPLAY_SCALE, Y_LEDS*DISPLAY_SCALE);
  frameRate(FRAMES_PER_SECOND);

  mov = new Movie(this, movieFile );
  mov.loop();
}


//--------------------------------
void draw() {

  drawMovie(true);
  sendImage(movFrame);
}

//-----------------------------------
void drawMovie(boolean blockMode) {

  if (mov.available() == true) {
    mov.read();
    movFrame=imgCopy(mov);
    movFrame.resize(X_LEDS, Y_LEDS);
    if (blockMode) {
      drawBlocked(movFrame);
    }
    else {
      image(movFrame, 0, 0, width, height);
    }
  }
}


//------------------------copy the movie image to a PImage
PImage imgCopy(PImage imgi) {
  color c;
  PImage imgo=createImage(imgi.width, imgi.height, RGB);
  imgi.loadPixels();
  imgo.loadPixels();
  for (int i=0; i<imgi.width; i++) {
    for (int j=0; j<imgi.height; j++) {
      c=imgi.get(i, j);
      //println(c);
      imgo.set(i, j, c);
    }
  }
  imgo.updatePixels();
  return(imgo);
}

//-------------------------draws the image without smoothing
void drawBlocked(PImage img) {
  color c;
  int dx=width/img.width;
  int dy=height/img.height;

  for (int i=0; i<dx; i++) {
    for (int j=0; j<dy; j++) {
      c=img.get(i, j);
      fill (img.get(i, j));
      rect(i*dx, j*dy, dx, dy);
    }
  }
}



//----------------------- send the image data using to the lamp
void sendImage(PImage img) {

  int r, g, b;
  color c= color(0, 0, 0);

  for (int x=0; x<X_LEDS; x++) 
  { 
    for (int y=0; y<Y_LEDS; y++) 
    {
      c = calibrate(img.get(x, y));
      r=int(red(c));
      g=int(green(c));
      b=int(blue(c));

      send_RGBxy(r, g, b, x, y);
      delay(1);
    }
  }   
  sendShow();
}

//----------------------- send the OSC show message to visualize the data
void sendShow() {
  OscMessage myMessage = new OscMessage("/show");
  oscP5.send(myMessage, OSCRemoteLocation);
}

//----------------------calibrates the color for a perceptual adaptation (to be improved)
color calibrate(color C) {
  float gammaR=3;
  float gammaG=2;
  float gammaB=2.5;

  int outRangeR=220;
  int outRangeG=255;
  int outRangeB=255;

  int inRange=255;
  float r, g, b;
  float rC, gC, bC;
  color cC;

  r=red(C);
  g=green(C);
  b=blue(C);

  rC=pow((r/inRange), gammaR)*outRangeR;
  gC=pow((g/inRange), gammaG)*outRangeG;
  bC=pow((b/inRange), gammaB)*outRangeB;

  cC=color(rC, gC, bC); 

  return(cC);
}


//------------------------------------------------ send the actual RGB data to the lamp matrix
void send_RGBxy(int R, int G, int B, int x, int y) {
  OscMessage myMessage = new OscMessage("/RGBxy");

  myMessage.add(R); 
  myMessage.add(G); 
  myMessage.add(B); 

  myMessage.add(x); 
  myMessage.add(y); 

  oscP5.send(myMessage, OSCRemoteLocation);
}


//------------------------------------------------- send the message to diaply the light values
void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");
  theOscMessage.print();
}

//-----------------------------------------------------
void delay(int ms)
{
  try
  {    
    Thread.sleep(ms);
  }
  catch(Exception e) {
  }
}


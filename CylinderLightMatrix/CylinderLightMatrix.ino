// cylinderlight bitmap sketch
// Marco Brianza
// June 24th 2013


#include <Ethernet.h>
#include <EthernetUdp.h>
#include <OSCBundle.h>
#include <OSCBoards.h>
#include <SPI.h>
#include "FastSPI_LED2.h"
#include <MemoryFree.h>

//leds stuff---------------------------------------
const byte X_LEDS=6;
const byte Y_LEDS=15;
const int NUM_LEDS = X_LEDS * Y_LEDS;
const byte OUT_PIN=7;
struct CRGB leds[NUM_LEDS];

//network stuff------------------------------------
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 1, 3); //the Arduino's IP
const byte MAX_MSG_SIZE=128;  // 64 sould be ok
byte packetBuffer[MAX_MSG_SIZE];  //buffer to hold incoming udp packet,
EthernetUDP Udp;
const unsigned int inPort = 10000;
const unsigned int outPort = 11000;
  
// ---------------------------------------

void setup(){   
 Serial.begin(115200);
 
  Ethernet.begin(mac,ip);
  Udp.begin(inPort);
 
 LEDS.setBrightness(254);
 LEDS.addLeds<TM1809, OUT_PIN>(leds,  NUM_LEDS);
 
Serial.print("Mem=");
Serial.println(freeMemory());
}
  
// - ----------------------------------------  
  
void loop(){
  OSCBundle bundleIN;
  OSCMessage messageIN;

  int s;
  s = Udp.parsePacket();
  
  if(s)
  {
    Udp.read(packetBuffer,s);
    bundleIN.fill(packetBuffer,s);

    if(!bundleIN.hasError())
    {
      int bs=bundleIN.size();
//      Serial.print("bundle messages ");
//      Serial.println(bs);
      if (bs){
       // bundle messages routing
         
      }
      else
      {
        messageIN.fill(packetBuffer,s);
        if(!messageIN.hasError())
        {
          messageIN.route("/e", echo); //debug
          messageIN.route("/RGBn",set_RGBn);
          messageIN.route("/RGBxy",set_RGBxy); 
          if (messageIN.fullMatch("/show")){
            LEDS.show();
            Serial.print("show");
          }     

        }
      }
    }
  }
  

} // end main---------------------




//------- OSC callbacks --------------------------

void echo(OSCMessage &msg, int addrOffset){
 float echoValue=msg.getFloat(0); 

Serial.print("Mem=");
Serial.println(freeMemory());
//   Serial.print("Debug=");
//   Serial.println(echoValue);

 OSC_replay("/d", echoValue);
  
}
// ------------------------------------

 
 
 // single LED control
 
 void set_RGBn(OSCMessage &msg, int addrOffset)
 {
  byte n, R,G,B;
 
  R=msg.getInt(0); 
  G=msg.getInt(1); 
  B=msg.getInt(2); 
  n=msg.getInt(3);
  
  if (n==0)
  {
   for (int i=0 ;i< NUM_LEDS; i++)  leds[i]=CRGB(B,R,G); 
  }
  else if(n>0 || n<NUM_LEDS) leds[n-1]=CRGB(B,R,G);        
  //LEDS.show();
  
 }
 
// end OSC callbacks ---------------------
 
void set_RGBxy(OSCMessage &msg, int addrOffset)
 {
  byte x,y, r,g,b;
  byte n;

    r=msg.getInt(0); 
    g=msg.getInt(1); 
    b=msg.getInt(2); 
    x=msg.getInt(3);
    y=msg.getInt(4); 
  
    n=Y_LEDS*x+y;
    Serial.println(n);     
    leds[n] = CRGB(b,r, g);  
 }
 

 
void OSC_replay(char* address, float value)
  {
//    Serial.print("response to ");
//    Serial.println(Udp.remoteIP());
    
    Udp.beginPacket(Udp.remoteIP(), outPort);
    OSCMessage msgOut(address);
    msgOut.add(value); 
    msgOut.send(Udp); // send the bytes to the SLIP stream
    Udp.endPacket(); // mark the end of the OSC Packet
    msgOut.empty(); // free space oc
  //  OSCBundle bndl; 
  //  bndl.add("/d").add(d);
  //  bndl.send(Udp); // send the bytes to the SLIP stream
  //  Udp.endPacket(); // mark the end of the OSC Packet
  //  bndl.empty(); // empty
    
  }  
  
 
 




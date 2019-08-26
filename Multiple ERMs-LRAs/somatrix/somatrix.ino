/*
  This example connects to an unencrypted WiFi network.
  Then to a broadcasting OSC server in Processing
  Then it accepts commands to control LED and vibration patterns using the Adafruit_DRV2605
  Based on Oscuino
  Circuit:
   WiFi shield attached
  Created 2019-02-26
  by p_sanches
  Based on tutorials:
  created 13 July 2010
  by dlf (Metodo2 srl)
  modified 31 May 2012
  by Tom Igoe

*/
#include <SPI.h>
#include <WiFiNINA.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCBundle.h>
#include <OSCBoards.h>
#include <Wire.h>
#include "Adafruit_DRV2605.h"
#include <PneuDuino.h>
#include <Wire.h>


Adafruit_DRV2605 drv;

uint8_t effect = 1; //Pre-made vibe Effects
boolean effectMode = false;


int vibeIntensityRT = 0;
int vibeDelayRT = 1;
int vibratePower = 0;
int deflatePower = 0;

boolean vibrate = false;
boolean deflate = false;

int inflateDuration = 0;
int deflateDuration = 0;

unsigned long currentMillis = 0;    
unsigned long previousMillis = 0;

float cx = 0;
float cy = 0;

//#include "arduino_secrets.h"
///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = "somarouter";        // your network SSID (name)
char pass[] = "";    // your network password (use for WPA, or use as key for WEP)
int status = WL_IDLE_STATUS;     // the WiFi radio's status

unsigned int localPort = 12000;      // local port to listen on

char packetBuffer[255]; //buffer to hold incoming packet

WiFiUDP Udp;

const IPAddress serverIp(192, 168, 1, 103);
const unsigned int serverPort = 32000;
PneuDuino p;


void setup() {

  //Initialize serial and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  //Initialize actuators

  //initialize LED
  pinMode(LED_BUILTIN, OUTPUT);

  //initializeVibe
  drv.begin();
  drv.selectLibrary(1);
  drv.useLRA();
  // I2C trigger by sending 'go' command
  // default: realtime
  drv.setMode(DRV2605_MODE_REALTIME);


  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue:
    while (true);
  }

  // attempt to connect to WiFi network:
  while ( status != WL_CONNECTED) {
    Serial.print("Attempting to connect to WPA SSID: ");
    Serial.println(ssid);
    // Connect to network:
    status = WiFi.begin(ssid);

    // wait 10 seconds for connection:
    delay(10000);
  }

  // you're connected now, so print out the data:
  Serial.print("You're connected to the network");
  printCurrentNet();
  printWiFiData();

  Serial.print("\nStarting listening on port:");
  Serial.print(localPort);
  // if you get a connection, report back via serial:
  Udp.begin(localPort);



  //register with server
  connectToServer();
  delay(50);


  Wire.begin();
  pinMode(12, OUTPUT);    //Channel A Direction Pin Initialize
  p.begin();


  pinMode(A0, INPUT);
  pinMode(2, INPUT);
}

void loop() {
  //   //if there's data available, read a packet
  //  int packetSize = Udp.parsePacket();
  //  if (packetSize)
  //  {
  //    Serial.print("Received packet of size ");
  //    Serial.println(packetSize);
  //    Serial.print("From ");
  //    IPAddress remoteIp = Udp.remoteIP();
  //    Serial.print(remoteIp);
  //    Serial.print(", port ");
  //    Serial.println(Udp.remotePort());
  //
  //    // read the packet into packetBufffer
  //    int len = Udp.read(packetBuffer, 255);
  //    if (len > 0) packetBuffer[len] = 0;
  //    Serial.println("Contents:");
  //    Serial.println(packetBuffer);
  //  }

  char incomingByte = 0;   // for incoming serial data
  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();
    if (incomingByte == 'c') {
      connectToServer();
      delay(50);
    }
  }

  OSCBundle bundleIN;
  int size;

  if ( (size = Udp.parsePacket()) > 0)
  {

    while (size--)
      bundleIN.fill(Udp.read());

    if (!bundleIN.hasError())
    {
      
      bundleIN.dispatch("/actuator/vibrate", routeVibrate);
      bundleIN.dispatch("/actuator/crdx", coordinateX);
      bundleIN.dispatch("/actuator/crdy", coordinateY);
      //bundleIN.dispatch("/actuator/deflatedur", routeDeflateDur);

    }
  }
  unsigned long currentMillis = millis();
  int reading2 = digitalRead(2);
  int readingA0 = analogRead(A0);


  
//  if (reading2 == HIGH)
//  {
//    if(vibratePower == 1)
//    {
    //coordinateX(&bundleIN);
    //coordinateY(&bundleIN);
    Serial.print("Coordinates ");
    Serial.print("X: ");  
    Serial.print(cx);  
    Serial.print("Y: "); 
    Serial.print(cy);
    Serial.print("\n");
//    }
//
//
//
//
//
//
//  }
}

//called whenever an OSCMessage's address matches "/led/"
void routeVibrate(OSCMessage &msg) {
  Serial.println("Vibrate");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    vibratePower = (int) data;
    vibrate = true;

  }
}




//called whenever an OSCMessage's address matches "/led/"
void coordinateX(OSCMessage &msg) {
  Serial.println("Coordinate X");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    cx = (int) data;
    

  }
}


void coordinateY(OSCMessage &msg) {
  Serial.println("Coordinate Y");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    cy = (int) data;
    //inflate = true;


  }
}




//
//void routeDeflateDur(OSCMessage &msg) {
//  Serial.println("Deflate Duration");
//  //returns true if the data in the first position is a float
//  if (msg.isFloat(0)) {
//    //get that float
//    float data = msg.getFloat(0);
//
//    Serial.println(data);
//    deflateDuration = (int) data;
//    //deflate = true;
//
//
//  }
//}






//called whenever an OSCMessage's address matches "/led/"
void routeVibeEffect(OSCMessage &msg) {
  Serial.println("Vibe Effect");
  setEffectMode();
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    effect = data;
  }
}

void setEffectMode() {
  if (!effectMode) {
    effectMode = true;
    drv.setMode(DRV2605_MODE_INTTRIG);
  }
}

void setRTMode() {

  if (effectMode) {
    effectMode = false;
    drv.setMode(DRV2605_MODE_REALTIME);
  }
}

//called whenever an OSCMessage's address matches "/led/"
void routeVibeIntensityRT(OSCMessage &msg) {
  Serial.println("Vibe Intensity");
  //setRTMode();
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    vibeIntensityRT = data;
  }
}

//called whenever an OSCMessage's address matches "/led/"
void routeVibeDelayRT(OSCMessage &msg) {
  Serial.println("Vibe Delay");
  setRTMode();
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    vibeDelayRT = data;
  }
}

void playVibeEffect() {
  // set the effect to play
  drv.setWaveform(0, effect);  // play effect
  drv.setWaveform(1, 0);       // end waveform

  // play the effect!
  drv.go();
  delay(20);
}


void playVibeRT() {
  drv.setRealtimeValue(vibeIntensityRT);
  delay(10);
  drv.setRealtimeValue(0);
  delay(vibeDelayRT);
}




void connectToServer() {

  Serial.print("\nConnecting to server bit at ");
  Serial.print(serverIp); Serial.print(":"); Serial.println(serverPort);

  OSCMessage msg("/actuator/startConnection/");

  Udp.beginPacket(serverIp, serverPort);
  msg.send(Udp); // send the bytes to the SLIP stream

  Udp.endPacket();

  msg.empty(); // free space occupied by message
}

void printWiFiData() {
  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);
  Serial.println(ip);

  // print your MAC address:
  byte mac[6];
  WiFi.macAddress(mac);
  Serial.print("MAC address: ");
  printMacAddress(mac);

}

void printCurrentNet() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print the MAC address of the router you're attached to:
  byte bssid[6];
  WiFi.BSSID(bssid);
  Serial.print("BSSID: ");
  printMacAddress(bssid);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.println(rssi);

  // print the encryption type:
  byte encryption = WiFi.encryptionType();
  Serial.print("Encryption Type:");
  Serial.println(encryption, HEX);
  Serial.println();
}

void printMacAddress(byte mac[]) {
  for (int i = 5; i >= 0; i--) {
    if (mac[i] < 16) {
      Serial.print("0");
    }
    Serial.print(mac[i], HEX);
    if (i > 0) {
      Serial.print(":");
    }
  }
  Serial.println();
}


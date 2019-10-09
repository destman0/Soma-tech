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
//#include <SPI.h>
#include <WiFiNINA.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCBundle.h>
#include <OSCBoards.h>
//#include <Wire.h>
//#include "Adafruit_DRV2605.h"

#include "Adafruit_MPRLS.h"


//Adafruit_DRV2605 drv;

#define RESET_PIN  -1  // set to any GPIO pin # to hard-reset on begin()
#define EOC_PIN    -1  // set to any GPIO pin to read end-of-conversion by pin
Adafruit_MPRLS mpr = Adafruit_MPRLS(RESET_PIN, EOC_PIN);

uint8_t effect = 1; //Pre-made vibe Effects
boolean effectMode = false;


int vibeIntensityRT = 0;
int vibeDelayRT = 1;
int inflatePower = 0;
int deflatePower = 0;

boolean inflate = false;
boolean deflate = false;

int inflateDuration = 0;
int deflateDuration = 0;

int solenoidPin1 = 7;
int solenoidPin2 = 6;

unsigned long currentMillis = 0;    
unsigned long previousMillis = 0;

//#include "arduino_secrets.h"
///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = "serv";        // your network SSID (name)
char pass[] = "somaserv";    // your network password (use for WPA, or use as key for WEP)
int status = WL_IDLE_STATUS;     // the WiFi radio's status

unsigned int localPort = 12000;      // local port to listen on

char packetBuffer[255]; //buffer to hold incoming packet

WiFiUDP Udp;

const IPAddress serverIp(192, 168, 0, 140);
const unsigned int serverPort = 32000;

int prevstate = 1;

void setup() {

  //Initialize serial and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  //Serial.println("MPRLS Simple Test");
  //if (! mpr.begin()) {
  //  Serial.println("Failed to communicate with MPRLS sensor, check wiring?");
   // while (1) {
   //   delay(10);
   // }
  //}
  Serial.println("Found MPRLS sensor");

  //Initialize actuators

  //initialize LED
//pinMode(LED_BUILTIN, OUTPUT);

  //initializeVibe
//  drv.begin();
//  drv.selectLibrary(1);
//  drv.useLRA();
  // I2C trigger by sending 'go' command
  // default: realtime
//  drv.setMode(DRV2605_MODE_REALTIME);


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
    status = WiFi.begin(ssid,pass);

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


  //Wire.begin();


  pinMode(solenoidPin1, OUTPUT);
  pinMode(solenoidPin2, OUTPUT);
  pinMode(12, OUTPUT);    //Channel A Direction Pin Initialize
  pinMode(13, OUTPUT);    //Channel B Direction Pin Initialize




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

      bundleIN.dispatch("/actuator/inflate", routeInflate);
      bundleIN.dispatch("/actuator/deflate", routeDeflate);
      bundleIN.dispatch("/actuator/inflatedur", routeInflateDur);
      bundleIN.dispatch("/actuator/deflatedur", routeDeflateDur);

    }
  }
  unsigned long currentMillis = millis();



  

 if(inflatePower == 1){
      inflatepump();
      if(prevstate != 2)
      Serial.println("Inflate");
 }
 else
   {
    
 if (deflatePower == 1)
{
      deflatepump();
      if(prevstate != 0)
      Serial.println("Deflate");
      
}
else{
  hold();
  if(prevstate != 1)
  Serial.println("Hold");
  }
}
   
}

//called whenever an OSCMessage's address matches "/led/"
void routeInflate(OSCMessage &msg) {
  Serial.println("Inflate");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    inflatePower = (int) data;
    inflate = true;

  }
}




//called whenever an OSCMessage's address matches "/led/"
void routeDeflate(OSCMessage &msg) {
  Serial.println("Deflate");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    deflatePower = (int) data;
    deflate = true;

  }
}


void routeInflateDur(OSCMessage &msg) {
  Serial.println("Inflate Duration");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    inflateDuration = (int) data;
    //inflate = true;


  }
}





void routeDeflateDur(OSCMessage &msg) {
  Serial.println("Deflate Duration");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    deflateDuration = (int) data;
    //deflate = true;


  }
}






//called whenever an OSCMessage's address matches "/led/"
//void routeVibeEffect(OSCMessage &msg) {
//  Serial.println("Vibe Effect");
//  setEffectMode();
  //returns true if the data in the first position is a float
//  if (msg.isFloat(0)) {
    //get that float
//    float data = msg.getFloat(0);

//    Serial.println(data);
//    effect = data;
//  }
//}

//void setEffectMode() {
//  if (!effectMode) {
//    effectMode = true;
//    drv.setMode(DRV2605_MODE_INTTRIG);
//  }
//}

//void setRTMode() {

//  if (effectMode) {
//    effectMode = false;
//    drv.setMode(DRV2605_MODE_REALTIME);
//  }
//}

//called whenever an OSCMessage's address matches "/led/"
//void routeVibeIntensityRT(OSCMessage &msg) {
//  Serial.println("Vibe Intensity");
  //setRTMode();
  //returns true if the data in the first position is a float
//  if (msg.isFloat(0)) {
    //get that float
//    float data = msg.getFloat(0);

//    Serial.println(data);
//    vibeIntensityRT = data;
//  }
//}

//called whenever an OSCMessage's address matches "/led/"
//void routeVibeDelayRT(OSCMessage &msg) {
//  Serial.println("Vibe Delay");
//  setRTMode();
  //returns true if the data in the first position is a float
//  if (msg.isFloat(0)) {
    //get that float
//    float data = msg.getFloat(0);

//    Serial.println(data);
//    vibeDelayRT = data;
//  }
//}

//void playVibeEffect() {
  // set the effect to play
//  drv.setWaveform(0, effect);  // play effect
//  drv.setWaveform(1, 0);       // end waveform

  // play the effect!
//  drv.go();
//  delay(20);
//}


//void playVibeRT() {
//  drv.setRealtimeValue(vibeIntensityRT);
//  delay(10);
//  drv.setRealtimeValue(0);
//  delay(vibeDelayRT);
//}




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

void inflatepump()

{
digitalWrite(solenoidPin1, HIGH);
digitalWrite(solenoidPin2, LOW);


analogWrite(3, 255);   //Terminal A motor - full speed
analogWrite(11, LOW);   //Termanl B motor - full stop
//Serial.println("Inflate?");
prevstate = 2;



}


void hold()

{
  digitalWrite(3, LOW);   //Terminal A motor - full stop
  analogWrite(11, LOW);   //Termanl B motor - full stop


  digitalWrite(solenoidPin1, HIGH);
  digitalWrite(solenoidPin2, HIGH);
  //Serial.println("Hold?");
  prevstate = 1;
}

void deflatepump()
{

  digitalWrite(solenoidPin1, LOW);
  digitalWrite(solenoidPin2, LOW);


  analogWrite(3, LOW);   //Terminal A motor - full stop
  analogWrite(11, 255);   //Terminal A motor - full speed


  //Serial.println("Deflate?");
  prevstate = 0;

}

void pressure()
{
  float pressure_hPa = mpr.readPressure();
  Serial.print("Pressure (hPa): "); Serial.println(pressure_hPa);
  Serial.print("Pressure (PSI): "); Serial.println(pressure_hPa / 68.947572932);
}

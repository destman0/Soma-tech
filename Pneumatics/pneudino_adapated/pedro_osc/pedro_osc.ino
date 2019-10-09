/*
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
#include <PneuDuino.h>

// If you use the WiFiNINA with the OSC library make sure you remove
// "SLIPEncodedSerial.cpp" and "SLIPEncodedSerial.h" from
// the arduino --> osc library. (#slavic_warrior_solution)

#define I2CPneuAddress 1 //CHANGE THIS VALUE DEPENDING ON HOW YOU WIRED THE PNEUDUINO

boolean inflate = false;
boolean deflate = false;

int inflateSpeed = 0;

boolean wasOff = false; //used to establish connection to server

///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = "serv";        // your network SSID (name)
char pass[] = "";    // your network password (use for WPA, or use as key for WEP)
int status = WL_IDLE_STATUS;     // the WiFi radio's status

unsigned int localPort = 12000;      // local port to listen on
char packetBuffer[255]; //buffer to hold incoming packet
WiFiUDP Udp;


const IPAddress serverIp(192, 168, 0, 140);
const unsigned int serverPort = 32000;

PneuDuino p;

float pressure;

//DEPRECATED VARIABLES --------------------------------------------------
int inflateDuration = 0;
int deflateDuration = 0;
unsigned long currentMillis = 0;
unsigned long previousMillis = 0;
//DEPRECATED VARIABLES END --------------------------------------------------

void setup() {
  //Initialize serial and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  p.setAddressMode(PNEUDUINO_ADDRESS_VIRTUAL);

  //Initialize actuators
  //initialize LED
  pinMode(LED_BUILTIN, OUTPUT);

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

    // wait 10 seconds and blink while trying to connect

    for (int i = 0; i <= 10; i++) {
      digitalWrite(13, HIGH);
      delay(500);
      digitalWrite(13, LOW);
      delay(500);
    }

    digitalWrite(13, HIGH);
    delay(3000);
    digitalWrite(13, LOW);

  }

  // wait 10 seconds and blink while trying to connect
  digitalWrite(13, HIGH);
  delay(3000);
  digitalWrite(13, LOW);


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
  pinMode(12, OUTPUT);    //Channel A Direction Pin Initialize (controlling the motor direction)
  p.begin();
  pinMode(A0, INPUT); //potentiometer
  pinMode(2, INPUT); //power switch
}

void loop() {

  //loop specifically for Pneuduino.

  p.update(); //always AND ONLY called in the beginning

  parseSerialCommands(); //read and parse any commands from serial (e.g. "c" = connect to server)
  readOSCMessage(); //read and parse any possible incoming OSC message from server

  int powerOn = digitalRead(2); //see if power is on. only inflate/deflate if power is on

  //pressure = map(p.readPressure(I2CPneuAddress), 60, 90, 0, 30); //read the pressure value from pneuduino. The original range (60-90) is mapped to 1-30
  //Serial.println(pressure); //DEBUG
  sendOSCPressure(); //send it to server

  //int potentiometer = analogRead(A0); //read value from potentiometer: CURRENTLY NOT DOING ANYTHING WITH IT

  if (powerOn == HIGH)
  {
    if (wasOff) {
      connectToServer();
      wasOff = false;
    }

    if (inflate)
    {
      inflatePump(inflateSpeed);
    }
    if (deflate)
    {
      deflatePump();
    }
  }
  else wasOff = true;
}

void inflatePump(int inflateSpeed) {

  digitalWrite(12, HIGH); //Channel A Direction Forward
  analogWrite(3, inflateSpeed);    //Channel A Speed 100%

  p.inflate(I2CPneuAddress); //method 1
  // p.in(1, LEFT); //method 2
}

void deflatePump() {

  analogWrite(3, 0); //Channel A Speed 0%

  p.deflate(I2CPneuAddress); //method 1
  // p.out(1, LEFT); //method 2
}

//OSC MESSAGE HANDLING FUNCTIONS -----------------------------------------------------------------------------

void readOSCMessage() {
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
      //      bundleIN.dispatch("/actuator/inflatedur", routeInflateDur); //DEPRECATED
      //      bundleIN.dispatch("/actuator/deflatedur", routeDeflateDur);
    }
  }
}

void sendOSCPressure() {
  //the message wants an OSC address as first argument
  OSCMessage msg("/sensor/pressure");
  msg.add(pressure);

  Udp.beginPacket(serverIp, serverPort);
  msg.send(Udp); // send the bytes to the SLIP stream
  Udp.endPacket(); // mark the end of the OSC Packet
  msg.empty(); // free space occupied by message

  delay(20);
}


//called whenever an OSCMessage's address matches "/inflate/": It sets the "inflate" boolean to true and the "inflateSpeed"
void routeInflate(OSCMessage &msg) {
  Serial.println("Inflate");
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);
    Serial.println(data);
    inflateSpeed = (int) data;  //message needs to between 0 and 255
    inflate = true;
    deflate = false;
  }
}

//called whenever an OSCMessage's address matches "/deflate/": opens and closes the valve
void routeDeflate(OSCMessage &msg) {

  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);
    Serial.println(data);

    //deflate
    if ((int) data == 1) {
      Serial.println("Valve control Open");
      deflate = true;
      inflate = false;
    }

    else if ((int) data == 0) {
      //inflate = false;
      deflate = false;
      inflate = true;
      Serial.println("Valve control Closed");
    }
  }
}

//DEPRECATED FUNCTION: LEFT HERE IN CASE PAVEL WANTS IT LATER
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

//DEPRECATED FUNCTION: LEFT HERE IN CASE PAVEL WANTS IT LATER
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

//UTILITY FUNCTIONS ---------------------------------------------------------------------------------------------------------------

void parseSerialCommands() {
  char incomingByte = 0;   // for incoming serial data
  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();
    if (incomingByte == 'c') {
      connectToServer();
      delay(50);
    }
  }
}

void connectToServer() {
  Serial.print("\nConnecting to server bit at ");
  Serial.print(serverIp); Serial.print(":"); Serial.println(serverPort);
  OSCMessage msg("/actuator/startConnection/");
  Udp.beginPacket(serverIp, serverPort);
  msg.send(Udp); // send the bytes to the SLIP stream
  Udp.endPacket();
  msg.empty(); // free space occupied by message

  //must also send a sensorconnect message in case it intends to be a sensor
  //  OSCMessage msg("/sensor/startConnection/");
  //  Udp.beginPacket(serverIp, serverPort);
  //  msg.send(Udp); // send the bytes to the SLIP stream
  //  Udp.endPacket();
  //  msg.empty(); // free space occupied by message
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

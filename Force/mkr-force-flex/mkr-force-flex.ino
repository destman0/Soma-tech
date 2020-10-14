/*
The following code is based on following examples:

https://github.com/adafruit/Adafruit_MPRLS/blob/master/examples/mprls_simpletest/mprls_simpletest.ino
https://github.com/arduino-libraries/MKRMotorCarrier/blob/master/examples/Motor_test/Motor_test.ino
p_sanches Serverbit code

*/



#include <MKRMotorCarrier.h>
#include <Wire.h>
#include "Adafruit_MPRLS.h"
#include <WiFiNINA.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCBundle.h>
#include <OSCBoards.h>

#define RESET_PIN  -1  // set to any GPIO pin # to hard-reset on begin()
#define EOC_PIN    -1  // set to any GPIO pin to read end-of-conversion by pin
Adafruit_MPRLS mpr = Adafruit_MPRLS(RESET_PIN, EOC_PIN);

int inflatePower = 0;

const int fsrPin = 1;     // the number of the force or flex sensor pin

char ssid[] = "serv";        // your network SSID (name)
char pass[] = "somaserv";    // your network password (use for WPA, or use as key for WEP)
int status = WL_IDLE_STATUS;     // the WiFi radio's status

unsigned int localPort = 12000;      // local port to listen on
char packetBuffer[255]; //buffer to hold incoming packet

WiFiUDP Udp;

const IPAddress serverIp(192, 168, 0, 140); // 192, 168, 0, 197 for Kelsey
const unsigned int serverPort = 32000; // 32005 for Kelsey


unsigned long time_now = 0; //in order to keep the time so that we can simulate delay() without blocking the loop() function
int period = 20;  //how often in miliseconds to send the pressure to the server

unsigned long time_now_connect_server = 0; //in order to keep the time so that we can simulate delay() without blocking the loop() function
int period_connect_server = 5000;  //how often in miliseconds to reconnect actuator to server

void setup() {
  // put your setup code here, to run once:
Serial.begin(9600);

//  while (!Serial) {
//    ; // wait for serial port to connect. Needed for native USB port only
//  }

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



}

void loop() {

    char incomingByte = 0;   // for incoming serial data
      if (Serial.available() > 0) {
        // read the incoming byte:
        incomingByte = Serial.read();
        if (incomingByte == 'c') { //if you write 'c' in the command line, it will connect to the server at the specified IP address above
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


    //we send the force/flex values in a OSC message to the server every some miliseconds, specified in the variable 'period'
    
    
    if(millis() > time_now + period){
        time_now = millis();
        sendOSCForce(analogRead(fsrPin));
        Serial.println(analogRead(fsrPin));
    }


    

    //this is just while Pavel does not add physical buttons! WHen he does, delete this code
//     if(millis() > time_now_connect_server + period_connect_server){
//        time_now_connect_server = millis();
//        sendOSCPressure(getPressure());
//        connectToServer();
//        delay(50);
//    }
     
}

void routeInflate(OSCMessage &msg) {
  //returns true if the data in the first position is a float
  if (msg.isFloat(0)) {
    //get that float
    float data = msg.getFloat(0);

    Serial.println(data);
    inflatePower = (int) data;

  }
}

void routeDeflate(OSCMessage &msg) {
}

void routeInflateDur(OSCMessage &msg) {
}

void routeDeflateDur(OSCMessage &msg) {
}




 

void sendOSCPressure(float pressure) {
  //the message wants an OSC address as first argument
  OSCMessage msg("/sensor/pressure");
  msg.add(pressure);

  Udp.beginPacket(serverIp, serverPort);
  msg.send(Udp); // send the bytes to the SLIP stream
  Udp.endPacket(); // mark the end of the OSC Packet
  msg.empty(); // free space occupied by message

  delay(20);
}

// Function for sending force / flex sensor values
void sendOSCForce(float fsr) {
  //the message wants an OSC address as first argument
  OSCMessage msg("/sensor/force");
  msg.add(fsr);

  Udp.beginPacket(serverIp, serverPort);
  msg.send(Udp); // send the bytes to the SLIP stream
  Udp.endPacket(); // mark the end of the OSC Packet
  msg.empty(); // free space occupied by message

  delay(20);
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
  

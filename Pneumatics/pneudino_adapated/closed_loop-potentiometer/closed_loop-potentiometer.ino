//Slightly modified pressure loop based on the following example:
//https://github.com/oujifei/pneuduino/blob/master/examples/PressureRegulator2/PressureRegulator2.ino
//Don't forget to change the number of p() to the number of the corresponding board that you have
//The number can be determined by connecting Master pneuduino board

#include <PneuDuino.h>
//#include <SPI.h>
//#include <WiFiNINA.h>
//#include <WiFiUdp.h>
//#include <OSCMessage.h>
//#include <OSCBundle.h>
//#include <OSCBoards.h>
//#include <Wire.h>
//#include "Adafruit_DRV2605.h"
//#include <PneuDuino.h>
//#include <Wire.h>

PneuDuino p;


// to prevent rapidly switching valves, we only run in intervals
unsigned long time_interval = 100L;
unsigned long last_run;


// the state of our valve
enum valve_states {
  INFLATING,
  HOLDING,
  DEFLATING,
};
int valve_state = DEFLATING;


void setup() {
  Wire.begin();
  pinMode(12,OUTPUT);     //Channel A Direction Pin Initialize
  pinMode(13,OUTPUT); 
  pinMode(A0, INPUT);
  p.begin(); 

  
  Serial.begin(9600);
  p.setAddressMode(PNEUDUINO_ADDRESS_VIRTUAL);
  Serial.print("/n");
}


void loop() {

  
  p.update();

  // if enough time has passed to run again
  if(millis() > last_run + time_interval) {
    // read the potentiometer
    //int pot = p.readPot();
    int pot = analogRead(A0);
    
    // read the actual pressure
    float pressure = p.readPressure(3);
    Serial.print("Actual pressure: ");
    Serial.print(pressure);
    Serial.print("\n");
  
    // set the target pressure as a function of pot position
    //int target = map(pot, 0, 63, 60, 90);
    int target = map(pot, 0, 1023, 60, 90);
    Serial.print("Target pressure: ");
    Serial.print(target);
    Serial.print("\n");

    // adjust valve state depending on pressure
    if(valve_state == HOLDING && pressure > target + 1) {
      // pressure too high, go from holding to deflating
      p.deflate(3);
      digitalWrite(13, HIGH); //Channel B Direction Forward
      analogWrite(3, 0);
      analogWrite(11, 255);
      valve_state = DEFLATING;
      Serial.print("holding to deflating");
      Serial.print("\n");
      p.update();
    }
    if(valve_state == INFLATING && pressure > target) {
      // pressure too high, go from inflating to holding
      p.hold(3);
      analogWrite(3, 0);
      analogWrite(11, 0);
      valve_state = HOLDING;
      Serial.print("inflating to holding");
      Serial.print("\n");
      p.update();
    }
    if(valve_state == DEFLATING && pressure < target) {
      // pressure too low, go from deflating to holding
      p.hold(3);
      analogWrite(3, 0);
      analogWrite(11, 0);
      valve_state = HOLDING;
      Serial.print("deflating to holding");
      Serial.print("\n");
      p.update();
    }
    if(valve_state == HOLDING && pressure < target - 1) {
      // pressure too low, go from holding to inflating
      p.inflate(3);
      digitalWrite(12, HIGH); //Channel A Direction Forward
      analogWrite(3, 255);    //Channel A Speed 100%
      analogWrite(11, 0);
      valve_state = INFLATING;
      Serial.print("holding to inflating");
      Serial.print("\n");
      p.update();
    }
//    else
//    {
//    Serial.print ("Malfunction!");
//    Serial.print("\n");
//    p.update();
//    }
    // reset last run
    last_run = millis();
    Serial.print("Last Run ");
    Serial.print(last_run);
    Serial.print("\n");
  }  
}

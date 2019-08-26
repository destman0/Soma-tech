#include <Encoder.h>
const int relay1 = 12;
const int relay2 = 9;
const int sw1Pin = 4;
const int sw2Pin = 5;

//Set up the linear actuator encoder
//On many of the Arduino boards pins 2 and 3 are interrupt pins
// which provide the best performance of the encoder data.
Encoder myEnc(2, 7); //   avoid using pins with LEDs attached
long oldPosition  = -99999;

void setup() {
  
  //Setup Channel A
  pinMode(relay1, OUTPUT); //Initiates Motor Channel A pin
  pinMode(relay2, OUTPUT); //Initiates Brake Channel A pin
  pinMode(sw1Pin, INPUT_PULLUP);
  pinMode(sw2Pin, INPUT_PULLUP);
  Serial.begin(9600);
  //Setup Channel B

}

void loop(){

  
  int sw1State = digitalRead(sw1Pin); //Read the status of Switch1
  int sw2State = digitalRead(sw2Pin); //Read the status of Switch2

 if (sw1State == LOW) { //If switch1 is pressed
     extendActuator();
  } else {
     if (sw2State == LOW) { //If switch2 is pressed
        retractActuator();
     } else {   //NO SWITCHES pressed.
        stopActuator();
     }
  }

  //check the encoder to see if the position has changed
  long newPosition = myEnc.read();
  if (newPosition != oldPosition) {
    oldPosition = newPosition;
    Serial.println(newPosition);
  }
}

void extendActuator() {
  //Serial.println("extendActuator");
  digitalWrite(relay1, HIGH);
  digitalWrite(relay2, LOW);
  analogWrite(3, 255); 
}

void retractActuator() {
  //Serial.println("retractActuator");
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  analogWrite(3, 255);
}

void stopActuator() {
  //Serial.println("stopActuator");
  digitalWrite(relay2, HIGH);
}

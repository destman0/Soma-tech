const int sw1Pin = 7;
const int sw2Pin = 8;
const int compressor = 6;
const int valve = 11;
 
void setup() {
  pinMode(sw1Pin, INPUT_PULLUP);
  pinMode(sw2Pin, INPUT_PULLUP);
  pinMode(compressor, OUTPUT);
  pinMode(valve, OUTPUT);
  Serial.begin(9600);
}
 
void loop() {
  // put your main code here, to run repeatedly:
  int sw1State = digitalRead(sw1Pin); //Read the status of Switch1
  int sw2State = digitalRead(sw2Pin); //Read the status of Switch2

 if (sw1State == LOW) { //If switch1 is pressed
     inhaleAir();
  } else {
     if (sw2State == LOW) { //If switch2 is pressed
        exhaleAir();
     } else {   //NO SWITCHES pressed.
        stopAir();
     }
  }
}

void inhaleAir() {
  Serial.println("Inhale");
  digitalWrite(compressor, HIGH); 
  digitalWrite(valve, LOW);

}

void exhaleAir() {
  Serial.println("exhale");
  digitalWrite(compressor, LOW);
  digitalWrite(valve, HIGH); 
}

void stopAir() {
  Serial.println("stop");
  digitalWrite(compressor, LOW);
  digitalWrite(valve, LOW); 
}

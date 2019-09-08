
int sensorValue = 0;

void setup() {
  // put your setup code here, to run once:
Serial.begin(9600);  
}

void loop() {
  // put your main code here, to run repeatedly:
sensorValue = analogRead(A0);
Serial.print(0);  // To freeze the lower limit
Serial.print(" ");
Serial.print(1023);  // To freeze the upper limit
Serial.print(" ");
Serial.println(sensorValue);
}

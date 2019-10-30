void setup() {
  // put your setup code here, to run once:
pinMode(A1, INPUT);
Serial.begin(9600);

}

void loop() {
  // put your main code here, to run repeatedly:
int sensorValue = analogRead(A1);
Serial.print(0);  // To freeze the lower limit
Serial.print(" ");
Serial.print(1000);  // To freeze the upper limit
Serial.print(" ");
Serial.println(sensorValue);
}

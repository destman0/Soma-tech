int heat_intensity = 128;
int button_status = LOW;

void setup() {
pinMode(12, OUTPUT); //Initiates Motor Channel A pin
pinMode(9, OUTPUT); //Initiates Brake Channel A pin
pinMode(A5, INPUT);
pinMode(10, OUTPUT);
pinMode (5, INPUT);
}


void loop() {

  digitalWrite(12, HIGH); //Establishes forward direction of Channel A
  digitalWrite(9, LOW);   //Disengage the Brake for Channel A
  button_status = digitalRead(5);
  
  //for (int i=0; i <= 1000; i++)
  //{
  int readingA5 = analogRead(A5);
  heat_intensity = map(readingA5, 0, 1023, 0, 255);
  if (button_status==HIGH)
  {
  analogWrite(3, heat_intensity);   //Spins the motor on Channel A at full speed  
  digitalWrite(10, HIGH);
  }
  else
  digitalWrite(10, LOW);
  //delay(10);
  //}
  
  //digitalWrite(9, HIGH); //Eengage the Brake for Channel A
  //digitalWrite(10, LOW);

  

  //delay(5000);






}





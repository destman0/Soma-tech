int solenoidPin1 = 9;                    //This is the output pin on the Arduino
int solenoidPin2 = 8;  

void setup() 
{
  pinMode(solenoidPin1, OUTPUT);  
  pinMode(solenoidPin2, OUTPUT);  
  Serial.begin(9600);//Sets that pin as an output
}

void loop() 
{
  digitalWrite(solenoidPin1, HIGH);      //Switch Solenoid ON
  digitalWrite(solenoidPin2, LOW);   
  Serial.println("CLICK");
  delay(1000);                          //Wait 1 Second
  digitalWrite(solenoidPin1, LOW);       //Switch Solenoid OFF
  digitalWrite(solenoidPin2, HIGH); 
  Serial.println("UNCLICK");
  delay(1000);                          //Wait 1 Second
}

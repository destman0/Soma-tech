const int forwards = 5;
const int backwards = 6;//assign relay INx pin to arduino pin

void setup() {
 
pinMode(forwards, OUTPUT);//set relay as an output
pinMode(backwards, OUTPUT);//set relay as an output

}



void loop() {
  // put your main code here, to run repeatedly:
digitalWrite(forwards, HIGH);
 digitalWrite(backwards, HIGH);//Activate the relay one direction, they must be different to move the motor


}

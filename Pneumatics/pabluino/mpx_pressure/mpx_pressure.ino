/*
  ReadAnalogVoltage

  Reads an analog input on pin 0, converts it to voltage, and prints the result to the Serial Monitor.
  Graphical representation is available using Serial Plotter (Tools > Serial Plotter menu).
  Attach the center pin of a potentiometer to pin A0, and the outside pins to +5V and ground.

  This example code is in the public domain.

  http://www.arduino.cc/en/Tutorial/ReadAnalogVoltage
*/

// the setup routine runs once when you press reset:
void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
}

// the loop routine runs over and over again forever:
void loop() {
  // read the input on analog pin 0:
  int sensorValue = analogRead(A0);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
  float voltage = sensorValue * (5 / 1024.0);
  float presskpa= 20 + voltage*1000/12.1;
  //12.1mV/kpa

  
  //example from forum, can be useless
  //float voltage = map(sensorValue, 0, 4095, 0, 328);
  //float pressure = ((voltage/3.31)+0.00842)/0.002421;
  

  float pressure = ((voltage / 5)+0.00842)/0.002421;
  //int package =  map(pressure, 0, 1023, 0, 255);
  //Serial.println(pressure);
  Serial.print(presskpa);
  Serial.print("kPa @");

  Serial.print(pressure);
  Serial.print("kPa @");
  
  Serial.print(voltage);
  Serial.println("V");
}


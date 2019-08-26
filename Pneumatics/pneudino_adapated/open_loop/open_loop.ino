#include <PneuDuino.h>
#include <Wire.h>
//#include <MotorDriver.h>


extern "C" { 
#include "utility/twi.h"  // from Wire library, so we can do bus scanning
}

// Scan the I2C bus between addresses from_addr and to_addr.
// On each address, call the callback function with the address and result.
// If result==0, address was found, otherwise, address wasn't found
// (can use result to potentially get other status on the I2C bus, see twi.c)
// Assumes Wire.begin() has already been called
//void scanI2CBus(byte from_addr, byte to_addr, 
//                void(*callback)(byte address, byte result) ) 
//{
//  byte rc;
//  byte data = 0; // not used, just an address to feed to twi_writeTo()
//  for( byte addr = from_addr; addr <= to_addr; addr++ ) {
//    rc = twi_writeTo(addr, &data, 0, 1, 0);
//    callback( addr, rc );
//  }
//}

// Called when address is found in scanI2CBus()
// Feel free to change this as needed
// (like adding I2C comm code to figure out what kind of I2C device is there)
//void scanFunc( byte addr, byte result ) {
//  Serial.print("addr: ");
//  Serial.print(addr,DEC);
//  Serial.print( (result==0) ? " found!":"       ");
//  Serial.print( (addr%4) ? "\t":"\n");
//}


byte start_address = 8;       // lower addresses are reserved to prevent conflicts with other protocols
byte end_address = 119;       // higher addresses unlock other modes, like 10-bit addressing
PneuDuino p;



//MotorDriver motor;

void setup()
{
    // initialize
    //motor.begin();
    Wire.begin();
    pinMode(12,OUTPUT);     //Channel A Direction Pin Initialize
    pinMode(13,OUTPUT);
    p.begin(); 

Serial.begin(9600);                   // Changed from 19200 to 9600 which seems to be default for Arduino serial monitor
    //Serial.println("\nI2CScanner ready!");

    //Serial.print("starting scanning of I2C bus from ");
    //Serial.print(start_address,DEC);
    //Serial.print(" to ");
    //Serial.print(end_address,DEC);
    //Serial.println("...");

    // start the scan, will call "scanFunc()" on result from each address
    //scanI2CBus( start_address, end_address, scanFunc );

    //Serial.println("\ndone");
    
    // Set pin mode so the loop code works ( Not required for the functionality)
    //pinMode(13, OUTPUT);
    pinMode(A0, INPUT);
    pinMode(2, INPUT);


    
}

void loop()
{
    int reading2 = digitalRead(2);
    int readingA0 = analogRead(A0);

    if(reading2 == HIGH)  
    {

    //p.update();   
    int mult = map(readingA0, 1023, 0, 1, 10);
    //int x  = p.readPressure(1);
    Serial.print(mult);
    Serial.print("\n");
    //motor.speed(0, 100);  
      //analogWrite(3, 0);      //Channel A Speed 0%
      //delay(100);             //100ms Safety Delay
      
      //delay(1000);            //1 Second Delay

    //p.in(1, LEFT);
    p.inflate(3);
    digitalWrite(12, HIGH); //Channel A Direction Forward
    digitalWrite(13, HIGH);
    analogWrite(3, 255);    //Channel A Speed 100%
    analogWrite(11,0);
    p.update(); 
    delay(mult*1000);
    readingA0 = analogRead(A0);
    mult = map(readingA0, 1023, 0, 1, 10);
    //motor.brake(0);                 // brake
    p.hold(3);
    analogWrite(3, 0);
    analogWrite(11, 0);
    delay(mult*1000);
    readingA0 = analogRead(A0);
    mult = map(readingA0, 1023, 0, 1, 10);
    //p.out(1, LEFT);
    p.deflate(3);
    analogWrite(11,255);
    analogWrite(3,0);
    p.update(); 
    delay(mult*1000);
    readingA0 = analogRead(A0);
    mult = map(readingA0, 1023, 0, 1, 10);
    //motor.stop(0);                  // stop
    //p.in(1, LEFT);
    p.hold(3);
    analogWrite(11,0);
    analogWrite(3,0);
    delay(mult*1000);
    }
    else
    {  
    //motor.stop(0);  
      }
}

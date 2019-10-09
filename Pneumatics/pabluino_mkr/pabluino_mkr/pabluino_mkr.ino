#include <MKRMotorCarrier.h>


void setup() {
  // put your setup code here, to run once:
Serial.begin(115200);
  if (controller.begin()) 
    {
      Serial.print("MKR Motor Shield connected, firmware version ");
      Serial.println(controller.getFWVersion());
    } 
  else 
    {
      Serial.println("Couldn't connect! Is the red led blinking? You may need to update the firmware with FWUpdater sketch");
      while (1);
    }

}

void loop() {
  // put your main code here, to run repeatedly:
    M1.setDuty(50);
    M2.setDuty(50);
    M3.setDuty(40);
    M4.setDuty(40);
}

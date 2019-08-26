/**
   TCA9548 I2CScanner.pde -- I2C bus scanner for Arduino

   Based on code c. 2009, Tod E. Kurt, http://todbot.com/blog/

*/

#include "Wire.h"

#include "Adafruit_DRV2605.h"

extern "C" {
#include "utility/twi.h"  // from Wire library, so we can do bus scanning
}

#define TCAADDR 0x70

Adafruit_DRV2605 drv1, drv2;


void tcaselect(uint8_t i) {
  if (i > 7) return;

  Wire.beginTransmission(TCAADDR);
  Wire.write(1 << i);
  Wire.endTransmission();
}


// standard Arduino setup()
void setup()
{
  while (!Serial);
  delay(1000);

  Wire.begin();

  Serial.begin(115200);
  Serial.println("\nTCAScanner ready!");


  tcaselect(1);
  drv1.begin();
  drv1.selectLibrary(1);
  //drv.useLRA();
  drv1.setMode(DRV2605_MODE_INTTRIG);

  tcaselect(2);
  drv2.begin();
  drv2.selectLibrary(1);
  //drv.useLRA();
  drv2.setMode(DRV2605_MODE_INTTRIG);

  //retarded shit
  uint8_t effect = 84;
  //drv.setWaveform(0, effect);  // play effect
  //drv.setWaveform(1, 0);       // end waveform

  //end of it



  for (uint8_t t = 0; t < 8; t++) {
    tcaselect(t);
    Serial.print("TCA Port #"); Serial.println(t);

    for (uint8_t addr = 0; addr <= 127; addr++) {
      if (addr == TCAADDR) continue;

      uint8_t data;
      if (! twi_writeTo(addr, &data, 0, 1, 1)) {
        Serial.print("Found I2C 0x");  Serial.println(addr, HEX);
      }
    }
  }
  Serial.println("\ndone");
}







void loop()
{
  tcaselect(1);
  Serial.print("Driver 1 selected. ");
  //Serial.print("Effect #"); Serial.println(effect);

  // set the effect to play
  drv1.setWaveform(0, 1);  // play effect
  drv1.setWaveform(1, 0);       // end waveform

  // play the effect!
  drv1.go();
  Serial.println("Motor 1 running.");

  // wait a bit
  delay(3000);
  Serial.print("Initiating a delay for 5 second. ");
  drv1.stop();
  Serial.println("Motor 1 stop");
  delay(2000);

  tcaselect(6);
  Serial.print("Driver 6 selected");
  //Serial.print("Effect #"); Serial.println(effect);

  // set the effect to play
  drv2.setWaveform(0, 1);  // play effect
  drv2.setWaveform(1, 0);       // end waveform

  // play the effect!
  drv2.go();
  Serial.print("Motor 6 running");

  // wait a bit
  delay(5000);
  Serial.print("Initiating a delay for 1 second");
  drv2.stop();
  Serial.println("Motor 6 stop");
  //effect++;
  //if (effect > 117) effect = 1;

  //  tcaselect(2);
  //  Serial.print("Driver 2 selected");
  //  drv2.setWaveform(0, 12);  // play effect
  //drv2.setWaveform(1, 0);       // end waveform
  //Serial.print("Effect #"); Serial.println(12);
  ////drv.setWaveform(0, 84);  // play effect
  ////drv.setWaveform(1, 0);
  //  drv2.go();
  //  Serial.print("Motor 2 running");
  //  delay(1000);
  //  Serial.print("Initiating a delay for 1 second");
  //  //drv.stop();
  //  Serial.print("Motor 2 stop");
  //  tcaselect(1);
  //  drv.setWaveform(0, 84);  // play effect
  //drv.setWaveform(1, 0);       // end waveform
  //  drv.go();
  //  delay(1000);
  //  drv.stop();
  //  tcaselect(4);
  //  drv.setWaveform(0, 84);  // play effect
  //drv.setWaveform(1, 0);       // end waveform
  //  drv.go();
  //  delay(1000);
  //  drv.stop();
  //  tcaselect(5);
  //  drv.setWaveform(0, 12);  // play effect
  //drv.setWaveform(1, 0);       // end waveform
  //  drv.go();
  //  delay(1000);
  //  drv.stop();

}

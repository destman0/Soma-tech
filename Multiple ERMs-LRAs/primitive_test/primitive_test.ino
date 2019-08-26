#include "Wire.h"
#include "Adafruit_DRV2605.h"

extern "C" {
#include "utility/twi.h"  // from Wire library, so we can do bus scanning
}

#define TCAADDR 0x70
Adafruit_DRV2605 drv1;

uint8_t effect = 53;

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


  tcaselect(0);
  drv1.begin();


  for (int i = 0; i < 6; i++) {
    tcaselect(i);
    drv1.selectLibrary(1);
    drv1.useERM();
    drv1.setMode(DRV2605_MODE_INTTRIG);
    drv1.setWaveform(0, 84);  // ramp up medium 1, see datasheet part 11.2
    drv1.setWaveform(1, 1);  // strong click 100%, see datasheet part 11.2
    drv1.setWaveform(2, 0);  // end of waveforms
  }


  //retarded shit

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
drv1.go();
  //for (int i = 0; i < 6; i++) {
tcaselect(0);
tcaselect(1);
//delay(1000);
tcaselect(2);
tcaselect(3);
//delay(1000);
tcaselect(4);
tcaselect(5);
//delay(1000);
    //Serial.print("Driver "); Serial.print(i); Serial.println(" selected. ");

    //drv1.go();
    //delay(3000);
    //drv1.stop();
//  }
  //delay(6000);
}


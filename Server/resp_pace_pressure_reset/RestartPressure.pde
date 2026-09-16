PressureReset pressureReset=new PressureReset();
void restartAtPressure(){
  stopBreathing();
  pressureReset.start(System.nanoTime()/1000000,breath.values[2],(float)breath.values[4]);
  notice="One deflation using the selected duration and strength. Stop cancels.";
  tickPressureReset();
}
void tickPressureReset(){
  float command=pressureReset.update(System.nanoTime()/1000000);
  // Deflate only the shared pillow device. Normal sessions retain legacy broadcasts.
  if(!captureMode()){
    OscMessage m=new OscMessage("/actuator/inflate");m.add(command);sendToOneActuator(m,PRESSURE_DEVICE_ID);
  }
  if(pressureReset.reached){startBreathing();notice="Deflation finished. 10 seconds to settle in.";}
}

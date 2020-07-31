/**
 * SOMA BITS broadcasting server
 * Created 2019-02-26
 * by p_sanches
 *
 * /sensor/[sid]/[anypath] [float]
 * /actuator/[sid]/[anypath] [float]
 *
 * Based on:
 *
 * oscP5broadcaster by andreas schlegel
  * an osc broadcast server.
 * osc clients can connect to the server by sending a connect and
 * disconnect osc message as defined below to the server.
 * incoming messages at the server will then be broadcasted to
 * all connected clients.
 * an example for a client is located in the oscP5broadcastClient exmaple.
 * oscP5 website at http://www.sojamo.de/oscP5
 * Let me test this workstation
 */

 //pavels IP: 140

import oscP5.*;
import netP5.*;
import java.io.*;
import java.util.*;
import java.text.*;
import controlP5.*;
import processing.sound.*;
import signal.library.*;

// -----------------------------------------------------
// Create the filter
   SignalFilter myFilter;
// -----------------------------------------------------


float minCutoff = 0.05; // decrease this to get rid of slow speed jitter
float beta      = 7.0;  // increase this to get rid of high speed lag


//NEVER SET MORE THAN ONE OF THESE TO TRUE! Each coupling can only be run separately
boolean interact1 = false;
boolean interact2 = false;
boolean interact3 = false;
boolean deflatall = false;
boolean stopall = false;


//----------------------------------------------Each coupling has to be run separately


int firstCouplingSensorId = 0;
int secondCouplingSensorId = 0;
int thirdCouplingSensorId = 0;
int fourthCouplingSensorId = 0;

int overrideTime;
boolean overrideCoupling = false;
int overrideWait = 10;

int onlyActuateTime;
boolean onlyActuate = false;
int onlyActuateWait = 0;

int waitForPressureTime;
boolean waitForPressure = false;
int waitForPressureWait = 0;

boolean calibrated = false;
boolean in_phase = false;

//import org.apache.commons.collections4.*;

boolean fileStarted=false;

//These are variables for doing sound coupling
SinOsc[] sineWaves; // Array of sines
float[] sineFreq; // Array of frequencies
int numSines = 5; // Number of oscillators to use


OscP5 oscP5;
NetAddressList SensorNetAddressList = new NetAddressList();
NetAddressList ActuatorNetAddressList = new NetAddressList();

int indexIP = 0;

enum DeviceRole {
    Sensor,
    Actuator,
    Both
};
class Device {
    int id;
    DeviceRole role;
    Device(int id, DeviceRole role) {
        this.id = id;
        this.role = role;
    }
    boolean isSensor() {
        return role == DeviceRole.Sensor || role == DeviceRole.Both;
    }
    boolean isActuator() {
        return role == DeviceRole.Actuator || role == DeviceRole.Both;
    }
};
HashMap<String, Device> DeviceIPs = new HashMap<String, Device>();
{{
  DeviceIPs.put("192.168.0.11", new Device(1, DeviceRole.Both));
  DeviceIPs.put("192.168.0.12", new Device(2, DeviceRole.Both));
  DeviceIPs.put("192.168.0.13", new Device(3, DeviceRole.Both));
  DeviceIPs.put("192.168.0.14", new Device(4, DeviceRole.Both));
  DeviceIPs.put("192.168.0.15", new Device(5, DeviceRole.Both));
}}

Map<String, Device> getActuators() {
    Map<String, Device> result = new HashMap<String, Device>();
    for (Map.Entry<String, Device> entry : DeviceIPs.entrySet()) {
        if (entry.getValue().isActuator()) {
            result.put(entry.getKey(), entry.getValue());
        }
    }
    return result;
}

Map<String, Device> getSensors() {
    Map<String, Device> result = new HashMap<String, Device>();
    for (Map.Entry<String, Device> entry : DeviceIPs.entrySet()) {
        if (entry.getValue().isSensor()) {
            result.put(entry.getKey(), entry.getValue());
        }
    }
    return result;
}

NetAddress wekinator;

//data structure to hold all sensor data
HashMap<String,Object[]> sensorInputs = new HashMap<String,Object[]>();

HashMap<String,Object[]> actuatorInputs = new HashMap<String,Object[]>();

int buttonStatus = 0;

/* listeningPort is the port the server is listening for incoming messages */
int myListeningPort = 32000;
/* the broadcast port is the port the clients should listen for incoming messages from the server*/
int myBroadcastPort = 12000;

String SensorConnectPattern = "/sensor/startConnection/";
String SensorDisconnectPattern = "/sensor/endConnection/";

String ActuatorConnectPattern = "/actuator/startConnection/";
String ActuatorDisconnectPattern = "/actuator/endConnection/";

String wekaPattern = "/wek/outputs";

String riotPattern= "/0/";

ControlP5 cp5;

Textarea myTextarea1, myTextarea2;
Knob myKnobA;


PrintWriter output;

int myColor = color(255);
int c1,c2;

float n,n1;

int framefile= 0;


int num = 50;
float[] arrayOfFloats = new float[num];

Interaction breathMirroring1;
Interaction breathMirroring2;
Interaction hrvBreathing;
Interaction squareBreathing ;
Interaction deflateAll;
Interaction stopAll;

void setup() {
  oscP5 = new OscP5(this, myListeningPort);
  wekinator = new NetAddress("127.0.0.1",6448);

  // connectActuator("127.0.0.1");
  size(1600,800);
  smooth();

  noStroke();
  cp5 = new ControlP5(this);


  cp5.addButton("Breath_Mirroring_1")
     .setValue(0)
     .setPosition(100, 50)
     .setSize(600,90)
     ;

  cp5.addButton("Square_Breathing")
    .setValue(100)
    .setPosition(100, 150)
    .setSize(600,90)
    ;

  cp5.addButton("Breath_Mirroring_2")
    .setValue(0)
    .setPosition(100,250)
    .setSize(600,90)
    ;

  cp5.addButton("Slow_HRV_Breathing")
     .setValue(100)
     .setPosition(100, 350)
     .setSize(600,90)
     ;

    cp5.addButton("Deflate_All_Pillows")
     .setValue(100)
     .setPosition(100,450)
     .setSize(600,90)
     .setColorBackground(0xff008888)
     ;

   cp5.addButton("Stop_All_Pillows")
     .setValue(100)
     .setPosition(100, 550)
     .setSize(600,90)
     //.setColor(cc)
     .setColorBackground(0xff880000)
     ;

   cp5.addSlider("Number_of_Cycles")
     .setPosition(20,170)
     .setSize(50,420)
     .setRange(1,10)
     .setValue(3)
     .setNumberOfTickMarks(10)
     .setVisible(false)
     ;
     
     
   cp5.addSlider("Duration_of_Exercise")
     .setPosition(20,170)
     .setSize(50,420)
     .setRange(1,60)
     .setValue(20)
     .setNumberOfTickMarks(60)
     .setVisible(false)
     ;
     
     
   cp5.addSlider("Inflation_Rate")
     .setPosition(750,100)
     .setSize(50,420)
     .setRange(0,100)
     .setValue(50)
     .setNumberOfTickMarks(11)
     .setVisible(false)
     ;  
     
     
   cp5.addSlider("Deflation_Rate")
     .setPosition(850,100)
     .setSize(50,420)
     .setRange(0,100)
     .setValue(100)
     .setNumberOfTickMarks(11)
     .setVisible(false)
     ;

  myTextarea1 = cp5.addTextarea("sensorval")
                    .setPosition(100, 650)
                    .setSize(600, 110)
                    .setFont(createFont("arial",12))
                    .setLineHeight(11)
                    .setColor(color(128))
                    .setColorBackground(color(255,100))
                    .setColorForeground(color(255,100));
                    ;

  myTextarea2 = cp5.addTextarea("instructions")
                    .setPosition(950,100)
                    .setSize(600,600)
                    .setFont(createFont("arial",50))
                    .setLineHeight(50)
                    .setColor(color(128))
                    .setColorBackground(color(255,100))
                    .setColorForeground(color(255,100));
                    ;
                    
  myKnobA = cp5.addKnob("Inhale_or_Exhale_Duration")
               .setRange(5,7)
               .setValue(5.45)
               .setPosition(750,600)
               .setRadius(70)
               .setNumberOfTickMarks(40)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setDragDirection(Knob.HORIZONTAL)
               .setVisible(false)
               ;                

  cp5.addToggle("in_phase")
     .setPosition(20,100)
     .setSize(50,30)
     .setValue(true)
     ;

  frameRate(60);

  //set up sound coupling
  sineWaves = new SinOsc[numSines]; // Initialize the oscillators
  sineFreq = new float[numSines]; // Initialize array for Frequencies

  for (int i = 0; i < numSines; i++) {
    // Calculate the amplitude for each oscillator
    float sineVolume = (1.0 / numSines) / (i + 1);
    // Create the oscillators
    sineWaves[i] = new SinOsc(this);
    // Start Oscillators
    // sineWaves[i].play();
    // Set the amplitudes for all oscillators
    sineWaves[i].amp(sineVolume);
  }

  myFilter = new SignalFilter(this);

  ActuatorNetAddressList.add(new NetAddress("127.0.0.1", myBroadcastPort));
  for (Map.Entry<String, Device> sensor : getSensors().entrySet()) {
    SensorNetAddressList.add(new NetAddress(sensor.getKey(), myBroadcastPort));
  }
  for (Map.Entry<String, Device> actuator : getActuators().entrySet()) {
    ActuatorNetAddressList.add(new NetAddress(actuator.getKey(), myBroadcastPort));
  }
  breathMirroring1 = new BreathMirroring(new SoundFile(this, "Breathing-1-instructions.mp3"),
                                         new SoundFile(this, "Breathing-1-exercise.mp3"));

  breathMirroring2 = new BreathMirroring(new SoundFile(this, "Breathing-2-instructions.mp3"),
                                         new SoundFile(this, "Breathing-2-exercise.mp3"));

  hrvBreathing = new HrvBreathing();

  squareBreathing = new SquareBreathing();

  deflateAll = new DeflateAll();

  stopAll = new StopAll();
}

Measurement currentMeasurement;


Interaction currentInteraction = null;

void selectInteraction(Interaction newInteraction) {
  if (newInteraction != null && newInteraction != currentInteraction) {
    if (currentInteraction != null) {
      currentInteraction.teardown(cp5);
    }
    currentInteraction = newInteraction;
    currentInteraction.prepare(currentMeasurement, cp5);
  }
}

public void Breath_Mirroring_1() {
  selectInteraction(breathMirroring1);
}

public void Breath_Mirroring_2() {
  selectInteraction(breathMirroring2);
}

public void Slow_HRV_Breathing() {
  selectInteraction(hrvBreathing);
}
public void Square_Breathing() {
  selectInteraction(squareBreathing);
}

public void Deflate_All_Pillows() {
  selectInteraction(deflateAll);
}

public void Stop_All_Pillows() {
  selectInteraction(stopAll);
}

Measurement readInputs() {
  return new Measurement(System.currentTimeMillis(),
                         readFloat("1/pressure", 0.0),
                         readFloat("2/pressure", 0.0),
                         readFloat("3/pressure", 0.0),
                         readFloat("4/pressure", 0.0),
                         readFloat("5/pressure", 0.0),
                         buttonStatus
                         );
}

void sendOutputValues(Output out) {
  sendTo(1, out.pressure1);
  sendTo(2, out.pressure2);
  sendTo(3, out.pressure3);
  sendTo(4, out.pressure4);
  sendTo(5, out.pressure5);
}

void sendTo(int device, float value) {
  OscMessage message = new OscMessage("/actuator/inflate");
  message.add(clip(value, -100, 100));
  sendToOneActuator(message, device);
}

void draw() {
  background(color(0, 0, 30));

  currentMeasurement = readInputs();

  myTextarea1.setText("Pressure in the bit number one:    " + (currentMeasurement.pressure1) + " \n\n"
      + "Pressure in the bit number two:     " + (currentMeasurement.pressure2) + " \n\n"
      + "Pressure in the bit number three:   " + (currentMeasurement.pressure3) + "\n\n"
      + "Pressure in the bit number four:    " + (currentMeasurement.pressure4) + "\n\n"
      + "Pressure in the bit number five:    " + (currentMeasurement.pressure5) + "\n\n"
      + "Button state:                       " + buttonStatus
  );

  Output output = currentInteraction != null
    ? currentInteraction.run(currentMeasurement)
    : null;

  if (output != null) {
    sendOutputValues(output);
  }
}

class DeflateAll implements Interaction {
  public void prepare(Measurement initialState, ControlP5 cp5) {}

  public Output run(Measurement inputs) {
    return new Output(-100.0,
                      -100.0,
                      -100.0,
                      -100.0,
                      -100.0
                      );
  }

  public void teardown(ControlP5 cp5) {
    OscMessage myMessage1;
    myMessage1 = new OscMessage("/actuator/inflate");
    myMessage1.add(0.0);
    sendToAllActuators(myMessage1);
  }
}

class StopAll implements Interaction {
  public void prepare(Measurement initialState, ControlP5 cp5) {}

  public Output run(Measurement inputs) {
    myTextarea2.setText("Stop!");
    OscMessage myMessage1;
    myMessage1 = new OscMessage("/actuator/inflate");
    myMessage1.add(0.0);
    sendToAllActuators(myMessage1);
    return null;
  }

  public void teardown(ControlP5 cp5) {}
}

// OSC handling
void oscEvent(OscMessage theOscMessage) {
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(SensorConnectPattern)) {
    // connectSensor(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(SensorDisconnectPattern)) {
    // disconnectSensor(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(ActuatorConnectPattern)) {
      println("Connect actuator message " + theOscMessage);
    // connectActuator(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(ActuatorDisconnectPattern)) {
    // disconnectActuator(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(riotPattern)) {
    //custom code to deal with it (replace function when needed)
    println("RIOT is online!");
  }
  /**
   * if pattern matching was not successful, then broadcast the incoming
   * message to all actuators in the ActuatorAddresList.
   */
   //check if sender is on sensor list (TBD: currently any OSC command is just blindly forwarded to the actuators without checking)

    else if (theOscMessage.addrPattern().contains("/sensor/buttonstate")) {
      buttonStatus = ((Float)theOscMessage.arguments()[0]).intValue();
    }
    else if(theOscMessage.addrPattern().contains("/sensor")){

    //add it to a data structure with all known OSC addresses (hashmap: addrPattern, arguments)
    addSensorValuetoHashMap(theOscMessage);

    //printAllSensorInputs();

    //optionally do something else with it, e.g. wekinator, store data, smart data layer
    //trainWekinatorMsg(theOscMessage);
    //trainWekinatorWithAllSensors();

    //printOSCMessage(theOscMessage);
    //oscP5.send(theOscMessage, ActuatorNetAddressList);
    //sendAllSensorData();
  }
  else if(theOscMessage.addrPattern().contains("/actuator")){
      println("Actuator message");
    int id = messageContainsID(theOscMessage);

    if(id == -1)
      sendToAllActuators(theOscMessage);
    else{
      theOscMessage.setAddrPattern(cleanActuatorPattern(theOscMessage));
      sendToOneActuator(theOscMessage,id);
    }
    //printOSCMessage(theOscMessage);

    //stop couplings for a while
    overrideCoupling = true;
    overrideTime = millis();
  }
  else{
   // print("## Sending OSC Message directly to Wekinator");
    //printOSCMessage(theOscMessage);
   // trainWekinatorMsg(theOscMessage);
  }
}

private void addToSensorInputs(String osckey, Object[] values){
  if(sensorInputs.put(osckey,values) == null && fileStarted){
    println("Received a new sensor: ENDING FILE PREMATURELY");
  }
}

private int messageContainsID(OscMessage theOscMessage){

  String[] addrComponents = theOscMessage.addrPattern().split("/");
  //"_/[actuator]/[id]"s

    try
    {
            // checking valid integer using parseInt() method
            return Integer.parseInt(addrComponents[2]);
    }
    catch (Exception e) //this means that it is not an integer and then it is meant for all actuators
    {
       return -1;
    }
}

private String cleanActuatorPattern(OscMessage theOscMessage){

  String[] addrComponents = theOscMessage.addrPattern().split("/");
  String[] newAddress = new String[addrComponents.length-1];
  //"_/[actuator]/[id]"

    try
    {
            // checking valid integer using parseInt() method
            Integer.parseInt(addrComponents[2]);

            for(int i=0, j=0;i<newAddress.length;i++,j++){
              if(i==2) i++;
              newAddress[j] = addrComponents[i];
            }

            return join(newAddress,"/");
    }
    catch (Exception e) //this means that it is not an integer and then it is meant for all actuators
    {
       return theOscMessage.addrPattern();
    }

}


// /sensor/x becomes /[id]/sensor/x
void addSensorValuetoHashMap(OscMessage theOscMessage){
  int id = getDeviceId(theOscMessage.netAddress());
//  if(id == -1)
//    id = connectSensor(theOscMessage.netAddress().address());



  //remove the "/sensor" part
  String[] addrComponents = theOscMessage.addrPattern().split("/");

  // System.out.println("## PRINTING addrComponents");
  // for (String a : addrComponents)
  //           System.out.println(a);

  String[] address = new String[addrComponents.length-1];

  address[0] = Integer.toString(id);

  for(int i=2;i<addrComponents.length; i++){ //i starts at 2 to jump past the initial blankspace "" and the word "sensor"
    address[i-1] = addrComponents[i];
  }
  String sensorId = join(address,"/");
  addToSensorInputs(sensorId, theOscMessage.arguments());
}

int getDeviceId(NetAddress address){
  Device device = DeviceIPs.get(address.address());
  return (device != null) ? device.id : - 1;
}

String getDeviceAddress(int id){
  for (HashMap.Entry<String, Device> entry : DeviceIPs.entrySet()) {
    if (entry.getValue().id == id) {
       return(entry.getKey());
    }
  }
  return null;
}


void sendToOneActuator(OscMessage theOscMessage, int id){

  // System.out.println("## Sending to one actuator with ID "+ id);

  String addr = getDeviceAddress(id);
  if(addr==null){
    // System.out.println("## ERROR: Actuator with ID "+ id+ " not found");
    return;
  }

  NetAddress actuatorNetAddress = ActuatorNetAddressList.get(addr,myBroadcastPort);
  if(actuatorNetAddress==null){
    // System.out.println("## ERROR: Actuator with ID "+ id+ " not found");
    return;
  }

  /* create an osc bundle */
  OscBundle myBundle = new OscBundle();
  myBundle.add(theOscMessage);

  myBundle.setTimetag(myBundle.now() + 10000);
  // println("Sending to " + id + " at " + actuatorNetAddress.address() + " message " + theOscMessage);
  /* send the osc bundle, containing 1 osc messages, to all actuators. */
  oscP5.send(myBundle, actuatorNetAddress);
}

void sendToAllActuators(OscMessage theOscMessage){

  
    //System.out.println("## Sending to ALL actuators");

    /* create an osc bundle */
  OscBundle myBundle = new OscBundle();
  myBundle.add(theOscMessage);

  myBundle.setTimetag(myBundle.now() + 10000);
  /* send the osc bundle, containing 1 osc messages, to all actuators. */
  oscP5.send(myBundle, ActuatorNetAddressList);
}

void sendAllRawSensorData(){

    /* create an osc bundle */
  OscBundle myBundle = new OscBundle();
  OscMessage myMessage = new OscMessage("");

   for (Map.Entry me : sensorInputs.entrySet()) {
       myMessage.setAddrPattern( (String) me.getKey());
       myMessage.setArguments ( (Object[])me.getValue() );

        /* add an osc message to the osc bundle */
        myBundle.add(myMessage);

         /* reset and clear the myMessage object for refill. */
        myMessage.clear();
    }

  myBundle.setTimetag(myBundle.now() + 10000);
  /* send the osc bundle, containing 2 osc messages, to a remote location. */
  oscP5.send(myBundle, ActuatorNetAddressList);

}

void printAllSensorInputs(){
   println("### Current sensor inputs (" + sensorInputs.size()+"):");
     // Using an enhanced loop to iterate over each entry
      for (Map.Entry me : sensorInputs.entrySet()) {
        print(me.getKey() + " is ");
        println(me.getValue());
      }
}


/* incoming osc message are forwarded to the oscEvent method. */
void printOSCMessage(OscMessage theOscMessage) {
  int i = 0;
  /* print the address pattern and the typetag of the received OscMessage */
  print("### Printing an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  print(" typetag: "+theOscMessage.typetag());
  //println(" args: "+theOscMessage.arguments());
  while(i<theOscMessage.arguments().length) {
        print(" ["+(i)+"] ");
        print(theOscMessage.arguments()[i]);
        i++;
      }
   println(" ## Ending of message");
}


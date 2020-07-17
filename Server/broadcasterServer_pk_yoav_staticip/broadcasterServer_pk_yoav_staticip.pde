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


PrintWriter output;

int myColor = color(255);
int c1,c2;

float n,n1;

int framefile= 0;

int num = 50;

long interactionstarttime;
long interactioncurrenttime;
boolean interactionstarted = false;
int phase;
int n_cycles = 3;
int current_cycle = 0;
int duration_chapter = 0;
int interaction_part = 1;
long phasedur = 3000;


float[] arrayOfFloats = new float[num];

void setup() {
  oscP5 = new OscP5(this, myListeningPort);
  wekinator = new NetAddress("127.0.0.1",6448);

  // connectActuator("127.0.0.1");
  size(1600,800);
  smooth();

  noStroke();
  cp5 = new ControlP5(this);


  cp5.addButton("Interaction_1")
     .setValue(0)
     .setPosition(100,100)
     .setSize(600,90)
     ;


  cp5.addButton("Interaction_2")
     .setValue(100)
     .setPosition(100,200)
     .setSize(600,90)
     ;

  cp5.addButton("Interaction_3")
     .setValue(100)
     .setPosition(100,300)
     .setSize(600,90)
     ;

    cp5.addButton("Deflate_All")
     .setValue(100)
     .setPosition(100,400)
     .setSize(600,90)
     .setColorBackground(0xff008888);
     ;

   cp5.addButton("Stop_All")
     .setValue(100)
     .setPosition(100,500)
     .setSize(600,90)
     //.setColor(cc)
     .setColorBackground(0xff880000);
     ;



  myTextarea1 = cp5.addTextarea("sensorval")
                    .setPosition(100,650)
                    .setSize(600,150)
                    .setFont(createFont("arial",18))
                    .setLineHeight(14)
                    .setColor(color(128))
                    .setColorBackground(color(255,100))
                    .setColorForeground(color(255,100));
                    ;

  myTextarea2 = cp5.addTextarea("instructions")
                    .setPosition(800,100)
                    .setSize(600,600)
                    .setFont(createFont("arial",38))
                    .setLineHeight(14)
                    .setColor(color(128))
                    .setColorBackground(color(255,100))
                    .setColorForeground(color(255,100));
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
}

// function Start will receive changes from 
// controller with name Start
public void Write(int theValue) {
  //checks if there are sensors or actuators
  if(!sensorInputs.isEmpty() || !actuatorInputs.isEmpty()){

    String filename= "output"+System.currentTimeMillis()+".txt";

    output = createWriter(filename);

    output.print("frame"+"\t");

    //writes headers of files
    Set<String> keys = sensorInputs.keySet();
    for(String key: keys){
        output.print(key+"\t"); // Write the header to the file
        //text(key+"\t", 10, 10, 70, 80);  // Text wraps within text box
    }
    Set<String> keys2 = actuatorInputs.keySet();
    for(String key: keys2){
        output.print(key+"\t"); // Write the header to the file
        //text(key+"\t", 10, 10, 70, 80);  // Text wraps within text box
    }
    output.print("\n");

    println("Starting writing to file: "+filename);
    c1 = c2;
    c2 = color(0,160,100);
    fileStarted=true;
  }
  else println("There are no sensor inputs for now.");
}

// function End will receive changes from 
// controller with name End
public void EndFile(int theValue) {
  if(fileStarted){
    println("Ending file");
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
    c1 = c2;
    c2 = color(150,0,0);
    fileStarted=false;
    framefile=0;
  }
}

public void Interaction_1() {
    println("Number One");
    interact1 = true;
    interact2 = false;
    interact3 = false;
    deflatall = false;
    stopall = false;
}
public void Interaction_2() {
    println("Number Two");
    interact1 = false;
    interact2 = true;
    interact3 = false;
    deflatall = false;
    stopall = false;
}
public void Interaction_3() {
    println("Number Three");
    interact1 = false;
    interact2 = false;
    interact3 = true;
    deflatall = false;
    stopall = false;
}

public void Deflate_All() {
    println("Deflating all units");
    interact1 = false;
    interact2 = false;
    interact3 = false;
    deflatall = true;
    stopall = false;
}

public void Stop_All() {
    println("Stop");
    interact1 = false;
    interact2 = false;
    interact3 = false;
    deflatall = false;
    stopall = true;
}

void draw() {
  background(myColor);
  myColor = lerpColor(c1, c2, n);
  n += (1 - n) * 0.1;

  if (fileStarted) {
    output.print(++framefile + "\t");

    //writes headers of files
    Set<String> keys = sensorInputs.keySet();
    for (String key : keys) {
      output.print(sensorInputs.get(key)[0] + "\t"); // Write the header to the file
    }
    Set<String> keys2 = actuatorInputs.keySet();
    for (String key : keys2) {
      output.print(actuatorInputs.get(key)[0] + "\t"); // Write the header to the file
    }
    output.print("\n");
  }
  //background(0);
  //if(sensorInputs.size()>0)
  // printAllSensorInputs();


  if (millis() - overrideTime >= overrideWait) {
    overrideCoupling = false;
  }

  if (millis() - waitForPressureTime >= waitForPressureWait) {
    waitForPressure = false;
  }

  float pressure1 = 0;
  float pressure2 = 0;
  float pressure3 = 0;
  float pressure4 = 0;

  if (sensorInputs.get("1/pressure") != null) {
    pressure1 = (Float) sensorInputs.get("1/pressure")[0];
  }
  if (sensorInputs.get("2/pressure") != null) {
    pressure2 = (Float) sensorInputs.get("2/pressure")[0];
  }
  if (sensorInputs.get("3/pressure") != null) {
    pressure3 = (Float) sensorInputs.get("3/pressure")[0];
  }
  if (sensorInputs.get("4/pressure") != null) {
    pressure4 = (Float) sensorInputs.get("4/pressure")[0];
  }

  myTextarea1.setText("Pressure in the bit number one:    " + (pressure1) + " \n\n"
      + "Pressure in the bit number two:     " + (pressure2) + " \n\n"
      + "Pressure in the bit number three:   " + (pressure3) + "\n\n"
      + "Pressure in the bit number four:    " + (pressure4) + "\n\n"
      + "Button state:                       " + buttonStatus
  );

  endCapture();

  if (interact1) {
    //plotPressure();
    interaction_One();
  } else if (interact2) {
    //plotPressure();
    interaction_Two();
  } else if (interact3) {
    interaction_Three();
  } else if (deflatall) {
    deflating_Units();
  } else if (stopall) {
    stopping_Units();
  }
}

PrintWriter recordPressure = null;

SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSS");

void endCapture() {
  if (!interact1 && recordPressure != null) {
    recordPressure.flush();
    recordPressure.close();
    recordPressure = null;
  }
}

void startCapture() {
  if (interact1 && recordPressure == null) {
    Date startTime = new Date();
    recordPressure = createWriter(
        "pressure-" + dateFormatter.format(startTime) + ".log"
    );
    recordPressure.println("Time,Pressure1,Pressure2,Pressure3,Pressure4,Button");
  }
}

float readFloat(String from, float defaultValue) {
  if (sensorInputs.containsKey(from)) {
    Object[] inputs = sensorInputs.get(from);
    return inputs.length > 0 ? ((Float)inputs[0]).floatValue() : defaultValue;
  } else {
    return defaultValue;
  }
}

float[] readInputs() {
  float[] result = new float[4];
  result[0] = readFloat("1/pressure", 0.0);
  result[1] = readFloat("2/pressure", 0.0);
  result[2] = readFloat("3/pressure", 0.0);
  result[3] = readFloat("4/pressure", 0.0);
  return result;
}

float GOAL_PRESSURE = 1300;
float GOAL_TOLERANCE = 100;

void adjustPressure(float current, int device) {
  float diff = current - GOAL_PRESSURE;
  if (abs(diff) > GOAL_TOLERANCE) {
    OscMessage message = new OscMessage("/actuator/inflate");
    float adjustment = diff > 0.0 ? -log(diff): log(-(diff)) * 10;
    message.add(adjustment);
    sendToOneActuator(message, device);
  }
}

void interaction_One(){
  myTextarea2.setText("Interaction 1");
  startCapture();

  float[] readings = readInputs();

  recordPressure.println(
      dateFormatter.format(new Date()) + ","
          + String.valueOf(readings[0]) + ","
          + String.valueOf(readings[1]) + ","
          + String.valueOf(readings[2]) + ","
          + String.valueOf(readings[3]) + ","
          + String.valueOf(buttonStatus)
  );

  for (int index = 0; index < readings.length; index++) {
    adjustPressure(readings[index], index + 1);
  }
}


void interaction_Two(){
println("First interaction with thinking");
float pressure1 = 0;
float pressure2 = 0;
float pressure3 = 0;
float pressure4 = 0;

if(sensorInputs.get("1/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure1 = (Float) sensorInputs.get("1/pressure")[0];
       print("Pressure 1: ");
       println(pressure1);
  }
  if(sensorInputs.get("2/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure2 = (Float) sensorInputs.get("2/pressure")[0];
    print("Pressure 2: ");
    println(pressure2);

    }
  if(sensorInputs.get("3/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure3 = (Float) sensorInputs.get("3/pressure")[0];
       print("Pressure 3: ");
       println(pressure3);
  }
    if(sensorInputs.get("4/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure4 = (Float) sensorInputs.get("4/pressure")[0];
       print("Pressure 4: ");
       println(pressure4);
  }
//Interation 2. Bit 1 behavior
OscMessage myMessage1;
myMessage1 = new OscMessage("/actuator/inflate");
if ( pressure1 < 1100.0){
myMessage1.add(50.0);
println("Bit1 - Autoinflate");
}
else{
myMessage1.add(0.0);
println("Bit1 - Standby");
}
sendToOneActuator(myMessage1, 1);

//Interation 2. Bit 2 behavior
OscMessage myMessage2;
myMessage2 = new OscMessage("/actuator/inflate");
if ( abs (pressure2 - pressure1) < 10.0){
// print("Bit 2 - Standby");
}
else if ((pressure2 > pressure1)&&( abs (pressure2 - pressure1) < 50.0)){
myMessage2.add(-20.0);
// print("Bit 2 - Deflate");
}
else if ((pressure2 < pressure1)&&( abs (pressure2 - pressure1) < 50.0)){
myMessage2.add(20.0);
// print("Bit 2 - Inflate");
}
else if ((pressure2 > pressure1)&&( abs (pressure2 - pressure1) >= 50.0)){
myMessage2.add(-100.0);
// print("Bit 2 - Deflate");
}
else if ((pressure2 < pressure1)&&( abs (pressure2 - pressure1) >= 50.0)){
myMessage2.add(100.0);
// print("Bit 2 - Inflate");
}

sendToOneActuator(myMessage2, 2);

//Interation 2. Bit 3 behavior               
OscMessage myMessage3;
myMessage3 = new OscMessage("/actuator/inflate");
if ( abs (pressure3 - pressure1) < 10.0){
// print("Bit 3 - Standby");
}
else if ((pressure3 > pressure1)&&( abs(pressure3 - pressure1)<50.0)){
myMessage3.add(-30.0);
// print("Bit 3 - Deflate");
}
else if ((pressure3 < pressure1)&&( abs(pressure3 - pressure1)<50.0)){
myMessage3.add(30.0);
// print("Bit 3 - Inflate");
}
else if ((pressure3 > pressure1)&&( abs(pressure3 - pressure1)>=50.0)){
myMessage3.add(-100.0);
// print("Bit 3 - Deflate");
}
else if ((pressure3 < pressure1)&&( abs(pressure3 - pressure1)>=50.0)){
myMessage3.add(100.0);
// print("Bit 3 - Inflate");
}




sendToOneActuator(myMessage3, 3);


//Interation 2. Bit 4 behavior               
OscMessage myMessage4;
myMessage4 = new OscMessage("/actuator/inflate");
if ( abs (pressure4 - pressure1) < 10.0){
  // print("Bit 4 - Standby");
}
else if ((pressure4 > pressure1)&&( abs (pressure4 - pressure1) < 50.0)){
myMessage4.add(-20.0);
// print("Bit 4 - Deflate");
}
else if ((pressure4 < pressure1)&&( abs (pressure4 - pressure1) < 50.0)){
myMessage4.add(20.0);
// print("Bit 4 - Inflate");
}
else if ((pressure4 > pressure1)&&( abs (pressure4 - pressure1) >= 50.0)){
myMessage4.add(-100.0);
// print("Bit 4 - Deflate");
}
else if ((pressure4 < pressure1)&&( abs (pressure4 - pressure1) >= 50.0)){
myMessage4.add(100.0);
// print("Bit 4 - Inflate");
}
sendToOneActuator(myMessage4, 4);
}

void interaction_Three(){

<<<<<<< HEAD
if (interaction_part==0){

if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
interactionstarted = true;
println("vafel");
}
  
interactioncurrenttime = System.currentTimeMillis();  
  
if ((interactioncurrenttime - interactionstarttime)<10000){
  
  
}
  
}
  
  
  
  
if (interaction_part==1) { 
=======
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
interactionstarted = true;
}
<<<<<<< HEAD
  
  
/*
=======



>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
float pressure1 = 0;
float pressure2 = 0; 
float pressure3 = 0;  
float pressure4 = 0;  

    if(sensorInputs.get("1/pressure")!=null){
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure1 = (Float) sensorInputs.get("1/pressure")[0];
       //print("Pressure 1: ");
       //println(pressure1);
  }   
  if(sensorInputs.get("2/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure2 = (Float) sensorInputs.get("2/pressure")[0];
    //print("Pressure 2: ");
    //println(pressure2);
      
    }
    if(sensorInputs.get("3/pressure")!=null){
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure3 = (Float) sensorInputs.get("3/pressure")[0];
       //print("Pressure 3: ");
       //println(pressure3);
  }
    if(sensorInputs.get("4/pressure") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure4 = (Float) sensorInputs.get("4/pressure")[0];
       //print("Pressure 4: ");
  //  println(pressure4);
<<<<<<< HEAD
  }  
 
  */
  
  interactioncurrenttime = System.currentTimeMillis();
=======
  }



  long interactioncurrenttime = System.currentTimeMillis();
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a


  phase = (int)((interactioncurrenttime - interactionstarttime)/phasedur);

  OscMessage myMessage1;
  myMessage1 = new OscMessage("/actuator/inflate");



  switch (phase)
  {
<<<<<<< HEAD
    case 0: 
        //println("Inhale");  
        myMessage1.add(100.0); 
=======
    case 0:
        println("Inhale");
        myMessage1.add(100.0);
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("INHALE  "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
<<<<<<< HEAD
  case 1: 
        //println("Hold");  
        myMessage1.add(0.0); 
=======
  case 1:
        println("Hold");
        myMessage1.add(0.0);
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("HOLD "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
  case 2:
<<<<<<< HEAD
        //println("Exhale");  
        myMessage1.add(-100.0); 
=======
        println("Exhale");
        myMessage1.add(-100.0);
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("EXHALE  "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
   case 3:
<<<<<<< HEAD
        //println("Hold");  
        myMessage1.add(0.0); 
=======
        println("Hold");
        myMessage1.add(0.0);
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("HOLD "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
  }
<<<<<<< HEAD
  
  myTextarea2.setText("Start time:    "+(interactionstarttime) + " \n\n" +
  "Current time:    "+(interactioncurrenttime)+ " \n\n" +
  "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
  "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur));
  
  
  
  
  if (((interactioncurrenttime - interactionstarttime)/phasedur)>3){
  interactionstarttime = interactioncurrenttime;
  }
}
  
  
  
  
  
 if (interaction_part==2){
   
   
 }
=======

//  myTextarea2.setText("Start time:    "+(interactionstarttime) + " \n\n" +
//  "Current time:    "+(interactioncurrenttime)+ " \n\n" +
//  "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
//  "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur));




  if (((interactioncurrenttime - interactionstarttime)/phasedur)>3){
  interactionstarttime = interactioncurrenttime;
  }






  //Delete that when interaction is coming
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a

  
  
  
  
  
}

void deflating_Units(){
<<<<<<< HEAD
//println("Deflation in process!"); 
=======
println("Deflation in process!");
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(-100.0);
        sendToAllActuators(myMessage1);
}

void stopping_Units(){
<<<<<<< HEAD
//println("Full Stop in process!");  
=======
println("Full Stop in process!");
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a
        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(0.0);
        sendToAllActuators(myMessage1);
}



void plotPressure(){

  //if(waitForPressure) return;

   // copy everything one value down
  for (int i=0; i<arrayOfFloats.length-1; i++) {
    arrayOfFloats[i] = arrayOfFloats[i+1];
  }

  float newValue = 0;//noise(frameCount*0.01)*width;

  //println(newValue);

  if(sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure")) != null) {
      //float yoffset = map(mouseY, 0, height, 0, 1);
      newValue = (Float) sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure"))[0];
  }

  //println("Pressure:", newValue);

  newValue = (newValue - 1000) * 20;

  // set last value to the new value
  arrayOfFloats[arrayOfFloats.length-1] = newValue;

}










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
  else if (theOscMessage.addrPattern().equals(wekaPattern)) {
    //custom code to deal with it (replace function when needed)
    WekinatorMKRVibe(theOscMessage);
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
    addToActuatorInputs(theOscMessage.addrPattern(),theOscMessage.arguments()); //put it in the actuator input history

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

private void addToActuatorInputs(String osckey, Object[] values){
  if(actuatorInputs.put(osckey,values) == null && fileStarted){
    println("Received a new actuator: ENDING FILE PREMATURELY");
    EndFile(0);
  }
}

private void addToSensorInputs(String osckey, Object[] values){
  if(sensorInputs.put(osckey,values) == null && fileStarted){
    println("Received a new sensor: ENDING FILE PREMATURELY");
    EndFile(0);
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
    System.out.println("## ERROR: Actuator with ID "+ id+ " not found");
    return;
  }

  NetAddress actuatorNetAddress = ActuatorNetAddressList.get(addr,myBroadcastPort);
  if(actuatorNetAddress==null){
    System.out.println("## ERROR: Actuator with ID "+ id+ " not found");
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
<<<<<<< HEAD
  
    //System.out.println("## Sending to ALL actuators");
=======

    System.out.println("## Sending to ALL actuators");
>>>>>>> 2eeb4fc0a3749662de20231c2272f0a67134323a

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

/*
private int connectSensor(String theIPaddress) {
  int id = addIPAddress(theIPaddress);
     if (!SensorNetAddressList.contains(theIPaddress, myBroadcastPort)) {
       SensorNetAddressList.add(new NetAddress(theIPaddress, myBroadcastPort));
       println("### adding "+theIPaddress+" to the sensor list. The ID is "+id);
     } else {
       println("### Sensor "+theIPaddress+" is already connected. The ID is "+id);
     }
     println("### currently there are "+SensorNetAddressList.list().size()+" sensors connected.");
    
      //this is hardcoded just for couplings
      if(SensorNetAddressList.list().size() == 1){
        firstCouplingSensorId = id;
        //println(firstCouplingSensorId);
      }
     
       //this is hardcoded just for couplings
      if(SensorNetAddressList.list().size() == 2){
        secondCouplingSensorId = id;
        //println(firstCouplingSensorId);
      }
     
       //this is hardcoded just for couplings
      if(SensorNetAddressList.list().size() == 3){
        thirdCouplingSensorId = id;
        //println(firstCouplingSensorId);
      }
     
     
       if(SensorNetAddressList.list().size() == 4){
        fourthCouplingSensorId = id;
        //println(firstCouplingSensorId);
      }
    
     return id;
 }

private void disconnectSensor(String theIPaddress) {
if (SensorNetAddressList.contains(theIPaddress, myBroadcastPort)) {
    SensorNetAddressList.remove(theIPaddress, myBroadcastPort);
       println("### removing sensor "+theIPaddress+" from the list.");
     } else {
       println("### Sensor "+theIPaddress+" is not connected.");
     }
       println("### Sensors: currently there are "+SensorNetAddressList.list().size());
 }
 
 
private int connectActuator(String theIPaddress) {
     int id = addIPAddress(theIPaddress);
     if (!ActuatorNetAddressList.contains(theIPaddress, myBroadcastPort)) {
       ActuatorNetAddressList.add(new NetAddress(theIPaddress, myBroadcastPort));
       println("### adding "+theIPaddress+" to the actuator list. The ID is "+id);
     } else {
       println("### Actuator "+theIPaddress+" is already connected. The ID is "+id);
     }
     println("### currently there are "+ActuatorNetAddressList.list().size()+" actuators connected.");
     return id;
 }



private void disconnectActuator(String theIPaddress) {
if (ActuatorNetAddressList.contains(theIPaddress, myBroadcastPort)) {
    ActuatorNetAddressList.remove(theIPaddress, myBroadcastPort);
       println("### removing actuator "+theIPaddress+" from the list.");
     } else {
       println("### Actuator "+theIPaddress+" is not connected.");
     }
       println("### Actuators: currently there are "+ActuatorNetAddressList.list().size());
 }
*/

void trainWekinatorWithAllSensors() {
  //println("entering");
  OscMessage wekaMsg = new OscMessage("/wek/inputs");
  int i = 0;
  float[] args = new float[sensorInputs.size()];

  //println("entering trouble:"+sensorInputs.size());

  println("### Training WEKA with all sensors (" + sensorInputs.size()+"):");
     // Using an enhanced loop to iterate over each entry

     Iterator entries = sensorInputs.entrySet().iterator();
      while (entries.hasNext()) {
            Map.Entry entry = (Map.Entry) entries.next();
            String key = (String)entry.getKey();
            Object[] value = (Object[])entry.getValue();
            print("["+(i)+"] ");
            print(key + " is ");
            println(value);
            args[i]=(float)value[0];
            i++;
        }

     //for (Map.Entry me : sensorInputs.entrySet()) {

     //   String key = (String) me.getKey();
     //   Object[] value = (Object[])me.getValue();
     //   print("["+(i)+"] ");
     //   print(key + " is ");
     //   println(value);
     //   args[i]=(float)value[0];
     //   i++;
     // }


//println("Im REALLY out of trouble");
      //for (Map.Entry me : sensorInputs.entrySet()) {
      //  print("["+(i)+"] ");
      //  print(me.getKey() + " is ");
      //  println(me.getValue());

      //  wekaMsg.add((Object[])me.getValue());
      //  //args[i] = (me.getValue())[0];
      //  i++;
      //}

  wekaMsg.add(args);

  printOSCMessage(wekaMsg);

  oscP5.send(wekaMsg, wekinator);
}

void trainWekinatorMsg(OscMessage msg) {
  OscMessage wekaMsg = new OscMessage("/wek/inputs");
  wekaMsg.setArguments(msg.arguments());
  printOSCMessage(wekaMsg);

  oscP5.send(wekaMsg, wekinator);
}

void WekinatorMKRVibe(OscMessage theOscMessage){
  OscBundle myBundle = new OscBundle();

  //open wek/outputs
  OscMessage intensity1Message = new OscMessage("/actuator/vibeintensity1");
  intensity1Message.add(theOscMessage.get(0).floatValue());
  myBundle.add(intensity1Message);

  OscMessage intensity2Message = new OscMessage("/actuator/vibeintensity2");
  intensity2Message.add(theOscMessage.get(1).floatValue());
   myBundle.add(intensity2Message);

  OscMessage time1Message = new OscMessage("/actuator/vibetime1");
  time1Message.add(theOscMessage.get(2).floatValue());
  myBundle.add(time1Message);

  OscMessage time2Message = new OscMessage("/actuator/vibetime2");
  time2Message.add(theOscMessage.get(3).floatValue());
  myBundle.add(time2Message);

  myBundle.setTimetag(myBundle.now() + 10000);

  oscP5.send(myBundle, ActuatorNetAddressList);
}

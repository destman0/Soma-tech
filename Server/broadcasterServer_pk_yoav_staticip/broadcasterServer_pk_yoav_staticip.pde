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

long interactionstarttime;
long interactioncurrenttime;
long longinteractionstarttime;
boolean interactionstarted = false;
int phase;
int n_cycles;
int current_cycle = 0;
int duration_chapter = 0;
int interaction_part = 0;
long phasedur;
long slow_breathing_duration;



float[] arrayOfFloats = new float[num];

void setup() {
  oscP5 = new OscP5(this, myListeningPort);
  wekinator = new NetAddress("127.0.0.1",6448);

  // connectActuator("127.0.0.1");
  size(1600,800);
  smooth();

  noStroke();
  cp5 = new ControlP5(this);


  cp5.addButton("Breath_Mirroring")
     .setValue(0)
     .setPosition(100,100)
     .setSize(600,90)
     ;


  cp5.addButton("Slow_HRV_Breathing")
     .setValue(100)
     .setPosition(100,300)
     .setSize(600,90)
     ;

  cp5.addButton("Square_Breathing")
     .setValue(100)
     .setPosition(100,200)
     .setSize(600,90)
     ;

    cp5.addButton("Deflate_All_Pillows")
     .setValue(100)
     .setPosition(100,400)
     .setSize(600,90)
     .setColorBackground(0xff008888)
     ;

   cp5.addButton("Stop_All_Pillows")
     .setValue(100)
     .setPosition(100,500)
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
     .setValue(80)
     .setNumberOfTickMarks(11)
     .setVisible(false)
     ;  
     
     
   cp5.addSlider("Deflation_Rate")
     .setPosition(850,100)
     .setSize(50,420)
     .setRange(0,100)
     .setValue(80)
     .setNumberOfTickMarks(11)
     .setVisible(false)
     ;

  //cp5.getController("vslider").getCaptionLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

   println("After buttons");





  myTextarea1 = cp5.addTextarea("sensorval")
                    .setPosition(100,630)
                    .setSize(600,170)
                    .setFont(createFont("arial",18))
                    .setLineHeight(14)
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


  selection = SelectedInteraction.Nothing;

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

enum SelectedInteraction {
  NotReady,
  Nothing,
  FollowBreathing,
  SlowBreathing,
  SquareBreathing,
  DeflateAll,
  StopAll
};

SelectedInteraction selection = SelectedInteraction.NotReady;

public void onInteractionChanged(SelectedInteraction newSelect) {
  switch (newSelect) {
  case Nothing:
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    break;
  case FollowBreathing:
    initializeFollowBreathing();
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    break;
  case SlowBreathing:
    interaction_part = 0;
    interactionstarted = false;
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(true);
    
    cp5.getController("Inflation_Rate").setVisible(true);
    cp5.getController("Deflation_Rate").setVisible(true);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(true);
    break;
  case SquareBreathing:
    interaction_part = 0;
    interactionstarted = false;
    cp5.getController("Number_of_Cycles").setVisible(true);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    
    cp5.getController("Inflation_Rate").setVisible(true);
    cp5.getController("Deflation_Rate").setVisible(true);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    break;
  case DeflateAll:
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    break;
  case StopAll:
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    break;
  default:
    break;
  }
  selection = newSelect;
}

public void Breath_Mirroring() {
  if (selection != SelectedInteraction.NotReady && selection != SelectedInteraction.FollowBreathing) {
    onInteractionChanged(SelectedInteraction.FollowBreathing);
  }
}
public void Slow_HRV_Breathing() {
  if (selection != SelectedInteraction.NotReady && selection != SelectedInteraction.SlowBreathing) {
    onInteractionChanged(SelectedInteraction.SlowBreathing);
  }
}
public void Square_Breathing() {
  if (selection != SelectedInteraction.NotReady && selection != SelectedInteraction.SquareBreathing) {
    onInteractionChanged(SelectedInteraction.SquareBreathing);
  }
}

public void Deflate_All_Pillows() {
  if (selection != SelectedInteraction.NotReady && selection != SelectedInteraction.DeflateAll) {
    onInteractionChanged(SelectedInteraction.DeflateAll);
  }
}

public void Stop_All_Pillows() {
  if (selection != SelectedInteraction.NotReady && selection != SelectedInteraction.StopAll) {
    onInteractionChanged(SelectedInteraction.StopAll);
  }
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
  float pressure5 = 0;

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
    if (sensorInputs.get("5/pressure") != null) {
    pressure5 = (Float) sensorInputs.get("5/pressure")[0];
  }

  myTextarea1.setText("Pressure in the bit number one:    " + (pressure1) + " \n\n"
      + "Pressure in the bit number two:     " + (pressure2) + " \n\n"
      + "Pressure in the bit number three:   " + (pressure3) + "\n\n"
      + "Pressure in the bit number four:    " + (pressure4) + "\n\n"
      + "Pressure in the bit number five:    " + (pressure5) + "\n\n"
      + "Button state:                       " + buttonStatus
  );

  endCapture();

  switch (selection) {
  case FollowBreathing:
    interaction_One();
    break;
  case SlowBreathing:
    interaction_Two();
    break;
  case SquareBreathing:
    interaction_Three();
    break;
  case DeflateAll:
    deflating_Units();
    break;
  case StopAll:
    stopping_Units();
    break;
  default:
    break;
  }
}



void interaction_Two(){
// +++++++++++++++++++++++++++++++++++Slow HRV breathing++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
slow_breathing_duration = int(cp5.getController("Duration_of_Exercise").getValue());

if (interaction_part==0){

if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
interactionstarted = true;

}  
  
interactioncurrenttime = System.currentTimeMillis();  
  
if ((interactioncurrenttime - interactionstarttime)<10000){
  myTextarea2.setText("In this interaction we would like you to do your everyday latop activities, while wearing the artefact");  
  
}

else{
interaction_part = 1;
interactionstarted=false;
}
  

  
  
}  
  
if (interaction_part==1) {   
if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
longinteractionstarttime = System.currentTimeMillis();
interactionstarted = true;
}

if ((interactioncurrenttime - longinteractionstarttime)<(slow_breathing_duration*60000)) {
interactioncurrenttime = System.currentTimeMillis();
phasedur = int(cp5.getController("Inhale_or_Exhale_Duration").getValue()*1000);
phase = (int)((interactioncurrenttime - interactionstarttime)/phasedur);

OscMessage myMessage1;
myMessage1 = new OscMessage("/actuator/inflate");

  switch (phase)
  {

    case 0: 
        //println("Inhale");  
        if(in_phase){
        myMessage1.add(cp5.getController("Inflation_Rate").getValue()); 
        }
        else{
        myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
        }        
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("INHALE  "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
  case 1: 
        //println("Exhale"); 
        if (in_phase){
        myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
        }
        else{
        myMessage1.add(cp5.getController("Inflation_Rate").getValue()); 
        }
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("HOLD "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
    break;
}

myTextarea2.setText("Long interacton start time:    "+(longinteractionstarttime) + " \n\n" +
  "Phase start time:    "+(interactionstarttime)+ " \n\n" +
  "Current time:    "+(interactioncurrenttime)+ " \n\n" +
  "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
  "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur));

if (((interactioncurrenttime - interactionstarttime)/phasedur)>1){
  interactionstarttime = interactioncurrenttime;
  }




} 
else {
interaction_part = 2;
interactionstarted=false;  
}  
  
  
}


if (interaction_part==2){
myTextarea2.setText("And this is the end of the exercise!");  
    
}
}

void interaction_Three(){
//+++++++++++++++++++++++++++++++++Equal / Square Breathing++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
n_cycles = int(cp5.getController("Number_of_Cycles").getValue());
if (interaction_part==0){

if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
interactionstarted = true;

}
  
interactioncurrenttime = System.currentTimeMillis();  
  
if ((interactioncurrenttime - interactionstarttime)<10000){
  myTextarea2.setText("The next exercise we are going to do is very much based on a yoga breathing exercise. We are going to inhale, hold our breath, exhale and hold our breath. And we are going to do that on the increasing number counts.");  
  
}

else{
interaction_part = 1;
interactionstarted=false;
}
  
}
  
  
  
  
if (interaction_part==1) { 
if (duration_chapter<4){  
if (current_cycle<n_cycles){
if(interactionstarted==false){
interactionstarttime = System.currentTimeMillis();
interactionstarted = true;
}

  
  
interactioncurrenttime = System.currentTimeMillis();


   switch(duration_chapter)
   {
   case 0:
   phasedur = 3000;
   break;
   case 1:
   phasedur = 5000;
   break;
   case 2:
   phasedur = 7000;
   break;
   case 3:
   phasedur = 10000;
   break;  
   }




  phase = (int)((interactioncurrenttime - interactionstarttime)/phasedur);

  OscMessage myMessage1;
  myMessage1 = new OscMessage("/actuator/inflate");



  switch (phase)
  {

    case 0: 
        //println("Inhale"); 
        if(in_phase){
        myMessage1.add((cp5.getController("Inflation_Rate").getValue())); 
        }
        else{
        myMessage1.add(-(cp5.getController("Deflation_Rate").getValue()));  
        }  
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("INHALE    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
    break;
  case 1: 
        //println("Hold");  
        myMessage1.add(0.0); 
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("HOLD    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
    break;
  case 2:

        //println("Exhale");  
        if(in_phase){
        myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
        }
        else {
        myMessage1.add(cp5.getController("Inflation_Rate").getValue());
        }
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("EXHALE    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
    break;
   case 3:

        //println("Hold");  
        myMessage1.add(0.0); 
        sendToAllActuators(myMessage1);
        //myTextarea2.setText("HOLD    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
    break;
  }
 
 
 
 // That is debugging information, please unqote, if the interaction goes somewhere....
 
  myTextarea2.setText("Start time:    "+(interactionstarttime) + " \n\n" +
  "Current time:    "+(interactioncurrenttime)+ " \n\n" +
  "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
  "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur) +" \n\n" +
  "Cycle:    "+(current_cycle) + " \n\n" +
  "Duration Chapter:   " +(duration_chapter)+ " \n\n" +
  "Duration:    " + (phasedur));
  
  

  
  
  
  
  if (((interactioncurrenttime - interactionstarttime)/phasedur)>3){
  interactionstarttime = interactioncurrenttime;
  current_cycle++;
  }

  
  
}

else{
duration_chapter++;
current_cycle=0;
}


}

else{
interaction_part = 2;
interactionstarted=false;  
}



} 
  
 if (interaction_part==2){
 myTextarea2.setText("And this is the end of the exercise!");
   
 }


  
}

void deflating_Units(){

//println("Deflation in process!"); 

        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(-100.0);
        sendToAllActuators(myMessage1);
}

void stopping_Units(){

//println("Full Stop in process!");  


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

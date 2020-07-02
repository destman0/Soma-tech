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
 *
 */
 
 //pavels IP: 140
 
import oscP5.*;
import netP5.*;
import java.io.*; 
import java.util.*; 
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
boolean couplingAccSound = false;
boolean couplingAccInfl = false;
boolean couplingPressureInfl = false;
boolean horsePillow = false;
boolean pressureInterplay = false;
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
HashMap<String, Integer> DeviceIPs = new HashMap<String, Integer>();

NetAddress wekinator;


//data structure to hold all sensor data
HashMap<String,Object[]> sensorInputs = new HashMap<String,Object[]>();

HashMap<String,Object[]> actuatorInputs = new HashMap<String,Object[]>();



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
PrintWriter output;

int myColor = color(255);
int c1,c2;

float n,n1;

int framefile= 0;

int num = 50;
float[] arrayOfFloats = new float[num];

void setup() {
  oscP5 = new OscP5(this, myListeningPort);
  wekinator = new NetAddress("127.0.0.1",6448);
  
  connectActuator("127.0.0.1");
  size(800,800);
  smooth();
   
  noStroke();
  cp5 = new ControlP5(this);
  
  // create a new button with name 'buttonA'
  cp5.addButton("Write")
     .setValue(0)
     .setPosition(100,100)
     .setSize(200,99)
     ;
  
  // and add another 2 buttons
  cp5.addButton("EndFile")
     .setValue(100)
     .setPosition(100,200)
     .setSize(200,99)
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
    sineWaves[i].play();
    // Set the amplitudes for all oscillators
    sineWaves[i].amp(sineVolume);
  }

  myFilter = new SignalFilter(this);
  
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

void draw() {
  background(myColor);
  myColor = lerpColor(c1,c2,n);
  n += (1-n)* 0.1; 
  
  
  if(fileStarted){
    
     output.print(++framefile+"\t");
    
      //writes headers of files
      Set<String> keys = sensorInputs.keySet();
      for(String key: keys){
          output.print(sensorInputs.get(key)[0]+"\t"); // Write the header to the file
      }
      Set<String> keys2 = actuatorInputs.keySet();
      for(String key: keys2){
          output.print(actuatorInputs.get(key)[0]+"\t"); // Write the header to the file
      }
      output.print("\n");
  }
  //background(0);
  //if(sensorInputs.size()>0)
  // printAllSensorInputs();
  
  
  if(millis() - overrideTime >= overrideWait){
    overrideCoupling = false;
  }
  

  
  if(millis() - waitForPressureTime >= waitForPressureWait){
    waitForPressure = false;
  }
  
  //plotPressure();
  // display all values however you want
  for (int i=0; i<arrayOfFloats.length; i++) {
    noStroke();
    fill(255,0,0,255);
    ellipse(width*i/arrayOfFloats.length+width/num/2,height-arrayOfFloats[i],width/num,width/num);
  }
  
  
  if(couplingAccSound){
    CoupleACCSineWave();
  }
  else 
  
  //if(!overrideCoupling){
      if(couplingAccInfl){
        //plotPressure();
        CoupleACCInflate();
      }else if(couplingPressureInfl){
        plotPressure();
        CouplePressureInflate();
      }
      else if(horsePillow){
        runLikeTheWind();
      }
      else if(pressureInterplay){
        MaintainPressure();
      }
}


float last_pressure1 = 0;
float last_pressure2 = 0;

void runLikeTheWind(){
   // copy everything one value down
  for (int i=0; i<arrayOfFloats.length-1; i++) {
    arrayOfFloats[i] = arrayOfFloats[i+1];
  }
  
 float minCutoff = 0.02; // decrease this to get rid of slow speed jitter
  float beta      = 20.0;  // increase this to get rid of high speed lag
  
  // Pass the parameters to the filter
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  
  float pressure1 = 0;//noise(frameCount*0.01)*width;
  float pressure2 = 0;
  
  float difference = 0;
  
  //println(newValue);
  
  if(sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure")) != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure1 = (Float) sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure"))[0];
        
       // println("Pressure 1 OK");
      
      if(sensorInputs.get(String.join("/",Integer.toString(secondCouplingSensorId),"pressure")) != null) {
          //float yoffset = map(mouseY, 0, height, 0, 1);
          pressure2 = (Float) sensorInputs.get(String.join("/",Integer.toString(secondCouplingSensorId),"pressure"))[0];
         // println("Pressure 2 OK");
          difference = pressure1-pressure2; //if pressure1 is bigger, inflate actuator 2, and vice-versa
          
          
         difference= myFilter.filterUnitFloat( difference );
        
         
         if((abs(pressure1-last_pressure1) < 1) && (abs(pressure2-last_pressure2) < 1)){ //no real difference in pressure, probably no one is touching both 
           return;
         }
         else {
           last_pressure1 = pressure1;
           last_pressure2 = pressure2;
         }
         
         //difference = difference * (100/abs(difference));
 
         println(pressure1, pressure2, difference);
         
         difference = constrain(difference*1.5, -100, 100);
         
         println(pressure1, pressure2, difference);
          
          if(difference > 2){
              //pressure 1 is higher: deflate 1 at double speed, inflate 2, hope for the best
              
              OscMessage myMessage1;
              myMessage1 = new OscMessage("/actuator/inflate");
              myMessage1.add(constrain(-difference, -100, 100)); 
              sendToOneActuator(myMessage1, 1);
               
              OscMessage myMessage2;
              myMessage2 = new OscMessage("/actuator/inflate");
              myMessage2.add(difference); 
              sendToOneActuator(myMessage2, 2);
              
           }
           else if(difference < -2){
               //pressure 2 is higher: inflate 1, deflate 2 at double speed, hope for the best
              
              OscMessage myMessage1;
              myMessage1 = new OscMessage("/actuator/inflate");
              myMessage1.add(abs(difference)); 
              sendToOneActuator(myMessage1, 1);
               
              OscMessage myMessage2;
              myMessage2 = new OscMessage("/actuator/inflate");
              myMessage2.add(constrain(difference, -100, 100)); 
              sendToOneActuator(myMessage2, 2);
       
             }
      }
  }
  

  
  // set last value to the new value
  arrayOfFloats[arrayOfFloats.length-1] = pressure1/2;//(difference*10)+200;
 
  // display all values however you want
  for (int i=0; i<arrayOfFloats.length; i++) {
    noStroke();
    fill(255,0,0,255);
    ellipse(width*i/arrayOfFloats.length+width/num/2,height-arrayOfFloats[i],width/num,width/num);
  }
}


void MaintainPressure(){
  
//for (int i=0; i<arrayOfFloats.length-1; i++) {
//    arrayOfFloats[i] = arrayOfFloats[i+1];
//  }  
  
  
float pressure1 = 0;
float pressure2 = 0; 
float pressure3 = 0;  
float pressure4 = 0;  

  

  if(sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure")) != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure1 = (Float) sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure"))[0];
        
       print("Pressure 1: ");
       println(pressure1);
  }   
      if(sensorInputs.get(String.join("/",Integer.toString(secondCouplingSensorId),"pressure")) != null) {
          //float yoffset = map(mouseY, 0, height, 0, 1);
          pressure2 = (Float) sensorInputs.get(String.join("/",Integer.toString(secondCouplingSensorId),"pressure"))[0];
        print("Pressure 2: ");
        println(pressure2);
      
    }


  if(sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"pressure")) != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure3 = (Float) sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"pressure"))[0];
        
       print("Pressure 3: ");
       println(pressure3);
  }
  
    if(sensorInputs.get(String.join("/",Integer.toString(fourthCouplingSensorId),"pressure")) != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        pressure4 = (Float) sensorInputs.get(String.join("/",Integer.toString(fourthCouplingSensorId),"pressure"))[0];
        
       print("Pressure 4: ");
       println(pressure4);
  }

/*
if (calibrated == false)
{
OscMessage myMessage1;
myMessage1 = new OscMessage("/actuator/inflate");

if ( pressure1 < 1200.0){
print("Bit 1 - Inflate");
myMessage1.add(100.0);
sendToOneActuator(myMessage1, 1);
}

if (pressure1 >= 1200.0){
print("Bit 1 - Calibrated");
calibrated = true;
myMessage1.add(0.0);
sendToOneActuator(myMessage1, 1);
}
} 




if (calibrated == true)
{
*/

OscMessage myMessage2;
myMessage2 = new OscMessage("/actuator/inflate");
if ( abs (pressure2 - pressure1) < 50.0){
print("Bit 2 - Standby");
}
else if (pressure2 > pressure1){
myMessage2.add(-50.0);
print("Bit 2 - Deflate");
}
else if (pressure2 < pressure1){
myMessage2.add(50.0);
print("Bit 2 - Inflate");
}  

sendToOneActuator(myMessage2, 2);
               
OscMessage myMessage3;
myMessage3 = new OscMessage("/actuator/inflate");
if ( abs (pressure3 - pressure1) < 50.0){
print("Bit 3 - Standby");
}
else if (pressure3 > pressure1){
myMessage3.add(-50.0);
print("Bit 3 - Deflate");
}
else if (pressure3 < pressure1){
myMessage3.add(50.0);
print("Bit 3 - Inflate");
}  

sendToOneActuator(myMessage3, 3);



               
OscMessage myMessage4;
myMessage4 = new OscMessage("/actuator/inflate");
if ( abs (pressure4 - pressure1) < 50.0){
  print("Bit 4 - Standby");
}
else if (pressure4 > pressure1){
myMessage4.add(-50.0);
print("Bit 4 - Deflate");
}
else if (pressure4 < pressure1){
myMessage4.add(50.0);
print("Bit 4 - Inflate");
}  

sendToOneActuator(myMessage4, 4);


}


//}





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

void CouplePressureInflate(){
  float yoffset = 0;
  float frequency = 0;
  
  float minCutoff = 0.02; // decrease this to get rid of slow speed jitter
  float beta      = 8.0;  // increase this to get rid of high speed lag
  
  // Pass the parameters to the filter
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  
  //check time for actuation only, if it hasn't stopped, then return ignore everything from here on
  //if it has stopped, then need to send a stop message to all actuators, and start a new timer to wait for them to stop
  
    if(onlyActuate){
      if(millis() - onlyActuateTime >= onlyActuateWait){
        
        onlyActuate = false;
        
        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(0.0); 
        //sendToOneActuator(myMessage1, 1);
         sendToAllActuators(myMessage1);
         
        // println("Wait!");
         
         //START A NEW TIMER to wait for the pressure to stabilize
         waitForPressureTime= millis();
         waitForPressure = true;
         return;
      }
      else return;
    }
  
  
  
  //check for timer to wait for pressure, if it hasn't stopped, then return and ignore everything from here on
  if(waitForPressure){
    //println("Waiting for pressure!");
    return;
  }
  
  
  if(sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure")) != null) {
      //float yoffset = map(mouseY, 0, height, 0, 1);
      yoffset = (Float) sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"pressure"))[0];
  }
  
  println("Pressure:", yoffset); 
   plotPressure();
  
    // if(yoffset == 0){
    //  return;
    //}
      
    frequency = (yoffset - 1000) * 20;

    //Use mouseX mapped from -0.5 to 0.5 as a detune argument //OLD CODE
    //float detune = map(mouseX, 0, width, -0.5, 0.5);
    
    float detune = 1;
    
    //if(sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"y")) != null) {
    //    //float yoffset = map(mouseY, 0, height, 0, 1);
    //    detune = (Float) sensorInputs.get(String.join("/",Integer.toString(firstCouplingSensorId),"y"))[0];
    //}
        
    if(detune != last_detune || last_yoffset != yoffset){ //it happens that they are the same often since this function is called more times than the sensor data updates
      
      
      yoffset = myFilter.filterUnitFloat( yoffset );
      
      for (int i = 0; i < numSines; i++) {
        sineFreq[i] = frequency * (i + 1 * detune);
        // Set the frequencies for all oscillators
        sineWaves[i].freq(sineFreq[i]);
      }
      
      
       if(yoffset-last_yoffset > 0){
        //deflate
        println("Deflate!", yoffset-last_yoffset);
        //OscMessage myMessage1;
        //  myMessage1 = new OscMessage("/actuator/inflate");
        //  myMessage1.add(-50.0); 
        //  //sendToOneActuator(myMessage, 1);
        //   sendToAllActuators(myMessage1);
           
        //   //start a timer for actuation
        //   onlyActuateTime= millis();
        //   onlyActuate = true;

          
       }
       else if(yoffset-last_yoffset < 0){
         ////inflate
         
         println("Inflate!", yoffset-last_yoffset);
           
         //  OscMessage myMessage2;
         //myMessage2 = new OscMessage("/actuator/inflate");
         //myMessage2.add(50.0); 
         ////sendToOneActuator(myMessage2, 1);
         //  sendToAllActuators(myMessage2);
           
         //  //start a timer for actuation
         //  onlyActuateTime= millis();
         //  onlyActuate = true;
       
       }
      
      //println("Pressure:", yoffset);
      //println("Frequency:", frequency);
      //println("Detune:", detune);
      //println("Diff_detune:", detune-last_detune);
      //println("Diff_yoffset:", yoffset-last_yoffset);
      
      last_yoffset = yoffset;
      last_detune = detune;
    }
}

float last_yoffset = 0;
float last_detune = 0;


// actuator/[id]/inflate 1 OR actuator/[id]/deflate 1
void CoupleACCInflate(){
  float yoffset = 1;
  float frequency = 1;
  
    // Pass the parameters to the filter
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  
  //if(firstCouplingSensorId !=0){
  //  println(firstCouplingSensorId);
  //  println(String.join("/",Integer.toString(firstCouplingSensorId),"x"));
  //}
  
  if(sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"x")) != null) {
      //float yoffset = map(mouseY, 0, height, 0, 1);
      yoffset = (Float) sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"x"))[0];
  }
  
  
  
  
    
    // if(yoffset == 0){
    //  return;
    //}
      
    frequency = yoffset*100 + 150;

    //Use mouseX mapped from -0.5 to 0.5 as a detune argument //OLD CODE
    //float detune = map(mouseX, 0, width, -0.5, 0.5);
    
    float detune = 0;
    
    if(sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"y")) != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        detune = (Float) sensorInputs.get(String.join("/",Integer.toString(thirdCouplingSensorId),"y"))[0];
    }
        
    if(detune != last_detune || last_yoffset != yoffset){ //it happens that they are the same often since this function is called more times than the sensor data updates

      yoffset = myFilter.filterUnitFloat( yoffset );
      
      
      for (int i = 0; i < numSines; i++) {
        sineFreq[i] = frequency * (i + 1 * detune);
        // Set the frequencies for all oscillators
        sineWaves[i].freq(sineFreq[i]);
      }
      
      println("Frequency:", frequency);
      println("Detune:", detune);
      println("Diff_detune:", detune-last_detune);
      println("Diff_yoffset:", yoffset-last_yoffset);
      
      
      
      if(yoffset-last_yoffset < 0){
        //deflate
        OscMessage myMessage1;
          myMessage1 = new OscMessage("/actuator/inflate");
          myMessage1.add(50.0); 
          //sendToOneActuator(myMessage, 1);
           sendToAllActuators(myMessage1);
           
          //OscMessage myMessage2;
          //myMessage2 = new OscMessage("/actuator/deflate");
          //myMessage2.add(1.0); 
          ////sendToOneActuator(myMessage, 1);
          // sendToAllActuators(myMessage2);
          
       }
       else{
         ////inflate
         //OscMessage myMessage1;
         //myMessage1 = new OscMessage("/actuator/deflate");
         //myMessage1.add(0.0); 
         ////sendToOneActuator(myMessage2, 1);
         //  sendToAllActuators(myMessage1);
           
           OscMessage myMessage2;
         myMessage2 = new OscMessage("/actuator/inflate");
         myMessage2.add(-50.0); 
         //sendToOneActuator(myMessage2, 1);
           sendToAllActuators(myMessage2);
       
       }
       
       
       
      
      last_yoffset = yoffset;
      last_detune = detune;
    }
}

void CoupleACCSineWave(){
  float yoffset = 0;
  
    if(sensorInputs.get("1/x") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        yoffset = (Float) sensorInputs.get("1/x")[0];
    }
      
    
    //Map mouseY logarithmically to 150 - 1150 to create a base frequency range
    float frequency = yoffset*100 + 150;
    
    println("Frequency:", frequency);
    //Use mouseX mapped from -0.5 to 0.5 as a detune argument
    
    //float detune = map(mouseX, 0, width, -0.5, 0.5);
    float detune = 0;
    
    if(sensorInputs.get("1/y") != null) {
        //float yoffset = map(mouseY, 0, height, 0, 1);
        detune = (Float) sensorInputs.get("1/y")[0];
    }
    
     println("Detune:", detune);
    
    for (int i = 0; i < numSines; i++) { 
      sineFreq[i] = frequency * (i + 1 * detune);
      // Set the frequencies for all oscillators
      sineWaves[i].freq(sineFreq[i]);
    }
}


void oscEvent(OscMessage theOscMessage) {
  //println("### OSC MESSAGE ARRIVED");
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(SensorConnectPattern)) {
    connectSensor(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(SensorDisconnectPattern)) {
    disconnectSensor(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(ActuatorConnectPattern)) {
    connectActuator(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(ActuatorDisconnectPattern)) {
    disconnectActuator(theOscMessage.netAddress().address());
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
  if(id == -1)
    id = connectSensor(theOscMessage.netAddress().address());
    
 
  
  //remove the "/sensor" part
  String[] addrComponents = theOscMessage.addrPattern().split("/");
  
  //System.out.println("## PRINTING addrComponents"); 
  //for (String a : addrComponents) 
  //          System.out.println(a); 
   
  String[] address = new String[addrComponents.length-1];
  
  address[0] = Integer.toString(id);
  
  for(int i=2;i<addrComponents.length; i++){ //i starts at 2 to jump past the initial blankspace "" and the word "sensor"
    address[i-1] = addrComponents[i];
  }

  addToSensorInputs(join(address,"/"), theOscMessage.arguments());
}

int getDeviceId(NetAddress address){
 Integer id = DeviceIPs.get(address.address());
 if(id==null) return -1;
 else return id;
}

String getDeviceAddress(int id){

   for (HashMap.Entry<String, Integer> entry : DeviceIPs.entrySet()) {
            if (entry.getValue().equals(id)) {
                return(entry.getKey());
            }
        }
    return null;
}


void sendToOneActuator(OscMessage theOscMessage, int id){
  
  System.out.println("## Sending to one actuator with ID "+ id);
  
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
  /* send the osc bundle, containing 1 osc messages, to all actuators. */
  oscP5.send(myBundle, actuatorNetAddress);
}

void sendToAllActuators(OscMessage theOscMessage){
  
    System.out.println("## Sending to ALL actuators");

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

private int addIPAddress(String IPAddress){
  //HashMap<String, Integer>
  Integer id = DeviceIPs.putIfAbsent(IPAddress, new Integer(indexIP));
  
  if(id==null){ //it is new!
    id= DeviceIPs.get(IPAddress);
    indexIP++;
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

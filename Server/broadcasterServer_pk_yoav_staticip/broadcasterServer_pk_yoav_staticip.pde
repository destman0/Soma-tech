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
boolean recording = false;

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
  DeviceIPs.put("192.168.0.16", new Device(6, DeviceRole.Both));
  DeviceIPs.put("192.168.0.17", new Device(7, DeviceRole.Both));
  DeviceIPs.put("192.168.0.18", new Device(8, DeviceRole.Both));
  DeviceIPs.put("192.168.0.19", new Device(9, DeviceRole.Both));
  DeviceIPs.put("192.168.0.20", new Device(10, DeviceRole.Both));
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
float forceSensor = 0.0;

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
Textlabel myTextlabelA, myTextlabelB, myTextlabelC, myTextlabelD, myTextlabelE;
Knob myKnobA, myKnobB, myKnobC, myKnobD, myKnobE;
ListBox l;


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
Interaction explosive1;
Interaction explosive2;
Interaction recordAll;
Interaction sectionBreathing;
Interaction playIntro;
Interaction playOutro;
Interaction playScan;
Interaction setPressureInteraction;
// Interaction playfulBreathing;

static int BUTTONS_START = 100;
static int BUTTONS_END = 710;
static int BUTTONS_GUTTER = 10;
static int BUTTON_1_START = BUTTONS_START;
static int BUTTON_OF_2_WIDTH = (BUTTONS_END - BUTTONS_START - BUTTONS_GUTTER) / 2;
static int BUTTON_2_OF_2_START = BUTTONS_START + BUTTONS_GUTTER + BUTTON_OF_2_WIDTH;
static int BUTTON_OF_3_WIDTH = (BUTTONS_END - BUTTONS_START - (2 * BUTTONS_GUTTER)) / 3;
static int BUTTON_2_OF_3_START = BUTTONS_START + BUTTONS_GUTTER + BUTTON_OF_3_WIDTH;
static int BUTTON_3_OF_3_START = BUTTONS_START + (2 * (BUTTONS_GUTTER + BUTTON_OF_3_WIDTH));
static int BUTTON_OF_4_WIDTH = (BUTTONS_END - BUTTONS_START - (3 * BUTTONS_GUTTER)) / 4;
static int BUTTON_2_OF_4_START = BUTTONS_START + BUTTONS_GUTTER + BUTTON_OF_4_WIDTH;
static int BUTTON_3_OF_4_START = BUTTONS_START + (2 * (BUTTONS_GUTTER + BUTTON_OF_4_WIDTH));
static int BUTTON_4_OF_4_START = BUTTONS_START + (3 * (BUTTONS_GUTTER + BUTTON_OF_4_WIDTH));

void setup() {
  oscP5 = new OscP5(this, myListeningPort);
  wekinator = new NetAddress("127.0.0.1",6448);

  // connectActuator("127.0.0.1");
  size(1600,800);
  smooth();

  noStroke();
  cp5 = new ControlP5(this);

  // cp5.addButton("Explosive_Pa_500")
  //   .setValue(0)
  //   .setPosition(100, 0)
  //   .setSize(300,45)
  //   ;

  // cp5.addButton("Explosive_Pa_200")
  //   .setValue(0)
  //   .setPosition(300, 0)
  //   .setSize(300,45)
  //   ;

  // cp5.addButton("Playful_Test")
  //   .setValue(0)
  //   .setPosition(100, 10)
  //   .setSize(300,90)
  //   ;


  cp5.addButton("Introduction")
    .setValue(0)
    .setPosition(BUTTON_1_START, 50)
    .setSize(BUTTON_OF_3_WIDTH, 90)
    ;

  cp5.addButton("Breath_Scan")
    .setValue(0)
    .setPosition(BUTTON_2_OF_3_START, 50)
    .setSize(BUTTON_OF_3_WIDTH, 90)
    ;

  cp5.addButton("Outro")
    .setValue(0)
    .setPosition(BUTTON_3_OF_3_START, 50)
    .setSize(BUTTON_OF_3_WIDTH, 90)
    ;

  cp5.addButton("Fricative_Exhale")
     .setValue(0)
     .setPosition(100, 200)
     .setSize(300,90)
     ;

  cp5.addButton("Square_Breathing")
    .setValue(100)
    .setPosition(100, 350)
    .setSize(300,90)
    ;

  cp5.addButton("Appoggio")
    .setValue(0)
    .setPosition(410,350)
    .setSize(300,90)
    ;

  cp5.addButton("Slow_HRV_Breathing")
     .setValue(100)
     .setPosition(410, 200)
     .setSize(300,90)
     ;

  cp5.addButton("Step_Breathing")
      .setValue(100)
      .setPosition(100, 500)
      .setSize(300,90)
      ;

  cp5.addButton("Deflate_All_Pillows")
     .setValue(100)
     .setPosition(BUTTON_1_START, 600)
     .setSize(BUTTON_OF_4_WIDTH, 90)
     .setColorBackground(0xff008888)
     ;

    cp5.addButton("Inflate_To")
      .setValue(1)
      .setPosition(BUTTON_2_OF_4_START, 600)
      .setSize(BUTTON_OF_4_WIDTH, 90)
      .setColorBackground(0xff008888);


   cp5.addButton("Stop_All_Pillows")
     .setValue(100)
     .setPosition(BUTTON_3_OF_4_START, 600)
     .setSize(BUTTON_OF_4_WIDTH, 90)
     .setColorBackground(0xff880000)
     ;

   cp5.addButton("Record_Only")
     .setValue(1)
     .setPosition(BUTTON_4_OF_4_START, 600)
     .setSize(BUTTON_OF_4_WIDTH, 90)
     .setColorBackground(0xff008888);

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
     
     
   cp5.addSlider("Target_Pressure")
     .setPosition(20, 170)
     .setSize(50, 420)
     .setRange(900, 1300)
     .setValue(1040)
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
                    .setPosition(100, 700)
                    .setSize(610, 80)
                    .setFont(createFont("arial",12))
                    .setLineHeight(11)
                    .setColor(color(128))
                    .setColorBackground(color(255,100))
                    .setColorForeground(color(255,100));
                    ;

  myTextarea2 = cp5.addTextarea("instructions")
                    .setPosition(950,100)
                    .setSize(600,400)
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


  myKnobB = cp5.addKnob("1st_number_of_counts")
               .setRange(3,10)
               .setValue(3)
               .setPosition(750,600)
               .setRadius(70)
               .setNumberOfTickMarks(7)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setDragDirection(Knob.HORIZONTAL)
               .setVisible(false)
               ;      

  myKnobC = cp5.addKnob("2nd_number_of_counts")
               .setRange(3,10)
               .setValue(4)
               .setPosition(900,600)
               .setRadius(70)
               .setNumberOfTickMarks(7)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setDragDirection(Knob.HORIZONTAL)
               .setVisible(false)
               ;  
               
  myKnobD = cp5.addKnob("3rd_number_of_counts")
               .setRange(3,10)
               .setValue(5)
               .setPosition(1050,600)
               .setRadius(70)
               .setNumberOfTickMarks(7)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setDragDirection(Knob.HORIZONTAL)
               .setVisible(false)
               ;  

  myKnobE = cp5.addKnob("4th_number_of_counts")
               .setRange(3,10)
               .setValue(6)
               .setPosition(1200,600)
               .setRadius(70)
               .setNumberOfTickMarks(7)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setDragDirection(Knob.HORIZONTAL)
               .setVisible(false)
               ;  

  myTextlabelA = cp5.addTextlabel("label1")
                    .setText("Breath Scan")
                    .setPosition(300,10)
                    .setFont(createFont("Arial", 20))
                    ;
                    
  myTextlabelB = cp5.addTextlabel("label2")
                    .setText("Soothing Exercises")
                    .setPosition(300,150)
                    .setFont(createFont("Arial", 20))
                    ;

  myTextlabelC = cp5.addTextlabel("label3")
                    .setText("Uplifting Exercises")
                    .setPosition(300,300)
                    .setFont(createFont("Arial", 20))
                    ;

  myTextlabelD = cp5.addTextlabel("label4")
                    .setText("Explorative Exercises")
                    .setPosition(300,450)
                    .setFont(createFont("Arial", 20))
                    ;

  myTextlabelE = cp5.addTextlabel("label5")
                    .setText("Manual Override")
                    .setPosition(300,570)
                    .setFont(createFont("Arial", 20))
                    ;

  cp5.addToggle("in_phase")
     .setPosition(20,100)
     .setSize(50,30)
     .setValue(true)
     ;

  cp5.addToggle("recording")
    .setPosition(20, 50)
    .setSize(50,30)
    .setColorForeground(color(240, 10, 10))
    .setValue(false)
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

  TreeMap<Long, Output> breathing1timings = new TreeMap();
  //                   Time in file millis,     output values
  breathing1timings.put(5000l,                  new Output());
  breathing1timings.put(19142l,                 new Output().set1(30));
  breathing1timings.put(27870l,                 new Output().set1(-30));
  breathing1timings.put(35000l,                 new Output());
  // "You will feel a slight shift"
  breathing1timings.put(36000l,                 new Output().set1(50));
  breathing1timings.put(36500l,                 new Output().set1(0));
  breathing1timings.put(37000l,                 new Output().set1(50));
  breathing1timings.put(37500l,                 new Output().set1(0));
  breathing1timings.put(38000l,                 new Output().set1(40));
  breathing1timings.put(38500l,                 new Output().set1(-40));
  breathing1timings.put(39500l,                 new Output().set1(0));
  // "You will feel a slight shift" Ends
  breathing1timings.put(43280l,                 new Output().set1(40));
  breathing1timings.put(46370l,                 new Output().set1(-40));
  breathing1timings.put(53450l,                 new Output());
  breathing1timings.put(68400l,                 new Output().set1(30));
  breathing1timings.put(83600l,                 new Output().set1(-30));
  breathing1timings.put(87200l,                 new Output());
  // Pause
  breathing1timings.put(91000l,                 new Output());

  breathMirroring1 = new BreathMirroring("frictiveBreathing",
                                         new SoundFile(this, "audio/breathing-exercise-1-instructions.wav"),
                                         new SoundFile(this, "audio/breathing-exercise-1-exercise.wav"),
                                         new SoundFile(this, "audio/and-now-your-breathing.wav"),
                                         new SoundFile(this, "audio/and-breath-in-normally-pavel.wav"),
                                         breathing1timings);

  TreeMap<Long, Output> breathing2timings = new TreeMap();
  //                   Time in file millis,     output values
  breathing2timings.put(5000l,                  new Output());
  breathing2timings.put(15442l,                 new Output().set1(30)); // "Please make sure that one..."
  breathing2timings.put(20270l,                 new Output().set1(-30));
  breathing2timings.put(25000l,                 new Output());
  // "You will feel a slight shift"
  shiftTimingEffect(29200l, breathing2timings);
  // "Where you will feel the expansion"
  breathing2timings.put(37660l,                 new Output().set1(30)); // "Please make sure that one..."
  breathing2timings.put(37660l + 1000l,         new Output().set1(-30));
  breathing2timings.put(37660l + 2000l,         new Output().set1(0));
  // "You will feel a slight shift" Ends
  breathing2timings.put(43800l,                 new Output().set1(30));
  breathing2timings.put(45900l,                 new Output().set1(-30));
  breathing2timings.put(47100l,                 new Output());
  breathing2timings.put(51000l,                 new Output().set2(30));
  breathing2timings.put(56600l,                 new Output().set2(-30));
  breathing2timings.put(59000l,                 new Output());
  // Pa
  // "Let's try it now"
  breathing2timings.put(72350l,                 new Output().set2(80)); // Pa
  breathing2timings.put(72450l,                 new Output().set2(0));
  breathing2timings.put(72500l,                 new Output().set2(80));
  breathing2timings.put(72750l,                 new Output().set2(-80));
  breathing2timings.put(73300l,                 new Output().set2(0));

  paTimingEffect(82000l, breathing2timings);
  paTimingEffect(84200l, breathing2timings);
  paTimingEffect(86200l, breathing2timings);
  breathing2timings.put(88200l,                 new Output());
  breathing2timings.put(93200l,                 new Output().set1(20).set2(20)); // "... focus on breathing into both hands"
  breathing2timings.put(94500l,                 new Output().set1(-20).set2(-20)); // "... focus on breathing into both hands"
  breathing2timings.put(95500l,                 new Output().set1(0).set2(30)); // " one on your rib cage"
  breathing2timings.put(95500l,                 new Output().set1(0).set2(30)); // " one on your rib cage"
  breathing2timings.put(96500l,                 new Output().set1(0).set2(-30)); // " one on your rib cage"
  breathing2timings.put(97800l,                 new Output().set1(30).set2(0)); // " one where our lower ..."
  breathing2timings.put(98800l,                 new Output().set1(-30).set2(0));
  breathing2timings.put(99800l,                 new Output());

  paTimingEffect(130390l - 1280l, breathing2timings);  // Sshhh
  paTimingEffect(132410l - 1280l, breathing2timings);
  paTimingEffect(134300l - 1280l, breathing2timings);
  paTimingEffect(136050l - 1280l, breathing2timings);

  breathing2timings.put(148200l,                new Output());

  breathMirroring2 = new BreathMirroring("appoggio",
                                         new SoundFile(this, "audio/mirror-breathing-2-instructions.wav"),
                                         new SoundFile(this, "audio/mirror-breathing-2-exercise-v2.wav"),
                                         new SoundFile(this, "audio/and-now-your-breathing.wav"),
                                         new SoundFile(this, "audio/and-breath-in-normally-pavel.wav"),
                                         breathing2timings);

  hrvBreathing = new HrvBreathing(new SoundFile(this, "audio/hrv-instructions.wav"));

  ArrayList<SoundFile> countAudioFiles = new ArrayList();
  countAudioFiles.add(new SoundFile(this, "audio/one.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/two.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/three.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/four.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/five.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/six.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/seven.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/eight.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/nine.wav"));
  countAudioFiles.add(new SoundFile(this, "audio/ten.wav"));
  ArrayList<SoundFile> secondsAudioFiles = new ArrayList();
  secondsAudioFiles.add(null);
  secondsAudioFiles.add(null);
  secondsAudioFiles.add(null);
  secondsAudioFiles.add(new SoundFile(this, "audio/four-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/five-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/six-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/seven-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/eight-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/nine-seconds.wav"));
  secondsAudioFiles.add(new SoundFile(this, "audio/ten-seconds.wav"));
  squareBreathing = new SquareBreathing(new SoundFile(this, "audio/square-instructions.wav"),
                                        countAudioFiles,
                                        secondsAudioFiles,
                                        new SoundFile(this, "audio/exhale.wav"),
                                        new SoundFile(this, "audio/inhale.wav"),
                                        new SoundFile(this, "audio/hold.wav"),
                                        new SoundFile(this, "audio/and-breath-in-normally.wav")
                                        );

  deflateAll = new DeflateAll();

  stopAll = new StopAll();

  recordAll = new RecordAll();

  sectionBreathing = new SectionBreathingInteraction();

  playIntro = new PlayAudio(new SoundFile(this, "audio/welcome.wav"), "Welcome");

  playScan = new PlayAudio(new SoundFile(this, "audio/scan.wav"), "Breathing Scan");

  playOutro = new PlayAudio(new SoundFile(this, "audio/outro.wav"), "Outro");

  setPressureInteraction = new SetPressure();

//   explosive1 = new ExplosivePaInteraction(500);
//   explosive2 = new ExplosivePaInteraction(200);
  // playfulBreathing = new PlayfulBreathing();
}

Measurement currentMeasurement;


Interaction currentInteraction = null;

void shiftTimingEffect(long start, TreeMap<Long, Output> timings) {
  timings.put(start,                 new Output().set1(50));
  timings.put(start + 500l,          new Output().set1(30));
  timings.put(start + 1000l,         new Output().set1(50));
  timings.put(start + 1500l,         new Output().set1(30));
  timings.put(start + 1900l,         new Output().set1(40));
  timings.put(start + 2400l,         new Output().set1(-60));
  timings.put(start + 3500l,         new Output().set1(0));
}

void paTimingEffect(long start, TreeMap<Long, Output> timings) {
  timings.put(start,                 new Output(30).set2(0)); // Inhale
  timings.put(start + 1280l,         new Output(0).set2(80)); // PA!
  timings.put(start + 1600l,         new Output(-50).set2(-80)); // release
  timings.put(start + 2100l,         new Output(0)); // release
}

void selectInteraction(Interaction newInteraction) {
  if (newInteraction != null && newInteraction != currentInteraction) {
    if (currentInteraction != null) {
      currentInteraction.teardown(cp5);
    }
    currentInteraction = newInteraction;
    currentInteraction.prepare(currentMeasurement, cp5);
  }
}

public void Fricative_Exhale() {
  selectInteraction(breathMirroring1);
}

public void Appoggio() {
  selectInteraction(breathMirroring2);
}

public void Slow_HRV_Breathing() {
  selectInteraction(hrvBreathing);
}

public void Square_Breathing() {
  selectInteraction(squareBreathing);
}

public void Step_Breathing() {
    selectInteraction(sectionBreathing);
}

public void Deflate_All_Pillows() {
  selectInteraction(deflateAll);
}

public void Stop_All_Pillows() {
  selectInteraction(stopAll);
}

public void Explosive_Pa_500() {
  selectInteraction(explosive1);
}

public void Explosive_Pa_200() {
  selectInteraction(explosive2);
}

public void Record_Only() {
  selectInteraction(recordAll);
}

public void Inflate_To() {
  selectInteraction(setPressureInteraction);
}

public void Introduction() {
  selectInteraction(playIntro);
}

public void Breath_Scan() {
  selectInteraction(playScan);
}

public void Outro() {
  selectInteraction(playOutro);
}

// public void Playful_Test() {
//   selectInteraction(playfulBreathing);
// }

Measurement readInputs() {
  return new Measurement(System.currentTimeMillis(),
                         readFloat("1/pressure", 0.0),
                         readFloat("2/pressure", 0.0),
                         readFloat("3/pressure", 0.0),
                         readFloat("4/pressure", 0.0),
                         readFloat("5/pressure", 0.0),
                         readFloat("6/pressure", 0.0),
                         readFloat("7/pressure", 0.0),
                         readFloat("8/pressure", 0.0),
                         readFloat("9/pressure", 0.0),
                         readFloat("10/pressure", 0.0),
                         buttonStatus,
                         forceSensor
                         );
}

void sendOutputValues(Output out) {
  sendTo(1, out.pressure1);
  sendTo(2, out.pressure2);
  sendTo(3, out.pressure3);
  sendTo(4, out.pressure4);
  sendTo(5, out.pressure5);
  sendTo(6, out.pressure6);
  sendTo(7, out.pressure7);
  sendTo(8, out.pressure8);
  sendTo(9, out.pressure9);
  sendTo(10, out.pressure10);
}

void sendTo(int device, float value) {
  OscMessage message = new OscMessage("/actuator/inflate");
  message.add(clip(value, -100, 100));
  sendToOneActuator(message, device);
}

void draw() {
  background(color(0, 0, 30));

  currentMeasurement = readInputs();

  myTextarea1.setText(String.format(
        "Pressure bit 1: %1$10.2f \t Pressure bit 2:  %2$10.2f\n" +
        "Pressure bit 3: %3$10.2f \t Pressure bit 4:  %4$10.2f\n" +
        "Pressure bit 5: %5$10.2f \t Pressure bit 6:  %6$10.2f\n" +
        "Pressure bit 7: %7$10.2f \t Pressure bit 8:  %8$10.2f\n" +
        "Pressure bit 9: %9$10.2f \t Pressure bit 10: %10$10.2f\n" +
        "Button state:  %11$2.0f \t Force sensor: %12$8.2f\n",
        new Float( currentMeasurement.pressure1 ), new Float( currentMeasurement.pressure2 ),
        new Float( currentMeasurement.pressure3 ), new Float( currentMeasurement.pressure4 ),
        new Float( currentMeasurement.pressure5 ), new Float( currentMeasurement.pressure6 ),
        new Float( currentMeasurement.pressure7 ), new Float( currentMeasurement.pressure8 ),
        new Float( currentMeasurement.pressure9 ), new Float( currentMeasurement.pressure10 ),
        new Float(currentMeasurement.button), new Float(currentMeasurement.forceSensor)
                                    )
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

class PlayAudio implements Interaction {
  protected SoundFile audio;
  protected String textMessage;

  public PlayAudio(SoundFile audio, String text) {
    this.audio = audio;
    this.textMessage = text;
  }

  public void prepare(Measurement ignore, ControlP5 cp5) {
    if (textMessage != null) {
      myTextarea2.setText(textMessage);
    }
    audio.play();
  }

  public Output run(Measurement ignore) {
    return null;
  }

  public void teardown(ControlP5 cp5) {
    myTextarea2.setText("");
    audio.stop();
  }
}

class SetPressure implements Interaction {
  Controller slider;
  Measurement initialState;
  float target;
  float[] diffs = new float[10];

  public void prepare(Measurement initialState, ControlP5 cp5) {
    this.slider = cp5.getController("Target_Pressure");
    slider.setVisible(true);
    target = slider.getValue();
    this.initialState = initialState;
    setDiffs(target, initialState);
  }

  private void setDiffs(float target, Measurement in) {
    diffs[0] = target - in.pressure1;
    diffs[1] = target - in.pressure2;
    diffs[2] = target - in.pressure3;
    diffs[3] = target - in.pressure4;
    diffs[4] = target - in.pressure5;
    diffs[5] = target - in.pressure6;
    diffs[6] = target - in.pressure7;
    diffs[7] = target - in.pressure8;
    diffs[8] = target - in.pressure9;
    diffs[9] = target - in.pressure10;
  }

  public void teardown(ControlP5 cp5) {
    slider.setVisible(false);
  }

  public Output run(Measurement in) {
    if (slider.getValue() != target) {
      target = slider.getValue();
      setDiffs(target, in);
    }
    Output out = new Output(update(diffs[0], target, in.pressure1),
                            update(diffs[1], target, in.pressure2),
                            update(diffs[2], target, in.pressure3),
                            update(diffs[3], target, in.pressure4),
                            update(diffs[4], target, in.pressure5),
                            update(diffs[5], target, in.pressure6),
                            update(diffs[6], target, in.pressure7),
                            update(diffs[7], target, in.pressure8),
                            update(diffs[8], target, in.pressure9),
                            update(diffs[9], target, in.pressure10)
                            );
    return out;
  }

  private float update(float initialDiff, float target, float current) {
    if (initialDiff > 0 && target - current > 0) {
      return 10 * (float)Math.log(target - current);
    } else if (initialDiff < 0 && target - current < 0) {
      return 10 * -(float)Math.log(-(target - current));
    } else {
      return 0;
    }
  }
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

  else if (theOscMessage.addrPattern().contains("/sensor/force")) {
    forceSensor = ((Float)theOscMessage.arguments()[0]);
  }
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
    print("Unhandled OSC message");
    printOSCMessage(theOscMessage);
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

  try {
      // checking valid integer using parseInt() method
      Integer.parseInt(addrComponents[2]);

      for(int i=0, j=0;i<newAddress.length;i++,j++){
        if(i==2) i++;
        newAddress[j] = addrComponents[i];
      }

      return join(newAddress,"/");
  }
  catch (Exception e) { //this means that it is not an integer and then it is meant for all actuators
    return theOscMessage.addrPattern();
  }

}


// /sensor/x becomes /[id]/sensor/x
void addSensorValuetoHashMap(OscMessage theOscMessage){
  int id = getDeviceId(theOscMessage.netAddress());
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

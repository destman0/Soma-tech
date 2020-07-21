PrintWriter recordPressure=null;

SimpleDateFormat dateFormatter=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSS");
SimpleDateFormat fileNameFormat=new SimpleDateFormat("'pressure'-yyyy-MM-dd-HH-mm-ss.'log'");

void endCapture(){
  if(!interact1&&recordPressure!=null){
    recordPressure.flush();
    recordPressure.close();
    recordPressure=null;
  }
}

void prepare(){
  if(interact1 && recordPressure == null){
    Date startTime=new Date();
    recordPressure = createWriter(fileNameFormat.format(startTime));
    recordPressure.println("Time,Pressure1,Pressure2,Pressure3,Pressure4,Button");
  }
}

float readFloat(String from,float defaultValue){
  if(sensorInputs.containsKey(from)){
    Object[]inputs=sensorInputs.get(from);
    return inputs.length>0?((Float)inputs[0]).floatValue():defaultValue;
  }else{
    return defaultValue;
  }
}

Measurement readInputs() {
  return new Measurement(System.currentTimeMillis(),
                         readFloat("1/pressure", 0.0),
                         readFloat("2/pressure", 0.0),
                         readFloat("3/pressure", 0.0),
                         readFloat("4/pressure", 0.0),
                         0.0,
                         buttonStatus
                         );
}

float GOAL_PRESSURE = 1300;
float GOAL_TOLERANCE = 10;

void adjustPressure(float current, float goal, int device){
  float diff=current - goal;
  if(abs(diff) > goal){
    OscMessage message = new OscMessage("/actuator/inflate");
    float adjustment=diff > 0.0 ? -log(diff) : log(-(diff)) * 10;
    message.add(adjustment);
    sendToOneActuator(message,device);
  }
}

enum FollowInteractionState {
  Stopped,
  Setup,
  Measure,
  Phase,
  AntiPhase
}

FollowInteractionState followInteractionState = FollowInteractionState.Stopped;

long startTimeMs = 0l;

class Measurement {
  public long timeMs;
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;
  public int button;

  public Measurement(long timeMs, float pressure1, float pressure2, float pressure3, float pressure4, float pressure5, int button) {
    this.timeMs = timeMs;
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
    this.button = button;
  }
}

void interaction_One(){
  myTextarea2.setText("Interaction 1");
  Measurement in = readInputs();

  switch (followInteractionState) {
  case Stopped:
    setupFollowInteraction();
    followInteractionState = FollowInteractionState.Setup;
    break;
  case Setup:
    boolean done = adjustPressureTo(GOAL_PRESSURE, in);
    if (done) {
      followInteractionState = FollowInteractionState.Measure;
    }
    break;
  case Measure:
    break;
  case Phase:
    break;
  case AntiPhase:
    break;
  }
}

void setupFollowInteraction() {
  startTimeMs = System.currentTimeMillis();
}

boolean adjustPressureTo(float goal, Measurement values) {
  adjustPressure(values.pressure1, goal, 1);
  adjustPressure(values.pressure2, goal, 2);
  adjustPressure(values.pressure3, goal, 3);
  adjustPressure(values.pressure4, goal, 4);
  adjustPressure(values.pressure5, goal, 5);

  return ((values.pressure1 != 0.0 && abs(values.pressure1 - goal) <= GOAL_TOLERANCE )
             && (values.pressure2 != 0.0 &&  abs(values.pressure2 - goal) <= GOAL_TOLERANCE )
             && (values.pressure3 != 0.0 &&  abs(values.pressure3 - goal) <= GOAL_TOLERANCE )
             && (values.pressure4 != 0.0 &&  abs(values.pressure4 - goal) <= GOAL_TOLERANCE )
             && (values.pressure5 != 0.0 &&  abs(values.pressure5 - goal) <= GOAL_TOLERANCE )
          );
}

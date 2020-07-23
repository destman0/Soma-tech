PrintWriter recordPressure=null;

SimpleDateFormat dateFormatter=new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSS");
SimpleDateFormat fileNameFormat=new SimpleDateFormat("'pressure'-yyyy-MM-dd-HH-mm-ss.'log'");

float GOAL_PRESSURE = 1300;
float GOAL_TOLERANCE = 10;
long MEASUREMENT_PHASE_TIME = 1 * 60 * 1000;

void adjustPressure(float current, float goal, int device){
  OscMessage message = new OscMessage("/actuator/inflate");
  float diff = current - goal;
  float adjustment = (abs(diff) > GOAL_TOLERANCE)
    ? diff > 0.0 ? -5 - (log(diff) * 5) : 5 + (log(-(diff)) * 10)
    : 0.0;
  message.add(adjustment);
  sendToOneActuator(message,device);
}

enum FollowInteractionState {
  Stopped,
  Setup,
  Measure,
  Phase,
  AntiPhase,
  Completed
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

  public String toString() {
    return "Measurement("
      + "timeMs=" + String.valueOf(timeMs)       + ","
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5) + ","
      + "button=" + String.valueOf(button)
      + ")";
  }
}

class Output {
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;

  public Output(float pressure1, float pressure2, float pressure3, float pressure4, float pressure5) {
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
  }

  public String toString() {
    return "Measurement("
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5)
      + ")";
  }

  public Output sum(Output o) {
    return new Output(this.pressure1 + o.pressure1,
                      this.pressure2 + o.pressure2,
                      this.pressure3 + o.pressure3,
                      this.pressure4 + o.pressure4,
                      this.pressure5 + o.pressure5
                      );
  }
}

ArrayList<Measurement> measurements = null;
ArrayList<Output> replayValues = null;
int replayIndex = 0;

void interaction_One(){
  Measurement in = readInputs();

  switch (followInteractionState) {
  case Stopped:
    myTextarea2.setText("Follow Breathing Interaction");
    followInteractionState = FollowInteractionState.Setup;
    break;
  case Setup:
    myTextarea2.setText("Follow Breathing Interaction: Inflating");
    boolean done = adjustPressureTo(GOAL_PRESSURE, in);
    if (done) {
      setupFollowInteraction();
      followInteractionState = FollowInteractionState.Measure;
    }
    break;
  case Measure:
    stopAllPillows();
    long elapsedTime = in.timeMs - startTimeMs;
    long remainingTime = MEASUREMENT_PHASE_TIME - elapsedTime;
    myTextarea2.setText("Follow Breathing Interaction: Measurement Phase\n"
                        + (remainingTime / (1000)) + " seconds remaining.");
    if (elapsedTime > MEASUREMENT_PHASE_TIME) {
      followInteractionState = FollowInteractionState.Phase;
      replayValues = calculateReplayValues(measurements);
      replayIndex = 0;
    } else {
      measurements.add(in);
    }
    break;
  case Phase:
    myTextarea2.setText("Follow Breathing Interaction: Mirroring Phase");
    if (replayIndex < replayValues.size()) {
      println("Reply index=" + replayIndex + "Values: " + replayValues.get(replayIndex));
      sendOutputValues(replayValues.get(replayIndex));
      replayIndex++;
    } else {
      followInteractionState = FollowInteractionState.Completed;
    }
    break;
  case AntiPhase:
    break;
  case Completed:
    myTextarea2.setText("Done!");
  }
}

void initializeFollowBreathing() {
  followInteractionState = FollowInteractionState.Stopped;
  measurements = new ArrayList(1000);
}

void setupFollowInteraction() {
  startTimeMs = System.currentTimeMillis();
}

boolean adjustPressureTo(float goal, Measurement values) {
  if (values.pressure1 != 0.0) adjustPressure(values.pressure1, goal, 1);
  if (values.pressure2 != 0.0) adjustPressure(values.pressure2, goal, 2);
  if (values.pressure3 != 0.0) adjustPressure(values.pressure3, goal, 3);
  if (values.pressure4 != 0.0) adjustPressure(values.pressure4, goal, 4);
  if (values.pressure5 != 0.0) adjustPressure(values.pressure5, goal, 5);

  return ((values.pressure1 == 0.0 || abs(values.pressure1 - goal) <= GOAL_TOLERANCE )
             && (values.pressure2 == 0.0 || abs(values.pressure2 - goal) <= GOAL_TOLERANCE )
             && (values.pressure3 == 0.0 || abs(values.pressure3 - goal) <= GOAL_TOLERANCE )
             && (values.pressure4 == 0.0 || abs(values.pressure4 - goal) <= GOAL_TOLERANCE )
             && (values.pressure5 == 0.0 || abs(values.pressure5 - goal) <= GOAL_TOLERANCE )
          );
}

void stopAllPillows() {
  OscMessage m = new OscMessage("/actuator/inflate");
  m.add(0.0);
  sendToAllActuators(m);
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
  message.add(value);
  sendToOneActuator(message,device);
}

float DIFF_TO_MOTOR_RATIO = 20000;

ArrayList<Output> calculateReplayValues(ArrayList<Measurement> inputs) {
  List<Output> smoothed = slidingAvg(toPressures(inputs), 10);
  ArrayList<Output> result = new ArrayList(inputs.size());
  for (int i = 1; i < smoothed.size(); i++) {
    Measurement pm = inputs.get(i - 1);
    Measurement cm = inputs.get(i);
    Output p = smoothed.get(i - 1);
    Output c = smoothed.get(i);
    result.add(new Output(
                          diffToMotor(diff(pm.timeMs, cm.timeMs, p.pressure1, c.pressure1)),
                          diffToMotor(diff(pm.timeMs, cm.timeMs, p.pressure2, c.pressure2)),
                          diffToMotor(diff(pm.timeMs, cm.timeMs, p.pressure3, c.pressure3)),
                          diffToMotor(diff(pm.timeMs, cm.timeMs, p.pressure4, c.pressure4)),
                          diffToMotor(diff(pm.timeMs, cm.timeMs, p.pressure5, c.pressure5))
    ));
  }
  return result;
}

float diffToMotor(float diffValue) {
  return clip(-diffValue * DIFF_TO_MOTOR_RATIO + 10, -50, 50);
}

Output getPressures(Measurement m) {
  return new Output(m.pressure1, m.pressure2, m.pressure3, m.pressure4, m.pressure5);
}

<T> List<List<T>> sliding(List<T> in, int size) {
  ArrayList<List<T>> res = new ArrayList(in.size());
  for (int i = 0; i < in.size(); i++) {
    res.add(in.subList(max(0, i - size), min(i + size, in.size())));
  }
  return res;
}

List<Output> toPressures(List<Measurement> ms) {
  ArrayList<Output> res = new ArrayList(ms.size());
  for (Measurement m : ms) {
    res.add(new Output(m.pressure1,
                       m.pressure2,
                       m.pressure3,
                       m.pressure4,
                       m.pressure5
                       ));
  }
  return res;
}

Output averages(List<Output> xs) {
  Output res = new Output(0, 0, 0, 0, 0);
  for (Output x : xs) {
    res = res.sum(x);
  }
  res.pressure1 /= xs.size();
  res.pressure2 /= xs.size();
  res.pressure3 /= xs.size();
  res.pressure4 /= xs.size();
  res.pressure5 /= xs.size();
  return res;
}

List<Output> slidingAvg(List<Output> xs, int windowSize) {
  List<List<Output>> windowed = sliding(xs, windowSize);
  ArrayList<Output> res = new ArrayList<Output>(xs.size());
  for (List<Output> window : windowed) {
    res.add(averages(window));
  }
  return res;
}

float diff(long x1, long x2, float y1, float y2) {
  return x1 == x2
    ? 0.0
    : (y2 - y1) / (x2 - x1);
}

float clip(float val, float from, float to) {
  return val > to
    ? to
    : val < from
    ? from
    : val;
}

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

class BreathMirroring implements Interaction {

  public BreathMirroring(SoundFile instructionsAudio,
                         SoundFile exerciseAudio,
                         SoundFile beforeReply,
                         SoundFile endAudio,
                         TreeMap<Long, Output> instructionsTiming) {
    this.instructionsAudio = instructionsAudio;
    this.exerciseAudio = exerciseAudio;
    this.instructionsTiming = instructionsTiming;
    this.beforeReplyAudio = beforeReply;
    this.endAudio = endAudio;
  }

  SoundFile instructionsAudio;
  SoundFile exerciseAudio;
  SoundFile beforeReplyAudio;
  SoundFile endAudio;
  TreeMap<Long, Output> instructionsTiming;

  // String instructionsAudioPath =  "Breathing-1-instructions.mp3";
  // String exerciseAudioPath =  "Breathing-1-exercise.mp3";

  float GOAL_PRESSURE = 1210;
  float GOAL_TOLERANCE = 20;
  long MEASUREMENT_PHASE_TIME = 1 * 60 * 1000;

  long startTimeMs = 0l;


  ArrayList<Measurement> measurements = null;
  ArrayList<Output> replayValues = null;
  int replayIndex = 0;

  public String buttonName = "Breathing Mirroring";

  public void prepare(Measurement initial, ControlP5 cp5) {
    runner = new StateMachineRunner<Measurement>(instructionsState, initial);
  }

  public void teardown(ControlP5 cp5) {
    stopAllPillows();
    instructionsAudio.stop();
    exerciseAudio.stop();
  }

  StateMachineRunner<Measurement> runner;

  // This one is complex because it has an internal state machine.
  State<Measurement> instructionsState = new State<Measurement>() {
      long position() { return (long) round(instructionsAudio.position() * 1000.0); }
      TreeMap<Long, Output> timings;
      StateMachineRunner<Measurement> internal;

      // Internal states for the instructions state
      State<Measurement> preInflate = new State<Measurement>() {
          public void enter(Measurement in) {}
          public State<Measurement> run(Measurement in) {
            boolean done = adjustPressureTo(1040, in);
            long instructionsStart = timings.size() > 0 ? timings.firstKey() : 5000;
            if (position() < instructionsStart) {
              return this;
            } else {
              return instructions;
            }
          }
          public void exit() {}
        };
      State<Measurement> instructions = new State<Measurement>() {
          public void enter(Measurement in) {}
          public State<Measurement> run(Measurement in) {
            Map.Entry<Long, Output> entry = timings.lowerEntry(position());
            if (entry == null) {
              // Nothing to do, state in this state
              return this;
            } else if (timings.lastKey() == entry.getKey()) {
              // This is the last entry, so we change state
              return postInflate;
            } else {
              // Run entry "effect"
              sendOutputValues(entry.getValue());
              return this;
            }
          }
          public void exit() {}
        };
      State<Measurement> postInflate = new State<Measurement>() {
          public void enter(Measurement in) {}
          public State<Measurement> run(Measurement in) {
            boolean done = adjustPressureTo(GOAL_PRESSURE, in);
            if (done && !instructionsAudio.isPlaying()) {
              return null;
            } else {
              return this;
            }
          }
          public void exit() {}
        };

      public void enter(Measurement in) {
        myTextarea2.setText("Follow Breathing Interaction");
        instructionsAudio.play();
        timings = instructionsTiming;
        // Initialize internal state machine
        internal = new StateMachineRunner<Measurement>(preInflate, in);
      }
      public State<Measurement> run(Measurement in) {
        // We actually want actually do some interaction here
        if (internal.isRunning()) {
          internal.run(in);
          return this;
        } else {
          return measureState;
        }
      }
      public void exit() {}
    };

  // Creating a new state that inherits 
  State<Measurement> measureState = new State<Measurement>() {
      // Setup everything when the state starts
      public void enter(Measurement in) {
        startTimeMs = in.timeMs;
        measurements = new ArrayList(1000);
        stopAllPillows();
        exerciseAudio.play();
        myTextarea2.setText("Follow Breathing Interaction: Follow the instructions\n");
      }
      // This is called in every iteration
      public State<Measurement> run(Measurement in) {
        long elapsedTime = in.timeMs - startTimeMs;
        if (exerciseAudio.isPlaying()) {
          measurements.add(in);
          // Return the next state, which is unchanged (e.g. not changing state)
          return this;
        } else {
          // Return change to "replayState", exit will be called
          return beforeReply;
        }
      }
      public void exit() {
        replayValues = calculateReplayValues(measurements);
        replayIndex = 0;
        println("End Measure");
      }
    };

  State<Measurement> beforeReply = new State<Measurement>() {
      public void enter(Measurement in) {
        beforeReplyAudio.play();
      }

      public State<Measurement> run(Measurement in) {
        if (beforeReplyAudio.isPlaying()) {
          return this;
        } else {
          return replayState;
        }
      }

      public void exit() {
        beforeReplyAudio.stop();
      }
    };

  State<Measurement> replayState = new State<Measurement>() {
      public void enter(Measurement in) {
        myTextarea2.setText("Follow Breathing Interaction:\n Breathe naturally, feel your breath being replayed.");
      }
      public State<Measurement> run(Measurement in) {
        if (replayIndex < replayValues.size()) {
          Output outValues = replayValues.get(replayIndex);
          replayIndex++;
          sendOutputValues(outValues);
          return this;
        } else {
          return outroState;
        }
      }
      public void exit() {}
    };

  State<Measurement> outroState = new State<Measurement>() {
      long startTime;
      public void enter(Measurement in) {
        myTextarea2.setText("Done!");
        startTime = in.timeMs;
        endAudio.play();
      }
      public State<Measurement> run(Measurement in) {
        stopAllPillows();
        if (in.timeMs - startTime < 1000 || endAudio.isPlaying()) {
          return this;
        }
        // Returning "null" as next state will stop the state machine runner
        return null;
      }
      public void exit() {
        endAudio.stop();
      }
    };

  public Output run(Measurement in) {
    runner.run(in);
    return null;
  }

  // Here starts the code that sends data and manipulates the recordings
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

  void adjustPressure(float current, float goal, int device){
    float diff = current - goal;
    float a = -0.007;
    float b = -1.2;
    float c = 5.0;
    float adjustment = (current < goal + (GOAL_TOLERANCE / 4.0) || current > goal + GOAL_TOLERANCE)
      ? (a * abs(diff) * diff) + (b * diff) + c
      : 0.0;
    sendTo(device, adjustment);
  }

  void stopAllPillows() {
    OscMessage m = new OscMessage("/actuator/inflate");
    m.add(0.0);
    sendToAllActuators(m);
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
    return diffValue > 0
      ? clip(diffValue * DIFF_TO_MOTOR_RATIO + 10, 10, 60)
      : clip(diffValue * DIFF_TO_MOTOR_RATIO, -40, -5);
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

float readFloat(String from,float defaultValue){
  if(sensorInputs.containsKey(from)){
    Object[]inputs=sensorInputs.get(from);
    return inputs.length>0?((Float)inputs[0]).floatValue():defaultValue;
  }else{
    return defaultValue;
  }
}

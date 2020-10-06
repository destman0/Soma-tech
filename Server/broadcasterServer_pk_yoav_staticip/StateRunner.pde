interface State<Tin> {
  public void enter(Tin in);
  public State<Tin> run(Tin in);
  public void exit();
}

abstract class MeasurementState implements State<Measurement> {
    long startTimeMs;
    long stateTime(Measurement in) {
        return in.timeMs - startTimeMs;
    }
    public void enter(Measurement in) {
        startTimeMs = in.timeMs;
    }
    public void exit() {}
}

class StateMachineRunner<Tin> {
  private State<Tin> currentState;
  StateMachineRunner(State<Tin> initialState, Tin initialEvent) {
    if (initialState != null) {
      initialState.enter(initialEvent);
      currentState = initialState;
    }
  }

  public void run(Tin in) {
    State<Tin> nextState;
    if (currentState != null) {
      nextState = currentState.run(in);
      if (nextState != currentState) {
        currentState.exit();
        if (nextState != null) {
          nextState.enter(in);
        }
        currentState = nextState;
      }
    }
  }

  public boolean isRunning() {
    return currentState != null;
  }

  public void stop() {
      currentState = null;
  }
}

public State<Measurement> fromTimings(final TreeMap<Long, Output> timings, final State<Measurement> nextState) {
    return new MeasurementState() {
        public State<Measurement> run(Measurement in) {
            Map.Entry<Long, Output> entry = timings.lowerEntry(stateTime(in));
            if (entry == null) {
                // Nothing to do, stay in this state
                return this;
            } else if (timings.lastKey() == entry.getKey()) {
                // This is the last entry, so we change state
                return nextState;
            } else {
                // Run entry "effect"
                sendOutputValues(entry.getValue());
                return this;
            }
        }
    };
}

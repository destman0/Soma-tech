interface State<Tin> {
  public void enter(Tin in);
  public State<Tin> run(Tin in);
  public void exit();
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
}

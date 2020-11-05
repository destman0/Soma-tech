public class SectionBreathingInteraction extends RecordingInteraction {
    int repetitions = 4;
    ControlP5 cp5;

    final float INHALE_AMOUNT = 60;
    final float INHALE_SECONDARY_AMOUNT = 25;
    final float EXHALE_AMOUNT = -80;
    final float EXHALE_SECONDARY_AMOOUNT = -30;

  public SectionBreathingInteraction() {
    super("sectionBreathing");
  }

    class HoldState extends MeasurementState {
        State<Measurement> nextState;
        public HoldState(State<Measurement> nextState) { this.nextState = nextState; }

        void enter(Measurement in) {
            super.enter(in);
            myTextarea2.setText("Hold");
        }

        public State<Measurement> run(Measurement in) {
            sendOutputValues(new Output());
            if (stateTime(in) < 3000) {
                return this;
            } else {
                return nextState;
            }
        }
    }

    class LowerInhaleState extends MeasurementState {
        State<Measurement> nextState;
        public LowerInhaleState(State<Measurement> nextState) { this.nextState = nextState; }

        void enter(Measurement in) {
            super.enter(in);
            myTextarea2.setText("Inhale to lower abdomen");
        }

        public State<Measurement> run(Measurement in) {
            if (stateTime(in) < 3000) {
                sendOutputValues(new Output()
                                 .set1(INHALE_AMOUNT)
                                 .scale(1.33)
                                 .scale(easeOutSine(stateTime(in) / 3000.0)));
                return this;
            } else {
                return new HoldState(nextState);
            }
        }
    }

    class MiddleInhaleState extends MeasurementState {
        State<Measurement> nextState;
        public MiddleInhaleState(State<Measurement> nextState) { this.nextState = nextState; }

        void enter(Measurement in) {
            super.enter(in);
            myTextarea2.setText("Inhale to center abdomen");
        }

        public State<Measurement> run(Measurement in) {
            if (stateTime(in) < 3000) {
                sendOutputValues(new Output().set1(INHALE_SECONDARY_AMOUNT).set2(INHALE_AMOUNT));
                return this;
            } else {
                return new HoldState(nextState);
            }
        }
    }

    class ThoraicInhaleState extends MeasurementState {
        State<Measurement> nextState;
        public ThoraicInhaleState(State<Measurement> nextState) { this.nextState = nextState; }

        void enter(Measurement in) {
            super.enter(in);
            myTextarea2.setText("Inhale to chest");
        }

        public State<Measurement> run(Measurement in) {
            if (stateTime(in) < 3000) {
                sendOutputValues(new Output()
                                 .set2(INHALE_SECONDARY_AMOUNT)
                                 .set3(INHALE_AMOUNT)
                                 .set4(INHALE_AMOUNT)
                                 );
                return this;
            } else {
                return new HoldState(nextState);
            }
        }
    }

    StateMachineRunner<Measurement> runner;

    State<Measurement> instructions = new MeasurementState() {
            void enter(Measurement in) {
                myTextarea2.setText("Viloma breathing");  
                super.enter(in);
            }
            State<Measurement> run(Measurement in) {
                if (stateTime(in) < 5000) {
                    boolean done = adjustPressureTo(1040, in);
                    return this;
                }
                return inhaleExercise;
            }
        };

    State<Measurement> inhaleExercise = new State<Measurement>() {
            int round;
            StateMachineRunner<Measurement> exerciseRunner;

            final long exhaleTime = 8000;
            State<Measurement> smoothExhale = new MeasurementState() {
                    void enter(Measurement in) {
                        super.enter(in);
                        myTextarea2.setText("Exhale");  
                    }
                    State<Measurement> run(Measurement in) {
                        long time = stateTime(in);
                        if (time < exhaleTime) {
                            float ease = easeSineAndBack(time / (float)exhaleTime);
                            sendOutputValues(new Output(-60, -60, -40, -40, 0).scale(ease));
                            return this;
                        } else { // time > 12000
                            return breathNormally;
                        }
                    }
                };

            State<Measurement> breathNormally = new MeasurementState() {
                    void enter(Measurement in) {
                        super.enter(in);
                        myTextarea2.setText("Breath Normally");  
                    }
                    State<Measurement> run(Measurement in) {
                        if (stateTime(in) > 13500l) {
                            myTextarea2.setText("ready...");
                        }
                        if (stateTime(in) < 15000l) {
                            sendOutputValues(new Output());
                            return this;
                        } else {
                            return null; // Ending the exercise
                        }
                    }
                };

            State<Measurement> upperInhale = new ThoraicInhaleState(smoothExhale);
            State<Measurement> middleInhale = new MiddleInhaleState(upperInhale);
            State<Measurement> lowerInhale = new LowerInhaleState(middleInhale);

            void enter(Measurement in) {
                exerciseRunner = new StateMachineRunner(lowerInhale, in);
                round = 0;
            }

            State<Measurement> run(Measurement in) {
                if (exerciseRunner.isRunning()) {
                    exerciseRunner.run(in);
                    return this;
                } else if (round < repetitions) {
                    round++;
                    // Start another round
                    exerciseRunner = new StateMachineRunner(lowerInhale, in);
                    return this;
                } else {
                    return null;
                }
            }

            void exit() {
                myTextarea2.setText("Done!");
            }
        };

    public void prepare(Measurement initialState, ControlP5 cp5) {
      super.prepare(initialState, cp5);
      runner = new StateMachineRunner(instructions, initialState);
      this.cp5 = cp5;
    }

    public Output run(Measurement inputs) {
      super.run(inputs);
      runner.run(inputs);
      return null;
    }

    public void teardown(ControlP5 cp5) {
      super.teardown(cp5);
    }

}

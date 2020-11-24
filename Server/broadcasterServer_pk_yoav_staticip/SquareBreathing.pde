enum SquarePhase {
  INHALE,
  HOLD1,
  EXHALE,
  HOLD2
}

class SquareBreathing extends RecordingInteraction {
  private int interaction_part;
  private boolean interactionstarted = false;
  private long interactionstarttime;
  private long interactioncurrenttime;
  private int duration_chapter;
  private int n_cycles;
  private int current_cycle;
  private int phase = -1;
  private long remainingTimeForPhaseSec;
  private Output output;

  private ArrayList<SoundFile> countingAudio;
  private ArrayList<SoundFile> secondsAudio;
  private SoundFile exhaleAudio;
  private SoundFile inhaleAudio;
  private SoundFile holdAudio;
  private SoundFile instructionsAudio;
  private SoundFile outroAudio;
  private StateMachineRunner<Measurement> runner;

  public SquareBreathing(SoundFile instructions,
                         ArrayList<SoundFile> countingAudio,
                         ArrayList<SoundFile> secondsAudio,
                         SoundFile exhaleAudio,
                         SoundFile inhaleAudio,
                         SoundFile holdAudio,
                         SoundFile outroAudio) {
    super("squareBreathing");
    this.countingAudio = countingAudio;
    this.exhaleAudio = exhaleAudio;
    this.inhaleAudio = inhaleAudio;
    this.holdAudio   = holdAudio;
    this.instructionsAudio = instructions;
    this.outroAudio = outroAudio;
    this.secondsAudio = secondsAudio;
  }

  public void prepare(Measurement initialState, ControlP5 cp5) {
    super.prepare(initialState, cp5);
    interaction_part = 0;
    interactionstarted = false;
    current_cycle = 0;
    duration_chapter = 0;
    cp5.getController("Number_of_Cycles").setVisible(true);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    cp5.getController("Inflation_Rate").setVisible(true);
    cp5.getController("Deflation_Rate").setVisible(true);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);

    cp5.getController("1st_number_of_counts").setVisible(true);
    cp5.getController("2nd_number_of_counts").setVisible(true);
    cp5.getController("3rd_number_of_counts").setVisible(true);
    cp5.getController("4th_number_of_counts").setVisible(true);
    runner = new StateMachineRunner<Measurement>(instructions, initialState);
  }

  MeasurementState instructions = new MeasurementState() {
      public void enter(Measurement in) {
        super.enter(in);
        instructionsAudio.play();
      }
      public State<Measurement> run(Measurement in) {
        if (stateTime(in) < 22000 || instructionsAudio.isPlaying()) {
          output = new Output(0.0);
          return this;
        } else {
          return new ChapterState(0);
        }
      }
    };

  MeasurementState outroState = new MeasurementState() {
      public void enter(Measurement in) {
        super.enter(in);
        myTextarea2.setText("Done!");
      }

      public State<Measurement> run(Measurement in) {
        if (stateTime(in) < 2000l) {
          output = new Output(0);
          return this;
        } else {
          return null;
        }
      }
    };

  private class ChapterState extends MeasurementState {
    int chapterNum;
    StateMachineRunner<Measurement> cycleRunner;
    SoundFile chapterAudio;
    public ChapterState(int chapterNum) {
      this.chapterNum = chapterNum;
    }

    public void enter(Measurement in) {
      super.enter(in);
      println("Starting Chapter " + chapterNum);
      int numCycles = int(cp5.getController("Number_of_Cycles").getValue());
      CycleState cycleState = new CycleState(0, numCycles, getChapterCount(chapterNum));
      cycleRunner = new StateMachineRunner<Measurement>(cycleState, in);
      chapterAudio = getChapterLengthAudio(chapterNum);
      if (chapterAudio != null) {
        chapterAudio.play();
      }
    }

    public MeasurementState run(Measurement in) {
      if (chapterAudio != null && chapterAudio.isPlaying()) {
        output = new Output(0.0);
        return this;
      } else {
        cycleRunner.run(in);
        if (cycleRunner.isRunning()) {
          return this;
        } else if (chapterNum < 4) {
          return new ChapterState(chapterNum + 1);
        } else {
          return outroState;
        }
      }
    }
  }

  private class CycleState extends MeasurementState {
    int currentCycle;
    int numCycles;
    int count;
    StateMachineRunner<Measurement> phaseRunner;

    public CycleState(int currentCycle, int numCycles, int count) {
      this.currentCycle = currentCycle;
      this.numCycles = numCycles;
      this.count = count;
    }

    public void enter(Measurement in) {
      super.enter(in);
      println("Starting Cycle " + ( currentCycle + 1 ) + " out of " + numCycles + ". Counting up to " + count);
      PhaseState beginPhase = new PhaseState(SquarePhase.INHALE, 0, count);
      phaseRunner = new StateMachineRunner<Measurement>(beginPhase, in);
    }

    public State<Measurement> run(Measurement in) {
      phaseRunner.run(in);
      if (phaseRunner.isRunning()) {
        return this;
      } else if (currentCycle < numCycles - 1) {
        println("Phase ended, currentCycle " + ( currentCycle + 1 ) + "/" + numCycles + ", restarting phase");
        return new CycleState(currentCycle + 1, numCycles, count);
      } else {
        return null;
      }
    }
  }

  private class PhaseState extends MeasurementState {
    SquarePhase currentPhase;
    int currentCount;
    int maxCount;

    public PhaseState(SquarePhase phase, int currentCount, int maxCount) {
      currentPhase = phase;
      this.currentCount = currentCount;
      this.maxCount = maxCount;
    }

    public void enter(Measurement in) {
      super.enter(in);
      println("In phase " + currentPhase + ", Count: " + currentCount + "/" + maxCount);
      if (currentCount == 0) {
        playPhaseAudio(currentPhase);
      } else {
        playCountAudio(currentCount);
      }
    }

    public State<Measurement> run(Measurement in) {
      if (stateTime(in) < 1000l) {
        OscMessage myMessage1 = new OscMessage("/actuator/inflate");
        switch (currentPhase) {
        case INHALE:
          if(in_phase){
            output = new Output(cp5.getController("Inflation_Rate").getValue());
          } else {
            output = new Output(-(cp5.getController("Deflation_Rate").getValue()));
          }
          break;
        case HOLD1:
          output = new Output(0.0);
          break;
        case EXHALE:
          if(in_phase){
            output = new Output(-(cp5.getController("Deflation_Rate").getValue()));
          } else {
            output = new Output(cp5.getController("Inflation_Rate").getValue());
          }
          break;
        case HOLD2:
          output = new Output(0.0);
          break;
        }
        return this;
      } else {
        int nextCount = (currentCount + 1) % maxCount;
        SquarePhase nextPhase = nextCount == 0 ? getNextPhase(currentPhase) : currentPhase;
        print("Next count: " + nextCount + ", next phase: " + nextPhase);
        if (nextCount == 0 && nextPhase == SquarePhase.INHALE) {
          println(" - end of phase");
          // We've completed a cycle!
          return null;
        } else {
          println(" - continue phase");
          return new PhaseState(nextPhase, nextCount, maxCount);
        }
      }
    }
  }

  public Output run(Measurement inputs) {
    super.run(inputs);
    runner.run(inputs);
    return output;
  }

  public void teardown(ControlP5 cp5) {
    super.teardown(cp5);
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    
    cp5.getController("1st_number_of_counts").setVisible(false);
    cp5.getController("2nd_number_of_counts").setVisible(false);
    cp5.getController("3rd_number_of_counts").setVisible(false);
    cp5.getController("4th_number_of_counts").setVisible(false);
    
    for (SoundFile s : countingAudio) {
      s.stop();
    }
    for (SoundFile s : secondsAudio) {
      if (s != null) s.stop();
    }
    exhaleAudio.stop();
    inhaleAudio.stop();
    holdAudio.stop();
    instructionsAudio.stop();
    outroAudio.stop();
  }

  private int getChapterCount(int chapter) {
    switch(chapter)
      {
      case 0:
        return int(cp5.getController("1st_number_of_counts").getValue());
      case 1:
        return int(cp5.getController("2nd_number_of_counts").getValue());
      case 2:
        return int(cp5.getController("3rd_number_of_counts").getValue());
      case 3:
        return int(cp5.getController("4th_number_of_counts").getValue());
      default:
        return 0;
      }
  }

  private SoundFile getChapterLengthAudio(int chapter) {
    int chapterCount = getChapterCount(chapter);
    return (chapterCount > 0 && chapterCount <= secondsAudio.size())
      ? secondsAudio.get(chapterCount - 1)
      : null;
  }

  private long getDuration(int chapter) {
    int chapterCount = getChapterCount(chapter);
    return chapterCount > 0 ? chapterCount * 1000 : 3000;
  }

  private int calculateRemainingSec(long startTime, long currentTime, int phase, long phaseDuration) {
    long endTime = startTime + (( phase + 1 ) * phaseDuration);
    long remainingTimeForPhaseMs = endTime - currentTime - 1;
    return max((int)remainingTimeForPhaseMs / 1000, (int)0); 
  }

  private SquarePhase getNextPhase(SquarePhase phase) {
    switch (phase) {
    case INHALE:
      return SquarePhase.HOLD1;
    case HOLD1:
      return SquarePhase.EXHALE;
    case EXHALE:
      return SquarePhase.HOLD2;
    case HOLD2:
      return SquarePhase.INHALE;
    default:
      return null;
    }
  }

  private void playCountAudio(int count) {
    if (count < countingAudio.size()) {
      countingAudio.get(count).play();
    }
  }

  private void playPhaseAudio(SquarePhase phase) {
    switch (phase) {
    case INHALE:
      inhaleAudio.play();
      return;
    case EXHALE:
      exhaleAudio.play();
      return;
    case HOLD1: // Fall-through
    case HOLD2:
      holdAudio.play();
      return;
    }
  }
}

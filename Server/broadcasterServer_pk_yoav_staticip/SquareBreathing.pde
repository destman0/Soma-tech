class SquareBreathing implements Interaction {
  private int interaction_part;
  private boolean interactionstarted = false;
  private long interactionstarttime;
  private long interactioncurrenttime;
  private int duration_chapter;
  private int n_cycles;
  private int current_cycle;
  private int phase = -1;
  private long remainingTimeForPhaseSec;

  private ArrayList<SoundFile> countingAudio;
  private SoundFile exhaleAudio;
  private SoundFile inhaleAudio;
  private SoundFile holdAudio;
  private SoundFile instructionsAudio;
  private SoundFile outroAudio;

  private final int INHALE = 0;
  private final int HOLD1  = 1;
  private final int EXHALE = 2;
  private final int HOLD2  = 3;

  public SquareBreathing(SoundFile instructions, ArrayList<SoundFile> countingAudio, SoundFile exhaleAudio, SoundFile inhaleAudio, SoundFile holdAudio, SoundFile outroAudio) {
    this.countingAudio = countingAudio;
    this.exhaleAudio = exhaleAudio;
    this.inhaleAudio = inhaleAudio;
    this.holdAudio   = holdAudio;
    this.instructionsAudio = instructions;
    this.outroAudio = outroAudio;
  }

  public void prepare(Measurement initialState, ControlP5 cp5) {
    interaction_part = 0;
    interactionstarted = false;
    current_cycle = 0;
    duration_chapter = 0;
    cp5.getController("Number_of_Cycles").setVisible(true);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    cp5.getController("Inflation_Rate").setVisible(true);
    cp5.getController("Deflation_Rate").setVisible(true);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
  }

  public Output run(Measurement inputs) {
    //+++++++++++++++++++++++++++++++++Equal / Square Breathing++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    n_cycles = int(cp5.getController("Number_of_Cycles").getValue());
    if (interaction_part==0){
      if(interactionstarted==false){
        interactionstarttime = System.currentTimeMillis();
        interactionstarted = true;
        instructionsAudio.play();
      }

      interactioncurrenttime = System.currentTimeMillis();  

      if ((interactioncurrenttime - interactionstarttime) < 22000 || instructionsAudio.isPlaying()){
        myTextarea2.setText("The next exercise we are going to do is very much based on a yoga breathing exercise. We are going to inhale, hold our breath, exhale and hold our breath. And we are going to do that on the increasing number counts.");  
        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(0.0);
        sendToAllActuators(myMessage1);  
      } else {
        interaction_part = 1;
        interactionstarted=false;
      }
    }
    interactioncurrenttime = System.currentTimeMillis();
    if (interaction_part==1) { 
      if (duration_chapter<4){  
        if (current_cycle<n_cycles){
          if(interactionstarted==false){
            interactionstarttime = System.currentTimeMillis();
            interactionstarted = true;
          }
          int currentPhase = (int)((interactioncurrenttime - interactionstarttime) / getDuration(duration_chapter)) % 4;
          int currentRemainingTimeForPhaseSec = calculateRemainingSec(interactionstarttime, interactioncurrenttime, currentPhase, getDuration(duration_chapter));
          OscMessage myMessage1;
          myMessage1 = new OscMessage("/actuator/inflate");
          switch (currentPhase)
          {
          case INHALE: 
            //println("Inhale"); 
            if(in_phase){
              myMessage1.add((cp5.getController("Inflation_Rate").getValue())); 
            } else{
              myMessage1.add(-(cp5.getController("Deflation_Rate").getValue()));  
            }  
            sendToAllActuators(myMessage1);
            // myTextarea2.setText(( in_phase ? "INHALE    " : "EXHALE    " ) + currentRemainingTimeForPhaseSec);
            break;
          case HOLD1: 
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            // myTextarea2.setText("HOLD    "+currentRemainingTimeForPhaseSec);
            break;
          case EXHALE:
            //println("Exhale");  
            if(in_phase){
              myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
            }
            else {
              myMessage1.add(cp5.getController("Inflation_Rate").getValue());
            }
            sendToAllActuators(myMessage1);
            // myTextarea2.setText(( in_phase ? "EXHALE    " : "INHALE    " ) + currentRemainingTimeForPhaseSec);
            break;
          case HOLD2:
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            // myTextarea2.setText("HOLD    " + currentRemainingTimeForPhaseSec + 1);
            break;
          }
          if (phase != currentPhase) {
            playPhaseAudio(currentPhase);
            if (phase == 3 && currentPhase == 0) {
              interactionstarttime = interactioncurrenttime;
              // Hack to prevent the phase from changing next cycle
              currentRemainingTimeForPhaseSec = calculateRemainingSec(interactionstarttime, interactioncurrenttime, currentPhase, getDuration(duration_chapter));
              current_cycle++;
            }
          } else if (currentRemainingTimeForPhaseSec != remainingTimeForPhaseSec) {
            playCountAudio((int)currentRemainingTimeForPhaseSec);
          } 
          phase = currentPhase;
          remainingTimeForPhaseSec = currentRemainingTimeForPhaseSec;

        // That is debugging information, please unqote, if the interaction goes somewhere....
        /*
          myTextarea2.setText("Start time:    "+(interactionstarttime) + " \n\n" +
          "Current time:    "+(interactioncurrenttime)+ " \n\n" +
          "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
          "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur) +" \n\n" +
          "Cycle:    "+(current_cycle) + " \n\n" +
          "Duration Chapter:   " +(duration_chapter)+ " \n\n" +
          "Duration:    " + (phasedur));
          */
        }

        else{
          duration_chapter++;
          current_cycle=0;
          remainingTimeForPhaseSec = calculateRemainingSec(interactionstarttime, interactioncurrenttime, 0, getDuration(duration_chapter));
        }
      }
      else{
        interaction_part = 2;
        interactionstarted=false;  
        inhaleAudio.stop();
        if (!outroAudio.isPlaying()) outroAudio.play();
      }
    } 

    if (interaction_part==2){
      myTextarea2.setText("And this is the end of the exercise!");
      OscMessage myMessage1;
      myMessage1 = new OscMessage("/actuator/inflate");
      myMessage1.add(0.0);
      sendToAllActuators(myMessage1);
    }
    return null;
  }

  public void teardown(ControlP5 cp5) {
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(false);
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);
    
    for (SoundFile s : countingAudio) {
      s.stop();
    }
    exhaleAudio.stop();
    inhaleAudio.stop();
    holdAudio.stop();
    instructionsAudio.stop();
    outroAudio.stop();
  }

  private long getDuration(int chapter) {
    switch(chapter)
    {
    case 0:
      return 3000;
    case 1:
      return 5000;
    case 2:
      return 7000;
    case 3:
      return 9000;
    default:
      return 3000;
    }
  }

  private int calculateRemainingSec(long startTime, long currentTime, int phase, long phaseDuration) {
    long endTime = startTime + (( phase + 1 ) * phaseDuration);
    long remainingTimeForPhaseMs = endTime - currentTime - 1;
    return max((int)remainingTimeForPhaseMs / 1000, (int)0); 
  }

  private void playCountAudio(int count) {
    if (count < countingAudio.size()) {
      countingAudio.get(count).play();
    }
  }

  private void playPhaseAudio(int phase) {
    switch (phase) {
    case INHALE:
      ( in_phase ? inhaleAudio : exhaleAudio ).play();
      return;
    case EXHALE:
      ( in_phase ? exhaleAudio : inhaleAudio ).play();
      return;
    case HOLD1: // Fall-through
    case HOLD2: // Fall-through
      holdAudio.play();
      return;
    }
  }
}

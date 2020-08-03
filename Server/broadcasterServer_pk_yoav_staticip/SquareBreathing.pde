class SquareBreathing implements Interaction {
  private int interaction_part;
  private boolean interactionstarted = false;
  private long interactionstarttime;
  private long interactioncurrenttime;
  private int duration_chapter;
  private int n_cycles;
  private int current_cycle;
  private long phasedur;
  private int phase = -1;
  private long remainingTimeForPhaseSec;

  private ArrayList<SoundFile> countingAudio;
  private SoundFile exhaleAudio;
  private SoundFile inhaleAudio;
  private SoundFile holdAudio;

  private final int INHALE = 0;
  private final int HOLD1  = 1;
  private final int EXHALE = 2;
  private final int HOLD2  = 4;

  public SquareBreathing(ArrayList<SoundFile> countingAudio, SoundFile exhaleAudio, SoundFile inhaleAudio, SoundFile holdAudio) {
    this.countingAudio = countingAudio;
    this.exhaleAudio = exhaleAudio;
    this.inhaleAudio = inhaleAudio;
    this.holdAudio   = holdAudio;
  }

  public void prepare(Measurement initialState, ControlP5 cp5) {
    interaction_part = 0;
    interactionstarted = false;
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
      }

      interactioncurrenttime = System.currentTimeMillis();  

      if ((interactioncurrenttime - interactionstarttime)<10000){
        myTextarea2.setText("The next exercise we are going to do is very much based on a yoga breathing exercise. We are going to inhale, hold our breath, exhale and hold our breath. And we are going to do that on the increasing number counts.");  
        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");
        myMessage1.add(0.0);
        sendToAllActuators(myMessage1);  
      }
      else{
        interaction_part = 1;
        interactionstarted=false;
      }
    }
    if (interaction_part==1) { 
      if (duration_chapter<4){  
        if (current_cycle<n_cycles){
          if(interactionstarted==false){
            interactionstarttime = System.currentTimeMillis();
            interactionstarted = true;
          }
          interactioncurrenttime = System.currentTimeMillis();
          switch(duration_chapter)
          {
            case 0:
            phasedur = 3000;
            break;
            case 1:
            phasedur = 5000;
            break;
            case 2:
            phasedur = 7000;
            break;
            case 3:
            phasedur = 10000;
            break;  
          }
          int currentPhase = (int)((interactioncurrenttime - interactionstarttime) / phasedur);
          long endTime = interactionstarttime + (( currentPhase + 1 ) * phasedur);
          long remainingTimeForPhaseMs = endTime - interactioncurrenttime;
          long currentRemainingTimeForPhaseSec = remainingTimeForPhaseMs / 1000; 
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
            myTextarea2.setText(( in_phase ? "INHALE    " : "EXHALE    " ) + currentRemainingTimeForPhaseSec);
            break;
          case HOLD1: 
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            myTextarea2.setText("HOLD    "+currentRemainingTimeForPhaseSec);
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
            myTextarea2.setText(( in_phase ? "EXHALE    " : "INHALE    " )+currentRemainingTimeForPhaseSec);
            break;
          case HOLD2:
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            myTextarea2.setText("HOLD    "+currentRemainingTimeForPhaseSec);
            break;
        }
          if (phase != currentPhase) {
            playPhaseAudio(currentPhase);
          } else if (currentRemainingTimeForPhaseSec != remainingTimeForPhaseSec) {
            playCountAudio((int)currentRemainingTimeForPhaseSec);
          }

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
          if (((interactioncurrenttime - interactionstarttime)/phasedur)>3){
            interactionstarttime = interactioncurrenttime;
            current_cycle++;
            phase = -1;
          }
          phase = currentPhase;
          remainingTimeForPhaseSec = currentRemainingTimeForPhaseSec;
        }

        else{
          duration_chapter++;
          current_cycle=0;
        }
      }
      else{
        interaction_part = 2;
        interactionstarted=false;  
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
  }

  private void playCountAudio(int count) {
    println("Play audio for " + count);
    if (count < countingAudio.size()) {
      countingAudio.get(count).play();
    }
  }

  private void playPhaseAudio(int phase) {
    println("Play phase " + phase);
    switch (phase) {
    case INHALE:
      println("Play inhale " + phase);
      ( in_phase ? inhaleAudio : exhaleAudio ).play();
      return;
    case EXHALE:
      println("Play exhale " + phase);
      ( in_phase ? exhaleAudio : inhaleAudio ).play();
      return;
    case HOLD1: // Fall-through
    case HOLD2: // Fall-through
      println("Play hold " + phase);
      holdAudio.play();
      return;
    }
  }
}

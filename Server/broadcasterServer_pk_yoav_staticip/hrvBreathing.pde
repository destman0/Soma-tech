class HrvBreathing implements Interaction {

  SimpleDateFormat fileNameFormat = new SimpleDateFormat("'recording/hrvBreathing'-yyyy-MM-dd'T'HH-mm-ss.'log'");
  PrintWriter output = null;
  String fileName = null;
  SoundFile instructionsAudio;
  boolean recordInputs;

  public HrvBreathing(SoundFile instructions, boolean record) {
    this.instructionsAudio = instructions;
    this.recordInputs = record;
  }

  public HrvBreathing(SoundFile instructions) {
    this(instructions, false);
  }

  private ControlP5 cp5;
  private long interactionstarttime;
  private long interactioncurrenttime;
  private long longinteractionstarttime;
  private int interaction_part;
  private boolean interactionstarted;
  private int slow_breathing_duration;
  private long phasedur;
  private int phase;

  public void prepare(Measurement initial, ControlP5 cp5) {
    this.cp5 = cp5;
    interaction_part = 0;
    interactionstarted = false;
    cp5.getController("Number_of_Cycles").setVisible(false);
    cp5.getController("Duration_of_Exercise").setVisible(true);
    cp5.getController("Inflation_Rate").setVisible(true);
    cp5.getController("Deflation_Rate").setVisible(true);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(true);

    if (output != null) {
      output.close();
    }
    fileName = fileNameFormat.format(initial.timeMs);
    if (recordInputs) {
      output = createWriter(fileName);
      output.println(initial.csvHeading());
    }
  }

  public void teardown(ControlP5 cp5) {
    cp5.getController("Duration_of_Exercise").setVisible(false);
    cp5.getController("Inflation_Rate").setVisible(false);
    cp5.getController("Deflation_Rate").setVisible(false);
    cp5.getController("Inhale_or_Exhale_Duration").setVisible(false);

    if (recordInputs) {
      output.flush();
      output.close();
      output = null;
      fileName = null;
    }
  }

  public Output run(Measurement input) {
    // +++++++++++++++++++++++++++++++++++Slow HRV breathing++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if (recordInputs) {
      output.println(input.csvLine());
    }

    slow_breathing_duration = int(cp5.getController("Duration_of_Exercise").getValue());

    if (interaction_part==0){
      if(interactionstarted==false){
        interactionstarttime = input.timeMs;
        interactionstarted = true;
        instructionsAudio.play();
      }  

      interactioncurrenttime = input.timeMs;  

      if ((interactioncurrenttime - interactionstarttime)<10000 || instructionsAudio.isPlaying()){
        myTextarea2.setText("In this interaction we would like you to do your everyday latop activities, while wearing the artefact");  
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
      if(interactionstarted==false){
        interactionstarttime = System.currentTimeMillis();
        longinteractionstarttime = System.currentTimeMillis();
        interactionstarted = true;
      }

      if ((interactioncurrenttime - longinteractionstarttime)<(slow_breathing_duration*60000)) {
        interactioncurrenttime = System.currentTimeMillis();
        phasedur = int(cp5.getController("Inhale_or_Exhale_Duration").getValue()*1000);
        phase = (int)((interactioncurrenttime - interactionstarttime)/phasedur);

        OscMessage myMessage1;
        myMessage1 = new OscMessage("/actuator/inflate");

          switch (phase)
          {

            case 0: 
                //println("Inhale");  
                if(in_phase){
                  myMessage1.add(cp5.getController("Inflation_Rate").getValue()); 
                }
                else{
                  myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
                }        
                sendToAllActuators(myMessage1);
                //myTextarea2.setText("INHALE  "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
            break;
          case 1: 
                //println("Exhale"); 
                if (in_phase){
                  myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
                }
                else{
                  myMessage1.add(cp5.getController("Inflation_Rate").getValue()); 
                }
                sendToAllActuators(myMessage1);
                //myTextarea2.setText("HOLD "+(interactioncurrenttime-(phase*phasedur+interactionstarttime))/1000);
            break;
        }

        myTextarea2.setText("Long interacton start time:    "+(longinteractionstarttime) + " \n\n" +
          "Phase start time:    "+(interactionstarttime)+ " \n\n" +
          "Current time:    "+(interactioncurrenttime)+ " \n\n" +
          "Delta:    "+(interactioncurrenttime - interactionstarttime) + " \n\n" +
          "Phase:    "+((interactioncurrenttime - interactionstarttime)/phasedur));

        if (((interactioncurrenttime - interactionstarttime)/phasedur)>1){
            interactionstarttime = interactioncurrenttime;
        }
      } 
      else {
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

    // Changing values directly from the interaction...
    return null;
  }

}

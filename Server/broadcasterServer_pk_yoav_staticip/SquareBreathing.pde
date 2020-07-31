class SquareBreathing implements Interaction {
  private int interaction_part;
  private boolean interactionstarted = false;
  private long interactionstarttime;
  private long interactioncurrenttime;
  private int duration_chapter;
  private int n_cycles;
  private int current_cycle;
  private long phasedur;
  private int phase;

  public SquareBreathing() {}

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
          phase = (int)((interactioncurrenttime - interactionstarttime)/phasedur);
          OscMessage myMessage1;
          myMessage1 = new OscMessage("/actuator/inflate");
          switch (phase)
          {
            case 0: 
            //println("Inhale"); 
            if(in_phase){
              myMessage1.add((cp5.getController("Inflation_Rate").getValue())); 
            }
            else{
              myMessage1.add(-(cp5.getController("Deflation_Rate").getValue()));  
            }  
            sendToAllActuators(myMessage1);
            myTextarea2.setText("INHALE    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
            break;
          case 1: 
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            myTextarea2.setText("HOLD    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
            break;
          case 2:
            //println("Exhale");  
            if(in_phase){
              myMessage1.add(-(cp5.getController("Deflation_Rate").getValue())); 
            }
            else {
              myMessage1.add(cp5.getController("Inflation_Rate").getValue());
            }
            sendToAllActuators(myMessage1);
            myTextarea2.setText("EXHALE    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
            break;
          case 3:
            //println("Hold");  
            myMessage1.add(0.0); 
            sendToAllActuators(myMessage1);
            myTextarea2.setText("HOLD    "+(interactioncurrenttime+1000-(phase*phasedur+interactionstarttime))/1000);
            break;
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
          }
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
}

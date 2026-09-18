/** Timing/settings only; independent of Processing and physical devices. */
public class BreathSession {
  // Session minutes, inhale seconds, exhale seconds, inflate %, deflate %.
  public final double[] values = {15, 5.45, 5.45, 70, 70};
  public final double[] minimum = {1, 1, 1, 0, 0};
  public final double[] maximum = {60, 15, 15, 100, 100};
  public final double[] step = {1, .05, .05, 1, 1};
  public boolean running, paused, complete;
  public double elapsed;
  public final double preparation = 10;
  public void start(){elapsed=0;running=true;paused=false;complete=false;}
  public void stop(){elapsed=0;running=false;paused=false;complete=false;}
  public void update(double seconds){
    if(!running || paused)return;
    elapsed+=Math.max(0,seconds);
    if(elapsed>=preparation+values[0]*60){elapsed=preparation+values[0]*60;running=false;complete=true;}
  }
  public void togglePause(){if(running)paused=!paused;}
  public boolean preparing(){return running && elapsed<preparation;}
  public double activeElapsed(){return Math.max(0,elapsed-preparation);}
  public double cycleTime(){return activeElapsed()%(values[1]+values[2]);}
  public boolean inhaling(){return cycleTime()<values[1];}
  public double phaseDuration(){return inhaling()?values[1]:values[2];}
  public double phaseElapsed(){return inhaling()?cycleTime():cycleTime()-values[1];}
  public double phaseRemaining(){return preparing()?preparation-elapsed:Math.max(0,phaseDuration()-phaseElapsed());}
  public double remaining(){return Math.max(0,values[0]*60-activeElapsed());}
  public double pace(){return 60/(values[1]+values[2]);}
  public double lift(){if(!running || preparing())return 0;return inhaling()?phaseElapsed()/values[1]:1-phaseElapsed()/values[2];}
  public float command(){return !running||paused||preparing()?0:inhaling()?(float)values[3]:-(float)values[4];}
  public void set(int i,double value){
    if(i<3 && running)return;
    values[i]=Math.max(minimum[i],Math.min(maximum[i],Math.round(value/step[i])*step[i]));
  }
}

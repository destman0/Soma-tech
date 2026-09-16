/** Restart-only timed deflation; no pressure target or sensor dependency. */
public class PressureReset {
  public boolean active, reached;
  private long started, durationMs;
  private float strength;
  public void start(long now,double seconds,float deflationStrength){
    started=now;durationMs=Math.max(0,Math.round(seconds*1000));
    strength=Math.max(0,Math.min(100,deflationStrength));
    active=true;reached=false;
  }
  public void cancel(){active=false;reached=false;}
  public double remaining(long now){return Math.max(0,durationMs-(now-started))/1000.0;}
  public float update(long now){
    if(!active)return 0;
    if(now-started>=durationMs){active=false;reached=true;return 0;}
    return -strength;
  }
}

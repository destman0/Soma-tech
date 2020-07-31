public interface Interaction {
  public void prepare(Measurement initialState, ControlP5 cp5);

  public Output run(Measurement inputs);

  public void teardown(ControlP5 cp5);
}

class Measurement {
  public long timeMs;
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;
  public int button;

  public Measurement(long timeMs, float pressure1, float pressure2, float pressure3, float pressure4, float pressure5, int button) {
    this.timeMs = timeMs;
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
    this.button = button;
  }

  public String toString() {
    return "Measurement("
      + "timeMs=" + String.valueOf(timeMs)       + ","
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5) + ","
      + "button=" + String.valueOf(button)
      + ")";
  }
}

class Output {
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;

  public Output(float pressure1, float pressure2, float pressure3, float pressure4, float pressure5) {
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
  }

  public String toString() {
    return "Measurement("
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5)
      + ")";
  }

  public Output sum(Output o) {
    return new Output(this.pressure1 + o.pressure1,
                      this.pressure2 + o.pressure2,
                      this.pressure3 + o.pressure3,
                      this.pressure4 + o.pressure4,
                      this.pressure5 + o.pressure5
                      );
  }
}

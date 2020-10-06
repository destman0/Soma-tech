import java.util.function.*;

public interface Interaction {
  public void prepare(Measurement initialState, ControlP5 cp5);

  public Output run(Measurement inputs);

  public void teardown(ControlP5 cp5);
}

public static SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSS");

class Measurement {
  public long timeMs;
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;
  public int button;
  public float forceSensor;

  public Measurement(Measurement m) {
    this(m.timeMs,
         m.pressure1,
         m.pressure2,
         m.pressure3,
         m.pressure4,
         m.pressure5,
         m.button,
         m.forceSensor);
  }

  public Measurement(long  timeMs,
                     float pressure1,
                     float pressure2,
                     float pressure3,
                     float pressure4,
                     float pressure5,
                     int   button,
                     float forceSensor) {
    this.timeMs = timeMs;
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
    this.button = button;
    this.forceSensor = forceSensor;
  }

  public String toString() {
    return "Measurement("
      + "timeMs=" + String.valueOf(timeMs)       + ","
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5) + ","
      + "button=" + String.valueOf(button)       + ","
      + "forceSensor=" + String.valueOf(forceSensor)
      + ")";
  }

  public String csvHeading() {
    return "time, pressure1, pressure2, pressure3, pressure4, pressure5, button, forceSensor";
  }

  public String csvLine() {
    return ""
      + dateFormatter.format(timeMs) + ","
      + String.valueOf(pressure1) + ","
      + String.valueOf(pressure2) + ","
      + String.valueOf(pressure3) + ","
      + String.valueOf(pressure4) + ","
      + String.valueOf(pressure5) + ","
      + String.valueOf(button)       + ","
      + String.valueOf(forceSensor);
  }
}

class Output {
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;

  public Output() {
    this(0.0);
  }

  public Output(float all) {
    this(all, all, all, all, all);
  }

  public Output(float pressure1, float pressure2, float pressure3, float pressure4, float pressure5) {
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
  }

  public Output(Output other) {
    this.pressure1 = other.pressure1;
    this.pressure2 = other.pressure2;
    this.pressure3 = other.pressure3;
    this.pressure4 = other.pressure4;
    this.pressure5 = other.pressure5;
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
    return new Output(constrain(this.pressure1 + o.pressure1, -100, 100),
                      constrain(this.pressure2 + o.pressure2, -100, 100),
                      constrain(this.pressure3 + o.pressure3, -100, 100),
                      constrain(this.pressure4 + o.pressure4, -100, 100),
                      constrain(this.pressure5 + o.pressure5, -100, 100)
                      );
  }

  public Output setAll(float v) { return set1(v).set2(v).set3(v).set4(v).set5(v); }
  public Output set1(float v) { pressure1 = constrain(v, -100, 100); return this; }
  public Output set2(float v) { pressure2 = constrain(v, -100, 100); return this; }
  public Output set3(float v) { pressure3 = constrain(v, -100, 100); return this; }
  public Output set4(float v) { pressure4 = constrain(v, -100, 100); return this; }
  public Output set5(float v) { pressure5 = constrain(v, -100, 100); return this; }

  public Output map1(Function<Float, Float> f) { return set1(f.apply(pressure1)); }
  public Output map2(Function<Float, Float> f) { return set2(f.apply(pressure2)); }
  public Output map3(Function<Float, Float> f) { return set3(f.apply(pressure3)); }
  public Output map4(Function<Float, Float> f) { return set4(f.apply(pressure4)); }
  public Output map5(Function<Float, Float> f) { return set5(f.apply(pressure5)); }

  public Output mapAll(Function<Float, Float> f) {
    set1(f.apply(pressure1));
    set2(f.apply(pressure2));
    set3(f.apply(pressure3));
    set4(f.apply(pressure4));
    return set5(f.apply(pressure5));
  }

  public Output scale(final float factor) {
    return mapAll(new Function<Float, Float>(){ public Float apply(Float x) { return x * factor; }});
  }
}

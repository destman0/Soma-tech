import java.util.function.*;

public interface Interaction {
  public void prepare(Measurement initialState, ControlP5 cp5);

  public Output run(Measurement inputs);

  public void teardown(ControlP5 cp5);
}

public abstract class RecordingInteraction implements Interaction {
  protected PrintWriter output = null;
  protected String fileName = null;
  protected String interactionName;
  protected boolean isRecording = false;

  SimpleDateFormat fileNameFormat;
  protected RecordingInteraction(String name) {
    this.interactionName = name;
    this.fileNameFormat = new SimpleDateFormat("'recording/"
                                               + name + "'"
                                               +"-yyyy-MM-dd'T'HH-mm-ss.'log'");
  }

  public void prepare(Measurement initialState, ControlP5 cp5) {
    if (recording) {  // `recording` is set by a ControlP5 toggle
      startRecording(initialState);
    }
  }

  protected void startRecording(Measurement data) {
    isRecording = true;
    if (output != null) {
      output.close();
    }
    fileName = fileNameFormat.format(data.timeMs);
    output = createWriter(fileName);
    output.println(data.csvHeading());
  }

  public Output run(Measurement inputs) {
    if (recording && !isRecording) {
      startRecording(inputs);
    } else if (!recording && isRecording) {
      stopRecording();
    }
    if (isRecording) {
      output.println(inputs.csvLine());
    }
    return null;
  }

  protected void stopRecording() {
    if (isRecording) {
      isRecording = false;
      output.flush();
      output.close();
      output = null;
      fileName = null;
    }
  }

  public void teardown(ControlP5 cp5) {
    stopRecording();
  }

}

public float clip(float v, float minValue, float maxValue) {
  return v < minValue
    ? minValue
    : (v > maxValue
         ? maxValue
         : v);
}

public static SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSS");

class Measurement {
  public long timeMs;
  public float pressure1;
  public float pressure2;
  public float pressure3;
  public float pressure4;
  public float pressure5;
  public float pressure6;
  public float pressure7;
  public float pressure8;
  public float pressure9;
  public float pressure10;
  public int button;
  public float forceSensor;

  public Measurement(Measurement m) {
    this(m.timeMs,
         m.pressure1,
         m.pressure2,
         m.pressure3,
         m.pressure4,
         m.pressure5,
         m.pressure6,
         m.pressure7,
         m.pressure8,
         m.pressure9,
         m.pressure10,
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
  public Measurement(long  timeMs,
                     float pressure1,
                     float pressure2,
                     float pressure3,
                     float pressure4,
                     float pressure5,
                     float pressure6,
                     float pressure7,
                     float pressure8,
                     float pressure9,
                     float pressure10,
                     int   button,
                     float forceSensor) {
    this(timeMs, pressure1, pressure2, pressure3, pressure4, pressure5, button, forceSensor);
    this.pressure6 = pressure6;
    this.pressure7 = pressure7;
    this.pressure8 = pressure8;
    this.pressure9 = pressure9;
    this.pressure10 = pressure10;
  }

  public String toString() {
    return "Measurement("
      + "timeMs=" + String.valueOf(timeMs)       + ","
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5) + ","
      + "pressure6=" + String.valueOf(pressure6) + ","
      + "pressure6=" + String.valueOf(pressure6) + ","
      + "pressure7=" + String.valueOf(pressure7) + ","
      + "pressure9=" + String.valueOf(pressure9) + ","
      + "pressure10=" + String.valueOf(pressure10) + ","
      + "button=" + String.valueOf(button)       + ","
      + "forceSensor=" + String.valueOf(forceSensor)
      + ")";
  }

  public String csvHeading() {
    return "time,pressure1,pressure2,pressure3,pressure4,pressure5,pressure6,pressure7,pressure8,pressure9,pressure10,button,forceSensor";
  }

  public String csvLine() {
    return ""
      + dateFormatter.format(timeMs) + ","
      + String.valueOf(pressure1) + ","
      + String.valueOf(pressure2) + ","
      + String.valueOf(pressure3) + ","
      + String.valueOf(pressure4) + ","
      + String.valueOf(pressure5) + ","
      + String.valueOf(pressure6) + ","
      + String.valueOf(pressure7) + ","
      + String.valueOf(pressure8) + ","
      + String.valueOf(pressure9) + ","
      + String.valueOf(pressure10) + ","
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
  public float pressure6;
  public float pressure7;
  public float pressure8;
  public float pressure9;
  public float pressure10;

  public Output() {
    this(0.0);
  }

  public Output(float all) {
    this(all, all, all, all, all, all, all, all, all, all);
  }

  public Output(float pressure1, float pressure2, float pressure3, float pressure4, float pressure5) {
    this.pressure1 = pressure1;
    this.pressure2 = pressure2;
    this.pressure3 = pressure3;
    this.pressure4 = pressure4;
    this.pressure5 = pressure5;
  }

  public Output(float pressure1, float pressure2, float pressure3, float pressure4, float pressure5,
                float pressure6, float pressure7, float pressure8, float pressure9, float pressure10) {
    this(pressure1, pressure2, pressure3, pressure4, pressure5);
    this.pressure6 = pressure6;
    this.pressure7 = pressure7;
    this.pressure8 = pressure8;
    this.pressure9 = pressure9;
    this.pressure10 = pressure10;
  }

  public Output(Output other) {
    this.pressure1 = other.pressure1;
    this.pressure2 = other.pressure2;
    this.pressure3 = other.pressure3;
    this.pressure4 = other.pressure4;
    this.pressure5 = other.pressure5;
    this.pressure6 = other.pressure6;
    this.pressure7 = other.pressure7;
    this.pressure8 = other.pressure8;
    this.pressure9 = other.pressure9;
    this.pressure10 = other.pressure10;
  }

  public String toString() {
    return "Output("
      + "pressure1=" + String.valueOf(pressure1) + ","
      + "pressure2=" + String.valueOf(pressure2) + ","
      + "pressure3=" + String.valueOf(pressure3) + ","
      + "pressure4=" + String.valueOf(pressure4) + ","
      + "pressure5=" + String.valueOf(pressure5) + ","
      + "pressure6=" + String.valueOf(pressure6) + ","
      + "pressure7=" + String.valueOf(pressure7) + ","
      + "pressure8=" + String.valueOf(pressure8) + ","
      + "pressure9=" + String.valueOf(pressure9) + ","
      + "pressure10=" + String.valueOf(pressure10)
      + ")";
  }

  public Output sum(Output o) {
    return new Output(this.pressure1 + o.pressure1,
                      this.pressure2 + o.pressure2,
                      this.pressure3 + o.pressure3,
                      this.pressure4 + o.pressure4,
                      this.pressure5 + o.pressure5,
                      this.pressure6 + o.pressure6,
                      this.pressure7 + o.pressure7,
                      this.pressure8 + o.pressure8,
                      this.pressure9 + o.pressure9,
                      this.pressure10 + o.pressure10
                      );
  }

  public Output setAll(float v) {
    return set1(v).set2(v).set3(v).set4(v).set5(v)
      .set6(v).set7(v).set8(v).set9(v).set10(v);
  }
  public Output set1(float v) { pressure1 = v; return this; }
  public Output set2(float v) { pressure2 = v; return this; }
  public Output set3(float v) { pressure3 = v; return this; }
  public Output set4(float v) { pressure4 = v; return this; }
  public Output set5(float v) { pressure5 = v; return this; }
  public Output set6(float v) { pressure6 = v; return this; }
  public Output set7(float v) { pressure7 = v; return this; }
  public Output set8(float v) { pressure8 = v; return this; }
  public Output set9(float v) { pressure9 = v; return this; }
  public Output set10(float v) { pressure10 = v; return this; }

  public Output map1(Function<Float, Float> f) { return set1(f.apply(pressure1)); }
  public Output map2(Function<Float, Float> f) { return set2(f.apply(pressure2)); }
  public Output map3(Function<Float, Float> f) { return set3(f.apply(pressure3)); }
  public Output map4(Function<Float, Float> f) { return set4(f.apply(pressure4)); }
  public Output map5(Function<Float, Float> f) { return set5(f.apply(pressure5)); }
  public Output map6(Function<Float, Float> f) { return set6(f.apply(pressure6)); }
  public Output map7(Function<Float, Float> f) { return set7(f.apply(pressure7)); }
  public Output map8(Function<Float, Float> f) { return set8(f.apply(pressure8)); }
  public Output map9(Function<Float, Float> f) { return set9(f.apply(pressure9)); }
  public Output map10(Function<Float, Float> f) { return set10(f.apply(pressure10)); }

  public Output mapAll(Function<Float, Float> f) {
    map1(f);
    map2(f);
    map3(f);
    map4(f);
    map5(f);
    map6(f);
    map7(f);
    map8(f);
    map9(f);
    return map10(f);
  }

  public Output scale(final float factor) {
    Function<Float, Float> scale = new Function<Float, Float>(){ public Float apply(Float x) { return x * factor; }};
    return mapAll(scale);
  }

  Function<Float, Float> clipOutput = new Function<Float, Float>(){
      public Float apply(Float v) { return clip(v.floatValue(), -100f, 100f);}
    };

  public Output clipAll() {
    return mapAll(clipOutput);
  }
}

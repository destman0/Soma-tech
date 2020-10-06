class Record extends Measurement {
    public Record(Measurement m, Output o) {
      super(m);
    }
}

class RecordAll implements Interaction {
  SimpleDateFormat fileNameFormat = new SimpleDateFormat("'recording/pressure'-yyyy-MM-dd'T'HH-mm-ss.'log'");
  PrintWriter output = null;
  String fileName = null;
  int samplesSize = (3 * 60 /* 3 minutes */ * (1000/50 /* samples per second */ ));
  ArrayList<Measurement> samples;
  public void prepare(Measurement initial, ControlP5 cp5) {
    samples = new ArrayList<Measurement>(samplesSize);
    if (output != null) {
      output.close();
    }
    fileName = fileNameFormat.format(initial.timeMs);
    output = createWriter(fileName);
    output.println(initial.csvHeading());
    myTextarea2.setText("Recording to " + fileName);
  }

  public Output run(Measurement inputs) {
    output.println(inputs.csvLine());
    return null;
  }

  public void teardown(ControlP5 cp5) {
    myTextarea2.setText("Recording ended.");
    dump();
  }

  private void dump() {
    if (output == null) {
      output = createWriter(fileName);
    }
    for (Measurement sample : samples) {
      output.println(sample.csvLine());
    }
    output.flush();
    output.close();
    output = null;
    fileName = null;
  }
}

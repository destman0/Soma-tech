// UI and original OSC server adapter. Both pressure displays read device 2.
BreathSession breath=new BreathSession();
int PRESSURE_DEVICE_ID=2;
java.util.concurrent.ConcurrentHashMap<String,Long> pressureSeen=new java.util.concurrent.ConcurrentHashMap<String,Long>();
long lastBreathTick;
int focusSetting=-1;
int ink=#233F45, muted=#657D80, teal=#318D88, violet=#7D79AC, line=#DEE9E7;
String notice="Choose a pace that feels comfortable, then start when you are ready.";
String[] settingLabels={"Session length","Inflate for","Deflate for","Inflation strength","Deflation strength"};
String[] units={"min","sec","sec","%","%"};
boolean captureMode(){return args!=null && args.length>0 && args[0].equals("--capture");}
void setupBreathingUI(){
  setupAdaptiveWindow();
  surface.setTitle("ComfyTime");textFont(createFont("Segoe UI",18));
  cp5.setAutoDraw(false);cp5.hide();lastBreathTick=System.nanoTime();
}
void updateBreathing(){long now=System.nanoTime();breath.update((now-lastBreathTick)/1e9);lastBreathTick=now;}
void sendBreathCommand(float command){OscMessage m=new OscMessage("/actuator/inflate");m.add(command);sendToAllActuators(m);}
boolean manualIn(){return selection==SelectedInteraction.InflateAll;}
boolean manualOut(){return selection==SelectedInteraction.DeflateAll;}
boolean manual(){return manualIn()||manualOut();}
void startBreathing(){pressureReset.cancel();breath.start();lastBreathTick=System.nanoTime();selection=SelectedInteraction.SlowBreathing;sendBreathCommand(0);notice="10 seconds to settle in. Let the footrest move quietly beneath your feet.";}
void stopBreathing(){pressureReset.cancel();breath.stop();selection=SelectedInteraction.StopAll;sendBreathCommand(0);notice="Stopped. Pumps are off; the pads are not actively deflating.";}
void toggleBreathing(){
  if(pressureReset.active)return;
  if(!breath.running){startBreathing();return;}
  updateBreathing();breath.togglePause();lastBreathTick=System.nanoTime();sendBreathCommand(breath.command());
  notice=breath.paused?"Paused. Pumps are off. Resume whenever you are ready.":"Take a moment to notice the movement beneath your feet.";
}
void manualBreathing(boolean inflate){pressureReset.cancel();breath.stop();selection=inflate?SelectedInteraction.InflateAll:SelectedInteraction.DeflateAll;if(inflate)inflating_Units();else deflating_Units();notice="Manual control uses the strength sliders. Press Stop to stop the pumps.";}
boolean hit(float x,float y,float w,float h){return uiMouseX()>=x&&uiMouseX()<=x+w&&uiMouseY()>=y&&uiMouseY()<=y+h;}
void label(String s,float x,float y,float size,int c){fill(c);textAlign(LEFT,BASELINE);textSize(size);text(s,x,y);}
void centered(String s,float x,float y,float size,int c){fill(c);textAlign(CENTER,BASELINE);textSize(size);text(s,x,y);textAlign(LEFT,BASELINE);}
void card(float x,float y,float w,float h){noStroke();fill(#E2EAE6);rect(x,y+3,w,h,25);fill(#FFFFFF);rect(x,y,w,h,25);}
void button(String s,float x,float y,float w,int bg,int fg){noStroke();fill(hit(x,y,w,46)?lerpColor(bg,ink,.08):bg);rect(x,y,w,46,13);centered(s,x+w/2,y+29,16,fg);}
String clockText(double seconds){int sec=(int)Math.ceil(Math.max(0,seconds));return nf(sec/60,2)+":"+nf(sec%60,2);}
void drawBreathingUI(){
  pushMatrix(); translate(uiOffsetX(),uiOffsetY()); scale(uiScale());
  background(#F1F5F1);noStroke();
  label("ComfyTime",36,51,34,ink);
  fill(#E1ECE7);rect(1000,24,244,36,18);centered("REFLECTIVE FOOTREST",1122,48,13,teal);
  label("A moment to settle",36,108,30,ink);
  label("A gentle rise and fall beneath your feet. Space to pause, notice and reflect.",36,139,17,muted);
  card(36,164,748,652);card(806,164,438,652);
  label("FOOTREST MOVEMENT",64,202,12,muted);
  String state=pressureReset.active?"RESTART / DEFLATING":manual()?"MANUAL CONTROL":breath.paused?"PAUSED":breath.complete?"SESSION COMPLETE":breath.preparing()?"SETTLE IN":breath.running?"GENTLE MOVEMENT":"READY WHEN YOU ARE";
  centered(state,410,233,13,teal);
  float lift=(float)breath.lift();float eased=.5-.5*cos(PI*lift);
  float diameter=174+64*eased;
  int phaseColor=breath.running&&!breath.preparing()&&!breath.inhaling()?violet:teal;
  noStroke();
  fill(lerpColor(phaseColor,#FFFFFF,.9));ellipse(410,363,diameter+18,diameter+18);
  fill(lerpColor(phaseColor,#FFFFFF,.78));ellipse(410,363,diameter,diameter);
  String cue=pressureReset.active?"Deflating":manualIn()?"Inflating":manualOut()?"Deflating":breath.paused?"Paused":breath.preparing()?"Get ready":breath.complete?"Finished":!breath.running?"Settle in":breath.inhaling()?"Rising":"Softening";
  centered(cue,410,358,30,ink);
  String detail=pressureReset.active?nf((float)pressureReset.remaining(System.nanoTime()/1000000),0,1)+" sec":manual()?"Press Stop to finish":breath.running?nf((float)breath.phaseRemaining(),0,1)+" sec":nf((float)breath.pace(),0,1)+" cycles / min";
  centered(detail,410,389,16,phaseColor);
  centered(pressureReset.active?"Session starts after this deflation":manual()?"Timer reset":clockText(breath.remaining())+" session remaining",410,526,16,muted);
  button(pressureReset.active?"Deflating...":breath.running?(breath.paused?"Resume":"Pause"):"Start session",100,547,230,teal,#FFFFFF);
  button("Restart",346,547,130,#EBF0EC,ink);button("Stop",492,547,228,#F8E7E2,#A34B40);
  label("Manual control",100,631,15,ink);label("Runs until Stop",100,650,12,muted);
  button("Inflate pads",310,610,195,manualIn()?teal:#E3EFE9,manualIn()?#FFFFFF:teal);
  button("Deflate pads",521,610,199,manualOut()?violet:#EDEBF5,manualOut()?#FFFFFF:violet);
  drawPad(250,696,lift,"LEFT LEG");drawPad(566,696,lift,"RIGHT LEG");
  centered("Illustrative movement / both pressure displays use device 2",410,797,12,muted);
  label("Shape the movement",834,206,23,ink);
  label("One rise + one fall = one movement cycle",834,234,14,muted);
  fill(#EDF3EF);rect(834,253,382,71,16);
  label(nf((float)breath.pace(),0,1),853,301,32,teal);label("cycles / min",928,299,16,muted);
  for(int i=0;i<5;i++)drawSetting(i);
  label(breath.running?"Stop the session to edit timing.":"Timing changes update the pace above.",834,751,13,muted);
  label("Strength is pump command, not air flow.",834,777,13,muted);
  label(notice,36,851,14,muted);
  label("SPACE  start / pause     S or ESC  stop     R  restart     TAB + arrows  adjust settings",36,880,12,muted);
  popMatrix();
  if(captureMode()){
    if(frameCount==3)saveFrame("preview-ready.png");
    if(frameCount==4){startBreathing();breath.elapsed=breath.preparation+2.7;}
    if(frameCount==6){saveFrame("preview-movement.png");exit();}
  }
}
void drawPad(float x,float y,float lift,String title){
  // Fabric side profile: the upper surface swells while the base stays grounded.
  float fullness=.5-.5*cos(PI*constrain(lift,0,1));
  float crown=y+5-27*fullness;
  noStroke();fill(#EBEEEA);ellipse(x,y+37,205,16);
  fill(#91B7AA);
  beginShape();vertex(x-96,y+29);
  bezierVertex(x-83,y+20,x-93,crown-2,x-72,crown);
  bezierVertex(x-28,crown-14,x+31,crown-12,x+72,crown+1);
  bezierVertex(x+91,crown-2,x+82,y+20,x+97,y+29);
  bezierVertex(x+62,y+47,x-60,y+47,x-96,y+29);endShape(CLOSE);
  // Softly lit fabric surface, pinched at the corners rather than a rectangular cap.
  fill(#B9D1C4);
  beginShape();vertex(x-96,y+29);
  bezierVertex(x-83,y+20,x-93,crown-2,x-72,crown);
  bezierVertex(x-28,crown-14,x+31,crown-12,x+72,crown+1);
  bezierVertex(x+91,crown-2,x+82,y+20,x+97,y+29);
  bezierVertex(x+42,y+20,x-43,y+22,x-96,y+29);endShape(CLOSE);
  noFill();stroke(#749E90);strokeWeight(1.2);
  bezier(x-94,y+29,x-40,y+42,x+43,y+42,x+95,y+29);
  // Corner folds and a soft highlight suggest sewn fabric.
  stroke(#9ABAAB);
  bezier(x-85,y+24,x-72,y+20,x-75,crown+10,x-66,crown+6);
  bezier(x+86,y+24,x+74,y+18,x+77,crown+12,x+66,crown+8);
  stroke(#D9E7DE);strokeWeight(2);
  bezier(x-50,crown+3,x-22,crown-5,x+20,crown-5,x+46,crown+3);
  noStroke();
  centered(title,x,y+61,11,muted);
  String key=PRESSURE_DEVICE_ID+"/pressure";Object[] data=sensorInputs.get(key);Long seen=pressureSeen.get(key);
  boolean fresh=seen!=null&&System.currentTimeMillis()-seen<2000;
  String pressure="Waiting for sensor";
  if(data!=null&&data.length>0&&data[0] instanceof Number)pressure=nf(((Number)data[0]).floatValue(),0,1)+" raw"+(fresh?"":" / stale");
  centered(pressure,x,y+83,15,fresh?ink:muted);
}
void drawSetting(int i){
  float y=356+i*75;boolean locked=i<3&&breath.running;
  label(settingLabels[i],834,y,15,locked?muted:ink);
  label((i==1||i==2?nf((float)breath.values[i],0,2):str((int)breath.values[i]))+" "+units[i],1124,y,15,teal);
  float knob=map((float)breath.values[i],(float)breath.minimum[i],(float)breath.maximum[i],874,1162);
  stroke(line);strokeWeight(6);line(874,y+25,1162,y+25);stroke(locked?#BDCFC7:teal);line(874,y+25,knob,y+25);noStroke();fill(locked?#BDCFC7:teal);ellipse(knob,y+25,16,16);
  if(focusSetting==i){noFill();stroke(ink);strokeWeight(1);ellipse(knob,y+25,24,24);noStroke();}
  centered("-",847,y+31,22,muted);centered("+",1190,y+31,22,muted);
}
void changeSetting(int i,double v){breath.set(i,v);if(i<3&&breath.running)notice="Stop the session to change timing. Strength stays adjustable.";}
void mousePressed(){
  if(hit(100,547,230,46)){toggleBreathing();return;}if(hit(346,547,130,46)){restartAtPressure();return;}if(hit(492,547,228,46)){stopBreathing();return;}
  if(hit(310,610,195,46)){manualBreathing(true);return;}if(hit(521,610,199,46)){manualBreathing(false);return;}
  for(int i=0;i<5;i++){float y=381+i*75;if(hit(831,y-18,375,36)){focusSetting=i;if(uiMouseX()<866)changeSetting(i,breath.values[i]-breath.step[i]);else if(uiMouseX()>1174)changeSetting(i,breath.values[i]+breath.step[i]);else changeSetting(i,map(uiMouseX(),874,1162,(float)breath.minimum[i],(float)breath.maximum[i]));return;}}
}
void mouseDragged(){int i=focusSetting;if(i>=0&&hit(866,363+i*75,308,36))changeSetting(i,map(uiMouseX(),874,1162,(float)breath.minimum[i],(float)breath.maximum[i]));}
void keyPressed(){if(key==ESC){key=0;stopBreathing();}else if(key==' ')toggleBreathing();else if(key=='s'||key=='S')stopBreathing();else if(key=='r'||key=='R')restartAtPressure();else if(key==TAB){focusSetting=(focusSetting+1)%5;key=0;}else if(key==CODED&&focusSetting>=0){int i=focusSetting;if(keyCode==LEFT||keyCode==DOWN)changeSetting(i,breath.values[i]-breath.step[i]);if(keyCode==RIGHT||keyCode==UP)changeSetting(i,breath.values[i]+breath.step[i]);}}
public void exit(){if(oscP5!=null)sendBreathCommand(0);super.exit();}

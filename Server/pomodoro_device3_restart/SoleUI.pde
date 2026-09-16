// Participant interface. Existing OSC transport and interaction_Three own actuation.
// Change these IDs if the two foot pads use different entries in DeviceIPs.
int LEFT_PAD_ID = 3, RIGHT_PAD_ID = 3;
java.util.concurrent.ConcurrentHashMap<String, Long> uiSeen = new java.util.concurrent.ConcurrentHashMap<String, Long>();
boolean uiPaused = false;
boolean uiRestartDeflating = false;
long uiRestartDuration;
float uiRestartLift;
long uiPausedAt;
int uiFocus = -1;
int uiInk=#233E3B, uiMuted=#637570, uiTeal=#287F73, uiCoral=#C9644E, uiLine=#DEE6DF;
String[] uiNames={"Pomodoro_Duration","Rest_Duration","Activation_Duration","Deactivation_Duration","Inflation_Rate","Deflation_Rate"};
String[] uiLabels={"Focus time","Break time","Inflate for","Deflate for","Inflation strength","Deflation strength"};
String[] uiUnits={"min","min","sec","sec","%","%"};
int[] uiMin={1,1,3,3,0,0}, uiMax={50,20,50,50,100,100};
String uiNotice="Settle in. Choose your timing, then start when you are ready.";
void setupSole(){
  surface.setTitle("Sole | Inflatable footrest Pomodoro");
  textFont(createFont("Segoe UI",18));
  for(String name:uiNames) {
    Controller c=cp5.getController(name);
    if(c instanceof Knob) ((Knob)c).snapToTickMarks(false);
    if(c instanceof Slider) ((Slider)c).snapToTickMarks(false);
  }
  // Defaults: focus (min), break (min), inflate (sec), deflate (sec), inflation strength (%), deflation strength (%).
  int[] defaults={25,5,36,50,100,100};
  for(int i=0;i<6;i++)cp5.getController(uiNames[i]).setValue(defaults[i]);
  cp5.hide(); // Disable legacy widget hit targets as well as their rendering.
}
boolean uiRunning(){return selection==SelectedInteraction.Pomodoro && interaction_part<2;}
float uiValue(int i){return cp5.getController(uiNames[i]).getValue();}
long uiNow(){return uiPaused?uiPausedAt:System.currentTimeMillis();}
int uiPhase(){return uiRestartDeflating?3:!uiRunning()?-1:interaction_part==0?0:phase+1;}
long uiDuration(){
  if(uiRestartDeflating)return uiRestartDuration;
  int p=uiPhase();
  return p==0?10000:p==1?(long)(uiValue(2)*1000):p==2?(long)(uiValue(0)*60000):p==3?(long)(uiValue(3)*1000):p==4?(long)(uiValue(1)*60000):(long)(uiValue(0)*60000);
}
long uiElapsed(){
  if(uiRestartDeflating)return Math.max(0,uiNow()-interactionstarttime);
  if(!uiRunning() || !interactionstarted)return 0;
  long t=uiNow()-interactionstarttime;
  int p=uiPhase();
  if(p>=2)t-=activation_duration;
  if(p>=3)t-=pomodoro_duration;
  if(p>=4)t-=deactivation_duration;
  return Math.max(0,t);
}
String uiTime(long ms){int sec=(int)Math.ceil(Math.max(0,ms)/1000.0);return nf(sec/60,2)+":"+nf(sec%60,2);}
void uiText(String s,float x,float y,float sz,int col){fill(col);textAlign(LEFT,BASELINE);textSize(sz);text(s,x,y);}
void uiCenter(String s,float x,float y,float sz,int col){fill(col);textAlign(CENTER,BASELINE);textSize(sz);text(s,x,y);textAlign(LEFT,BASELINE);}
void uiCard(float x,float y,float w,float h){noStroke();fill(#E6EAE3);rect(x,y+3,w,h,24);fill(#FFFFFF);rect(x,y,w,h,24);}
boolean uiHit(float x,float y,float w,float h){return mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h;}
void uiButton(String s,float x,float y,float w,int bg,int fg){
  fill(uiHit(x,y,w,46)?lerpColor(bg,uiInk,.08):bg);noStroke();rect(x,y,w,46,13);uiCenter(s,x+w/2,y+29,16,fg);
}
void drawSole(){
  background(#F4F3ED);noStroke();
  uiText("sole",36,53,34,uiInk);uiText("A little lift for your focus.",115,51,17,uiMuted);
  fill(#E4ECE5);rect(942,25,302,38,19);uiCenter("FOOTREST  /  POMODORO",1093,50,13,uiTeal);
  uiText("Put your feet up. Time to focus.",36,109,30,uiInk);
  uiText("The pads inflate, stay raised while you focus, then deflate for your break.",36,139,17,uiMuted);
  uiCard(36,163,748,592);uiCard(806,163,438,592);
  String[] phases={"Get ready","Inflating","Focus","Deflating","Break"};
  boolean manualInflate=selection==SelectedInteraction.InflateAll;
  boolean manualDeflate=selection==SelectedInteraction.DeflateAll;
  boolean manual=manualInflate || manualDeflate;
  int p=uiPhase();String status=manualInflate?"Manual / inflating":manualDeflate?"Manual / deflating":uiPaused?"Paused":p>=0?phases[constrain(p,0,4)]:interaction_part==2?"Session complete":"Ready when you are";
  if(uiRestartDeflating)status=uiPaused?"Restart deflation / paused":"Deflating before restart";
  uiCenter(status.toUpperCase(),410,205,14,uiTeal);
  noFill();stroke(uiLine);strokeWeight(10);ellipse(410,330,210,210);
  float progress=uiRunning()?constrain((float)uiElapsed()/uiDuration(),0,1):0;
  stroke(p>=3?uiCoral:uiTeal);if(progress>0)arc(410,330,210,210,-HALF_PI,-HALF_PI+TWO_PI*progress);noStroke();
  uiCenter(manual?"Manual":uiTime(uiDuration()-uiElapsed()),410,340,manual?38:52,uiInk);
  uiCenter(manual?"Press Stop to finish":uiRunning()?"remaining":"focus time",410,372,15,uiMuted);
  uiButton(uiRunning()?(uiPaused?"Resume":"Pause"):"Start Pomodoro",100,459,230,uiTeal,#FFFFFF);
  uiButton("Restart",346,459,130,#EDF1EB,uiInk);
  uiButton("Stop",492,459,228,#F9E8E1,#A13E31);
  uiText("Manual control",100,542,16,uiInk);
  uiText("Runs until you press Stop",100,562,12,uiMuted);
  uiButton("Inflate pads",310,521,195,manualInflate?uiTeal:#E4EFE8,manualInflate?#FFFFFF:uiTeal);
  uiButton("Deflate pads",521,521,199,manualDeflate?uiCoral:#F7E9E1,manualDeflate?#FFFFFF:#A14F3E);
  uiPad(237,626,LEFT_PAD_ID,"LEFT FOOT",#65AC9A);
  uiPad(582,626,RIGHT_PAD_ID,"RIGHT FOOT",#D89B82);
  uiText("Make it yours",834,204,23,uiInk);
  uiText(uiRunning()?"Pause or stop any time. Stop to edit timing.":"Adjust with the sliders or the + / - buttons.",834,230,13,uiMuted);
  for(int i=0;i<6;i++)uiSlider(i);
  uiText("Strength is pump command, not air flow.",834,730,13,uiMuted);
  String[] steps={"01  Inflate","02  Focus","03  Deflate","04  Break"};
  for(int i=0;i<4;i++){
    float x=36+i*309;fill(p==i+1?#DFEBE3:#EAEDE6);rect(x,777,290,35,11);uiCenter(steps[i],x+145,800,14,p==i+1?uiTeal:uiMuted);
  }
  uiText(uiNotice,36,840,13,uiMuted);
  uiText("SPACE  start / pause     S  stop     R  restart",909,840,12,uiMuted);
  if(args!=null && args.length>0 && args[0].equals("--capture") && frameCount==4){saveFrame("preview.png");exit();}
}
void uiPad(float x,float y,int id,String label,int col){
  int p=uiPhase();float t=constrain((float)uiElapsed()/uiDuration(),0,1);
  float lift=p==1?t:p==2?1:p==3?1-t:0;
  if(uiRestartDeflating)lift=uiRestartLift*(1-t);
  // Preserve the visual position when paused; no synthetic pressure readings.
  fill(#E7EBE5);ellipse(x,y+38,238,40);
  fill(lerpColor(col,uiInk,.18));rect(x-103,y-16-lift*30,206,58+lift*30,35);
  fill(col);rect(x-103,y-25-lift*30,206,59,32);
  noFill();stroke(lerpColor(col,#FFFFFF,.45));strokeWeight(2);rect(x-88,y-14-lift*30,176,37,23);noStroke();
  uiCenter(label,x,y+76,12,uiMuted);
  String key=id+"/pressure";Object[] data=sensorInputs.get(key);Long seen=uiSeen.get(key);
  boolean fresh=seen!=null && System.currentTimeMillis()-seen<2000;
  String reading="Waiting for sensor";
  if(data!=null && data.length>0 && data[0] instanceof Number)reading=nf(((Number)data[0]).floatValue(),0,1)+" raw"+(fresh?"":"  / stale");
  uiCenter(reading,x,y+101,17,fresh?uiInk:uiMuted);
}
void uiSlider(int i){
  float y=267+i*73;boolean locked=i<4 && uiRunning();
  uiText(uiLabels[i],834,y,15,locked?uiMuted:uiInk);
  uiText(str(round(uiValue(i)))+" "+uiUnits[i],1124,y,16,uiTeal);
  float x=873,w=289, yy=y+25;
  stroke(uiLine);strokeWeight(6);line(x,yy,x+w,yy);
  float v=map(uiValue(i),uiMin[i],uiMax[i],0,w);
  stroke(locked?#BECBC4:uiTeal);line(x,yy,x+v,yy);noStroke();fill(locked?#BECBC4:uiTeal);ellipse(x+v,yy,16,16);
  if(uiFocus==i){noFill();stroke(uiInk);strokeWeight(1);ellipse(x+v,yy,24,24);noStroke();}
  uiCenter("-",847,yy+6,22,uiMuted);uiCenter("+",1190,yy+6,22,uiMuted);
}
void uiChange(int i,float value){if(i<4 && uiRunning()){uiNotice="Stop the session to change its timing.";return;}cp5.getController(uiNames[i]).setValue(constrain(round(value),uiMin[i],uiMax[i]));}
void uiStop(){uiRestartDeflating=false;uiPaused=false;selection=SelectedInteraction.StopAll;interactionstarted=false;interaction_part=0;stopping_Units();uiNotice="Stopped. Pumps are off; pads are not actively deflating.";}
void uiManual(boolean inflate){
  uiRestartDeflating=false;
  uiPaused=false;interactionstarted=false;interaction_part=0;
  selection=inflate?SelectedInteraction.InflateAll:SelectedInteraction.DeflateAll;
  if(inflate)inflating_Units();else deflating_Units();
  uiNotice="Manual control uses the strength sliders. Timer reset; press Stop to stop the pumps.";
}
void uiStart(){uiRestartDeflating=false;uiPaused=false;interaction_part=0;phase=0;interactionstarted=false;selection=SelectedInteraction.Pomodoro;stopping_Units();uiNotice="10 seconds to settle in, then inflate / focus / deflate / break.";}
void uiRestart(){
  // Repeated clicks must not bypass or extend the pending deflation.
  if(uiRestartDeflating)return;
  int p=uiPhase();
  if(uiRunning() && (p==1 || p==2)){
    uiRestartLift=p==1?constrain((float)uiElapsed()/uiDuration(),0,1):1;
    uiRestartDuration=(long)(uiValue(3)*1000);
    uiRestartDeflating=true;uiPaused=false;
    interactionstarttime=System.currentTimeMillis();interactionstarted=true;
    deflating_Units();
    uiNotice="Deflating before a fresh Pomodoro. Pause or Stop any time.";
  }else uiStart();
}
void uiUpdateRestart(){
  if(!uiRestartDeflating)return;
  if(uiPaused){stopping_Units();return;}
  if(uiElapsed()>=uiRestartDuration){uiStart();return;}
  deflating_Units();
}
void uiToggle(){
  if(!uiRunning()){uiStart();return;}
  if(!uiPaused){uiPausedAt=System.currentTimeMillis();uiPaused=true;stopping_Units();uiNotice="Paused. Pumps are off. Resume when you are ready.";}
  else{interactionstarttime+=System.currentTimeMillis()-uiPausedAt;uiPaused=false;uiNotice="Session resumed.";}
}
void mousePressed(){
  if(uiHit(100,459,230,46)){uiToggle();return;}
  if(uiHit(346,459,130,46)){uiRestart();return;}
  if(uiHit(492,459,228,46)){uiStop();return;}
  if(uiHit(310,521,195,46)){uiManual(true);return;}
  if(uiHit(521,521,199,46)){uiManual(false);return;}
  for(int i=0;i<6;i++){float y=292+i*73;if(uiHit(831,y-18,375,36)){uiFocus=i;if(mouseX<866)uiChange(i,uiValue(i)-1);else if(mouseX>1174)uiChange(i,uiValue(i)+1);else uiChange(i,map(mouseX,873,1162,uiMin[i],uiMax[i]));return;}}
}
void mouseDragged(){if(uiFocus>=0 && uiHit(865,274+uiFocus*73,310,36))uiChange(uiFocus,map(mouseX,873,1162,uiMin[uiFocus],uiMax[uiFocus]));}
void keyPressed(){
  if(key==ESC){key=0;uiStop();}
  else if(key==' ')uiToggle();else if(key=='s'||key=='S')uiStop();else if(key=='r'||key=='R')uiRestart();
  else if(key==TAB){uiFocus=(uiFocus+1)%6;key=0;}
  else if(key==CODED && uiFocus>=0){if(keyCode==LEFT||keyCode==DOWN)uiChange(uiFocus,uiValue(uiFocus)-1);if(keyCode==RIGHT||keyCode==UP)uiChange(uiFocus,uiValue(uiFocus)+1);}
}
public void exit(){if(oscP5!=null)stopping_Units();super.exit();}

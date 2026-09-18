// Original layout coordinates are 1280 x 900; render and hit testing share this transform.
float uiScale(){return min(width/1280.0,height/900.0);}
float uiOffsetX(){return (width-1280*uiScale())/2;}
float uiOffsetY(){return (height-900*uiScale())/2;}
float uiMouseX(){return (mouseX-uiOffsetX())/uiScale();}
float uiMouseY(){return (mouseY-uiOffsetY())/uiScale();}
void setupAdaptiveWindow(){
  // AWT reports usable desktop space in logical pixels, respecting OS display scaling.
  java.awt.Rectangle area=java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds();
  float fit=min(0.8,min(max(1,area.width-80)/1280.0,max(1,area.height-100)/900.0));
  int windowW=max(1,round(1280*fit)),windowH=max(1,round(900*fit));
  surface.setSize(windowW,windowH);
  surface.setResizable(true);
  surface.setLocation(area.x+(area.width-windowW)/2,area.y+30);
}

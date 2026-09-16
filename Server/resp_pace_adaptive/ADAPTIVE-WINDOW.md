# Screen-fitting version

Open **resp_pace_adaptive.pde** in Processing Java mode. Keep all sketch tabs together.

The initial window is at most **1024 x 720** and shrinks further to fit the usable desktop reported by the operating system, including display scaling. Space is reserved for window borders and desktop controls.

Drag the window edges to resize it. The entire interface scales proportionally and stays centered; buttons, sliders and dragging use the same coordinate conversion. Wide or tall windows may have blank margins. Very small windows make text smaller.

This copies the latest timed-deflation restart version: device 1 pressure, reflective interface, manual controls, and Restart performing one deflation using the current duration and strength before the session. Existing versions are unchanged. No change to hardware communication.

Window sizing and scaling are in AdaptiveWindow.pde. Defaults and ranges remain in BreathSession.java.

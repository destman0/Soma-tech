# Sole: participant interface

Open **pomodoro_device3.pde** in Processing (Java mode) and Run. Keep SoleUI.pde in the same folder. Uses the existing ControlP5, oscP5, Sound and SignalFilter libraries. The original source is preserved in original-pomodoro.pde.txt.

## Controls

- Set focus/break minutes, inflation/deflation seconds, and pump strengths with sliders or +/- buttons. Tab selects a setting; arrow keys adjust it.
- Start: 10 seconds to settle in, then inflate, focus, deflate, break. One session, matching the original sketch.
- Pause/Resume: freezes the countdown and sends zero while paused.
- Stop: sends zero and resets the session. This does not empty the pads.
- Restart: sends zero and begins again with the preparation period. It does not empty the pads first.
- Space starts/pauses/resumes; S or Escape stops; R restarts.
- Manual **Inflate pads** / **Deflate pads** buttons run continuously until Stop, using their respective strength sliders. Selecting either resets the Pomodoro, including a paused session. Start Pomodoro or Restart leaves manual mode and begins a fresh session. The active manual direction is highlighted; the countdown is replaced with a Manual indicator. The pads remain schematic in manual mode; use the sensor readings to observe pressure.
- Timing locks during a session, including pauses. Strength remains adjustable and applies to the next command.

## Existing wireless connection

This sketch is the laptop server: run it instead of the old server, since both listen on port 32000. Existing device IPs, OSC bundles, broadcast destinations and /actuator/inflate commands are retained. Commands still go to **all configured actuators**, including devices 3-5 in the original configuration. Verify DeviceIPs for your setup.

Both visual readouts use the same pressure reading from device 3 (192.168.0.13), because both pillows connect to that device; change LEFT_PAD_ID and RIGHT_PAD_ID in SoleUI.pde if needed. Readings are raw sensor units. After two seconds without a reading, the last value is labelled stale. Pad animation represents the phase timing, not measured volume, height or pressure. Strength is a 0-100% pump command, not calibrated air flow.

The interface retains the original open-loop hardware control; the stale label does not stop actuation and no new pressure limits are imposed. Physical operation and comfort parameters need verification on your actual setup. A zero UDP command is not a guaranteed physical emergency stop.

## Files and verification

SoleUI.pde contains the new visual layer and interaction handlers. pomodoro_device3.pde retains the original server and timing logic, with hidden legacy widgets, pause handling, pressure timestamps and a corrected end-of-session boundary. The main filename now matches the sketch folder as required by Processing.

preview.png is a capture of the actual Processing window. The --capture argument renders and exits without outgoing broadcast commands. Physical pillows were not connected during verification.

Verified with Processing 4.5.6 preprocessing and Java compilation using explicit installed library paths (the local command-line Processing installation did not discover its core library automatically). SoleUITest.java checks exact defaults, preparation, pause/resume, locked timing, live strength updates, all four phases, completion, restart and stop.

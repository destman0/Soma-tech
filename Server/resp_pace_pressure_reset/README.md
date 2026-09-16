See PRESSURE-RESET.md for this version's Restart behavior.

# Sole / reflective footrest

Open `resp_pace_pressure_reset.pde` in Processing Java mode. Keep `BreathingUI.pde` and `BreathSession.java` alongside it. Requires the existing oscP5, ControlP5, Sound and SignalFilter libraries. Original source is preserved in `original-resp-pace.pde.txt`.

## Participant interface

A reflective interface for an inflatable footrest beneath the table. The circle and pad illustrations show the material rising and softening; they do not instruct the participant to synchronize their breathing. The design takes inspiration from HRV-paced breathing, expressed as movement of the material. There is no hold phase. Default timing is **5.45 seconds inflation + 5.45 seconds deflation**, approximately **5.5 movement cycles/minute**. The app does not measure HRV.

- Start begins a 10-second preparation period, then repeats inflation/deflation for the session duration (15 minutes by default).
- Inflation and deflation durations are independent, adjustable in 0.05-second increments. The cycles/minute display updates automatically.
- Pause freezes the guide and session clock and commands zero. Resume continues the remaining phase.
- Stop commands zero and resets. Restart begins a fresh preparation period. Neither actively empties the pads.
- Timing locks while running or paused; pump strengths remain adjustable.
- Manual Inflate / Deflate resets the session and runs at the selected strength until Stop or another mode is selected.
- Space starts/pauses/resumes; S or Escape stops; R restarts; Tab and arrows adjust settings.

## Change defaults and ranges in one place

At the top of `BreathSession.java`, edit `values`, `minimum`, `maximum` and `step`. Order: session minutes, inflation seconds, deflation seconds, inflation strength %, deflation strength %. These arrays directly control the interface and timing; legacy hidden ControlP5 ranges do not apply. Keep positive durations and defaults within the limits.

## Hardware and readings

The existing server protocol, configured device IPs and broadcast destinations are retained: receive on UDP 32000 and send `/actuator/inflate` on UDP 12000. Positive inflates, negative deflates, zero stops. This application replaces the old laptop server; do not run both on the same receiving port.

Both pressure displays read **device 1**, configured as 192.168.0.11, because the pillows share a device. This is one shared reading, not two independent measurements. Edit `PRESSURE_DEVICE_ID` in BreathingUI.pde to change it. Values are raw sensor units; missing readings are labelled and readings older than two seconds are marked stale. Animation illustrates timing, not measured height or pressure.

Commands retain the original broadcast to all configured actuators, not only device 1. Pump strength is a command percentage, not calibrated flow. The existing open-loop actuation has no new pressure limits or automatic stop on stale telemetry. Physical operation has not been tested with pillows connected.

## Verification

`tests/BreathSessionTest.java` checks timing, repetition, pause, completion and settings without devices. `--capture` saves actual rendered ready/movement screenshots and suppresses outgoing broadcast commands. The original frame-dependent cycle reset has been replaced with elapsed-time cycle calculation to avoid accumulating phase drift.

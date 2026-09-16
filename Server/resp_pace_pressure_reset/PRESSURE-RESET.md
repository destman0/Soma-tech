# Restart: one timed deflation

Open resp_pace_pressure_reset.pde. This version now uses timed deflation, replacing the previous pressure-target approach.

Restart / R cancels the session and deflates device 1 once, using the current **Deflate for** duration and **Deflation strength**. These settings are captured when Restart is pressed. When the interval finishes, a zero command is sent and the normal 10-second preparation period begins, followed by the session.

There is no pressure-target check or dependency on sensor readings. Start session keeps its original behavior. Stop cancels the deflation and session start. Manual controls cancel it and enter manual mode. Pressing Restart again begins a fresh deflation interval.

The folder and internal filenames retain their earlier names. The original resp_pace folder is unchanged. Timing logic was tested without hardware; physical operation remains untested.

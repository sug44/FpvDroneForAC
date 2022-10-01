Setting up:
Requires Content Manager and Custom Shaders Patch. The app detects any controller that Content Manager detects.
Drag the downloaded zip file into content manager, click on the menu icon(3 horizontal lines) at the top right corner, and click install.
To install Custom Shaders Patch go to Content Manager > Settings > Custom Shaders Patch and click "install".
Go to Content Manager > Settings > Assetto Corsa > Apps and check the "Enable Python apps" checkbox and the "FPV Drone" checkbox below.
Go to Fpv Drone settings at Content Manager > Settings > Apps > FPV Drone and set each input axis with the axis on your controller.
You can see your controller axes in Content Manager > Settings > Assetto Corsa > Controls, and on the right will be your controllers.
While you're here check if your throttle range of motion is 0 to 1 and if it is check the "Throttle range of motion is 0 to 1" checkbox in the Fpv Drone settings.
You can tell that your throttle range of motion is 0 to 1 by checking if your throttle axis value doesnt move all the way up or down.
Some axes on your controller might be inverted, if so you can check the "invert *axis*" checkmark in the Fpv Drone settings.
If you use a radio controller, change the "mode" to "Acro"
Default values are for dualshock 4 gamepad.
Input axes for Dualshock 4: Throttle = 2, Pitch = 6, Yaw = 1, Roll = 3, Invert throttle, Invert pitch.
Input axes for Xbox 360: Throttle = 2, Pitch = 5, Yaw = 1, Roll = 4, Invert throttle, Invert pitch.
If you have multiple controllers, you can change the "Input device" in the Fpv Drone settings.

How to use:
When you are in game, you need to enable the app window by moving your mouse to the right of the screen and clicking on "FPV Drone" app
You can enable/disable the drone by clicking the "On/Off" button. Or you can press F7 to get into the drone camera and F1 to switch back.
By switching with F1/F7 you can keep the position of the drone. Pressing Alt+F7 has the same affect as clicking the "On/Off" button.
The drone has no collision. You can adjust simulated ground level in the app with the "Ground level" slider.
You can change any value except Fpv input values and air density in the app.
If you want your own default values, you can set them in the assettocorsa/apps/python/FPV_Drone/config_defaults.ini file.

The app uses Betaflight rates. 
Every setting is pretty much self explanatory except for "Minimal surface area coefficient".
Minimal drone surface area coefficient is the coefficient by which surface area of the drone is multiplied when its propellers are parallel to the airflow.
It means that if the coefficient is 0 the drone behaves like a flat disk and if it's 1 the drone behaves like a sphere.
It is used to calculate air drag. No lift is being simulated
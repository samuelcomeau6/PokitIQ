# PokitIQ
Pokit meter app for Garmin watch connect IQ

- Step 1: Side load the app https://github.com/samuelcomeau6/PokitIQ/blob/main/Pokit/bin/PokitIQ.prg
(it may or may not work for you right away) https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/#yourfirstconnectiqapp:~:text=complete%20the%20import-,Side%20Loading%20an%20App,-The%20Monkey%20C
- Step 2: Start the app and it shows a measurement mode and a status, skip ahead to step 5
- Step 3: You are unlucky. Download VS code and the Garmin SDK https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/
- Step 4: Following the instructions on Garmin's website build and sideload the app
- Step 5: Pokit does not broadcast the name of the device for some reason so for now just hold the watch very close to PokitPro and wait for it to connect. Pushing the button on the device to wake it up may be required. If the pokit is already connected to a phone it will not connect to the watch, close the Pokit app. If it does connect, you can cycle through the available measurement modes by pressing the next menu button (swipe or down button)
- Step 6: If you can't connect, you are unlucky. Perform steps 3,4 if not already done and modify the RSSI(signal strength) requirement to be lower (BleDevice.mc line 230) and build the app. Side load and test. A value of rssi>-75 should add more sensitivity without picking up too much garbage. I would avoid rssi>-90 or lower since you can connect to things in other rooms. Note that this value is only to determine which device is the Pokit and does not determine the range or sensitivity for transmission.

Good luck. Have fun. The code is garbage, I threw it together fast.

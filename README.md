EtherShield RESTduino
=====================

** IMPORTANT NOTE **

This version of RESTduino is for ENC28J60 based ethernet shields only, not the Official Arduino Ethernet Shield, these use the wizznet chips, it is very heavily based on the original RESTduino by Jason Gullickson, full details at: http://jasongullickson.posterous.com/restduino-arduino-hacking-for-the-rest-of-us. Full thanks and credit go to Jason for the original code and ideas. I have taken his work and massaged it into an application that works with the ENC28J60 based ethernet shields.

I've also updated the demo to use 3 sliders to change the colours on a RGB LED.

This should also be compatible with the Nanode boards described at http://nanode.eu 

RESTduino is a simple sketch to provide a REST-like interface to the Arduino via the Ethernet Shield.  The idea is to allow developers familiar with interacting with REST services with a way to control physical devices using the Arduino (without having to write any Arduino code).


Of course some flexibility is traded for this convenience; only basic operations are currently supported:

* Digital pin I/O (HIGH, LOW and PWM)
* Analog pin input

Later versions of the sketch may provide additional functionality (servo control, etc.) however if you need more than just basic pin control you're probably better off learning the basics of programming the Arduino and offloading some of your processing to the board itself.

Getting Started
---------------

First you'll need an Arduino, a ENC28J60-based Ethernet shield and the Arduino development tools; here's some links to get you started:

* Arduino Uno (adafruit): http://www.adafruit.com/index.php?main_page=product_info&cPath=17&products_id=50
* EtherShield (nuelectronics): http://www.nuelectronics.com/estore/index.php?main_page=product_info&products_id=4
* Arduino development tools: http://www.arduino.cc/en/Main/Software

Or you could use the Nanode, http://nanode.eu which combines both the Arduino functionality and the EtherShield on one board. If you use a Nanode then you will additionally need the FTDI programming lead.

For testing you'll want some hardware to connect to the Arduino, the demo uses a common cathode RGB LED connected to pins 3, 5 and 6. Connecting single LEDs between the pins and ground will also work.

Load up the sketch (EtherShield_RESTduino.pde) and modify the following lines to match your setup:

static uint8_t mymac[6] = { 0x54,0x55,0x58,0x10,0x20,0x35};

This line sets the MAC address of your ethernet board;

static uint8_t myip[4] = { 192,168,1,177};

The next line you'll need to modify is this one which sets the IP address; set it to something valid for your network.

Now you should be ready to upload the code to your Arduino.  Once the upload is complete you can open the "Serial Monitor" to get some debug info from the sketch.

Now you're ready to start talking REST to your Arduino/Nanode!

To turn on the LED attached to pin #3 (currently case sensitive!):

http://192.168.1.177/3/HIGH

This will set the pin to the HIGH state and the LED should light.  Next try this:

http://192.168.1.177/3/100

This will use PWM to illuminate the LED at around 50% brightness (valid PWM values are 0-255).

Now if we connect a switch to pin #2 we can read the digital (on/off) value using this URL:

http://192.168.1.177/2

This returns a tiny chunk of JSON containing the pin requested and its current value:

{"2":"LOW"}

Analog reads are similar; reading the value of Analog pin #1 looks like this:

http://192.168.1.177/a1

...and return the same JSON formatted result as above:

{"a1":"432"}

Javascript/jQuery Demo
----------------------
A simple example of how to interface with RESTduino via jQuery is included as DemoApp2.html.  

This page displays 3 slider controls (via jQuery UI) which when adjusted will set the PWM value of Pin #3, #5 and #6 to the value selected by the slider. These then change the appropriate colour on the RGB LED.

If you look at line 32 you can see where the REST URL (you'll need to adjust this for the IP address of your device) is constructed based on the selected value of the slider and on lines 53, 63 and 73 an AJAX request is executed passing the URL constructed above to the Arduino.

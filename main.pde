/*
 * Accelerometer data logger 
 * with LCD and MicroSD
 * Curtis F.
 *
 */
#include <EEPROM.h>
// SD Card includes 
#include "Fat16.h"
#include "SdCard.h"
SdCard card;
Fat16 file;
// end
#include <avr/io.h>
#include <avr/wdt.h>
#define Reset_AVR() wdt_enable(WDTO_30MS); while(1) {}

int buttonPin = 5; //button Pin
int GS1Pin = 2; //Gravity Select Pin 1
int GS2Pin = 3; //Gravity Select Pin 2
int AccSleepPin = 4; // Accelorometer sleep pin for enable/disable
int X, Y, Z; // Raw ADC values for XYZ
int sendtoserial = 0;
int samplestaken = 0;
int isLoggingData = 1;
int val = 0; 

void setup()
{
    pinMode(buttonPin, INPUT);
    pinMode(GS1Pin, OUTPUT);
    pinMode(GS2Pin, OUTPUT);
    pinMode(AccSleepPin, OUTPUT);
    Serial.begin(19200);
    Serial.println("Accelerometer data logger"); 
    analogReference(EXTERNAL); // ser ADC voltage ref to 3.3 external
    digitalWrite(GS1Pin, LOW); // set inital 1.5G sensitiviy
    digitalWrite(GS2Pin, LOW);
    digitalWrite(AccSleepPin, HIGH); // turn on Accelorometer
    sendtoserial = EEPROM.read(1);
    //SD card Int
        intcardfunction();
    // End 
    if (sendtoserial == 0) Serial.println("MicroSD Log"); 
}

void loop()
{
  while (1) {
    X = analogRead(2); // store values
    Y = analogRead(1);
    Z = analogRead(0);
  
  if (sendtoserial == 1) { 
    Serial.print(40, BYTE); // print "(" charcater 
    Serial.print(X); // send raw values out serial port
    Serial.print(Y);
    Serial.print(Z);
    Serial.println(41, BYTE); // print ")" charcater 
    delay(5);   
    
    val = digitalRead(buttonPin);  // read input value
    if (val == HIGH) {            // check if the input is HIGH
    while (digitalRead(buttonPin) == HIGH){}
    Serial.println("Reset_AVR();");
    EEPROM.write(1, 0);
    Reset_AVR(); //reset to load to default MicroSD logging mode
    } 
  }
  if (sendtoserial == 0) { 
    logtosdcard();
    val = digitalRead(buttonPin);  // read input value
    if (val == HIGH) {            // check if the input is HIGH
    EEPROM.write(1, 1);
    while (digitalRead(buttonPin) == HIGH){}
    Serial.println("Reset_AVR();");
    Reset_AVR(); //reset to load to default MicroSD logging mode
    } 
    
  }
    serbPollSerialPort(); // listen on serial port for commands
  }
    delay(1);
}

void intcardfunction()
{
  if (!card.init()) error("card.init"); // initialize 
  if (!Fat16::init(card, 1)) {
    // try super floppy
    if (!Fat16::init(card, 0)) error("Fat16::init");
  }
}

void logtosdcard()
{
  char name[] = "LOG-00.TXT";
  for (uint8_t i = 0; i < 254; i++) {
    name[4] = i/10 + '0';
    name[5] = i%10 + '0';
    if (file.create(name)) break;
  }
  if (!file.isOpen()) error ("file.create");
    file.print(millis());
    file.print(":");
    file.print(40, BYTE);// print "(" charcater 
    file.print(X, DEC); 
    file.print(",");
    file.print(Y, DEC); 
    file.print(",");
    file.print(Z, DEC); 
    file.println(41, BYTE);// print ")" charcater 
    samplestaken++ ;
  if (samplestaken > 15)
  {
    file.sync();
    samplestaken = 0;
  }
}

void serbPollSerialPort()
{
  int dta;                              //variable to hold the serial  byte
  if ( Serial.available() >= 5) {       //if 5 bytes are in the buffer (length pf a full request)
    dta = Serial.read(); 
    if ( dta = 65){                        //Checks for first check byte "A"
      dta = Serial.read();
        if ( dta = 65){                    //Checks for second check byte "A"
          dta = Serial.read();
            if ( dta = 65){                //Checks for third check byte "A"
               int command = Serial.read();        //Fourth byte is the command
               int param1 = Serial.read();         //Fifth byte is param1
               interpretCommand(command, param1);  //sends the parsed request to it's handler
            }
        }
      }
    }
}

void interpretCommand(int command, int param1)
{
if       (command == 83){             // If command = "S" then
  switch (param1) {
    case 49: // case command parameter = "1"
      digitalWrite(AccSleepPin, LOW); // turn off Accelorometer
      delay(100); 
      digitalWrite(GS1Pin, LOW); // change to 1.5G sensitivity
      digitalWrite(GS2Pin, LOW);   
      delay(400);
      Serial.flush(); // clear buffer 
      digitalWrite(AccSleepPin, HIGH); // turn on Accelorometer
      break;
    case 50: // case command parameter = "2"
      digitalWrite(AccSleepPin, LOW);
      delay(100);
      digitalWrite(GS1Pin, LOW);// change to 2G sensitivity
      digitalWrite(GS2Pin, HIGH);  
      delay(400);
      Serial.flush(); // clear buffer 
      digitalWrite(AccSleepPin, HIGH); // turn on Accelorometer
      break;
    case 51: // case command parameter = "3"
      digitalWrite(AccSleepPin, LOW);
      delay(100);
      digitalWrite(GS1Pin, HIGH);// change to 4G sensitivity
      digitalWrite(GS2Pin, LOW); 
      delay(400);
      Serial.flush(); // clear buffer 
      digitalWrite(AccSleepPin, HIGH); // turn on Accelorometer
      break;
    case 52: // case command parameter = "4"
      digitalWrite(AccSleepPin, LOW);
      delay(100);
      digitalWrite(GS1Pin, HIGH);// change to 6G sensitivity
      digitalWrite(GS2Pin, HIGH);
      delay(400);
      Serial.flush(); // clear buffer 
      digitalWrite(AccSleepPin, HIGH); // turn on Accelorometer
      break;
     }  
}
if       (command == 69){ // if command = "E" then
  switch (param1) { 
    case 69: // case command parameter = "E"
      digitalWrite(AccSleepPin, HIGH);
      Serial.flush();
      break;
    case 68: // case command parameter = "D"
      digitalWrite(AccSleepPin, LOW);
      Serial.flush();
      break;
    }
  }
}

void error(char *str)
{
  sendtoserial = 1;
  Serial.print("error: ");
  Serial.println(str);
}

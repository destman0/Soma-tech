//based on the following examples
//https://www.instructables.com/id/Arduino-Motor-Shield-Tutorial/
//https://github.com/oujifei/pneuduino/blob/master/examples/PressureRegulator2/PressureRegulator2.ino

int solenoidPin1 = 7;
int solenoidPin2 = 6;
float voltage;
float presskpa;
int sensorValue;
float volt;


// to prevent rapidly switching valves, we only run in intervals
unsigned long time_interval = 100L;
unsigned long last_run;

void setup()
{
  //Initializing solenoid pins
  pinMode(solenoidPin1, OUTPUT);
  pinMode(solenoidPin2, OUTPUT);

  //Initializing motors
  pinMode(12, OUTPUT);
  //pinMode(9, OUTPUT);

  pinMode(13, OUTPUT);
  //pinMode(8, OUTPUT);

  //pinMode(A0, INPUT);



  Serial.begin(9600);//Sets that pin as an output
}

void loop()
{
  digitalWrite(12, HIGH); //Establishes forward direction for motor terminal A
  digitalWrite(13, HIGH); //Establishes forward direction for motor terminal B

  inflate();
  


  //delay(1000);                          //Wait 1 Second
  //pressure();
  
  
  //hold();

  //delay(1000);                          //Wait 1 Second
  //pressure();
  


  //deflate();


  //delay(1000);                          //Wait 1 Second
  //pressure();
  
}


void pressure ()
{
   sensorValue = analogRead(A2);
   voltage = sensorValue * (5 / 1024.0);
   presskpa = 20 + voltage * 1000 / 12.1;
   Serial.print(presskpa);
   Serial.print("kPa @");
   Serial.print(voltage);
   Serial.println("V"); 
  
  }





void inflate ()

{
  digitalWrite(solenoidPin1, HIGH);      
  digitalWrite(solenoidPin2, LOW);
  
  
  analogWrite(3, 255);   //Terminal A motor - full speed 
  analogWrite(11, LOW);   //Termanl B motor - full stop
  Serial.println("Inflate?");
  
  
  }  


void hold ()

{
  digitalWrite(3, LOW);   //Terminal A motor - full stop
  analogWrite(11, LOW);   //Termanl B motor - full stop
 
  
  digitalWrite(solenoidPin1, HIGH);      
  digitalWrite(solenoidPin2, HIGH);
  Serial.println("Hold?");  
   
      }

void deflate ()
{
  
  digitalWrite(solenoidPin1, LOW);       
  digitalWrite(solenoidPin2, LOW);

  
  analogWrite(3, LOW);   //Terminal A motor - full stop 
  analogWrite(11, 255);   //Terminal A motor - full speed 

  
  Serial.println("Deflate?"); 
  
      
  }
  

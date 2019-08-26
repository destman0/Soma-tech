int compressor = 6;
int valve = 11;

void setup() {
  // put your setup code here, to run once:
  pinMode(compressor, OUTPUT);
  pinMode(valve, OUTPUT);
  pinMode(A5, INPUT);
  pinMode(10, OUTPUT);
  Serial.begin(9600);

}

void loop() {
  int readingA5 = analogRead(A5);
  int mult = map(readingA5, 1024, 0, 10, 100);
  Serial.print(readingA5);
  Serial.print("\t"); 
  
  
  // put your main code here, to run repeatedly:
  digitalWrite(compressor, HIGH); 
  digitalWrite(valve, LOW);
  //delay(mult*400);
  for(int i=0; i<mult*40; i++)
  {
      readingA5 = analogRead(A5);
      int newmult = map(readingA5, 1024, 0, 10, 100);
      if (newmult*40<i)
      break; 
  
    
   int intensity = map(i,0,mult*40,0,255);
   analogWrite(10,intensity);
   delay(1); 
    }    
   /*  
  digitalWrite(compressor, LOW); 
  digitalWrite(valve, LOW);

  readingA5 = analogRead(A5);
  mult = map(readingA5, 1024, 0, 10, 100);


  Serial.print(mult);
  Serial.print("\t"); 
  
  for(int i=0; i<mult*40; i++)
  {
      readingA5 = analogRead(A5);
      int newmult = map(readingA5, 1024, 0, 10, 100);
      if (newmult*40<i)
      break; 

   delay(1); 
    }  
   */                  
  digitalWrite(compressor, LOW);
  digitalWrite(valve, HIGH); 

  readingA5 = analogRead(A5);
  mult = map(readingA5, 1024, 0, 10, 100);

  //Serial.print(mult);
  //Serial.print("\t"); 
  
  for(int i=0; i<mult*150; i++)
  {
      readingA5 = analogRead(A5);
      int newmult = map(readingA5, 1024, 0, 10, 100);
      if (newmult*150<i)
      break; 
      
 int intensity = map(i,0,mult*150,255,0);
 analogWrite(10,intensity);

   delay(1); 
    }  



  //digitalWrite(compressor, HIGH); 
  //digitalWrite(valve, HIGH);
  //delay(3000);                       
  //digitalWrite(compressor, LOW);
  //digitalWrite(valve, HIGH); 
  //delay(3000);
}

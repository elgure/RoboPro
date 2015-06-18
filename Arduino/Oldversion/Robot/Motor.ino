#ifndef __MOTOR__
#define MOTOR_OFF 0
#define MOTOR_ON 1
#endif

static const int STB = 2;
static const int M1_LEFT = 3;
static const int M1_RIGHT = 5;
static const int M2_LEFT = 6;
static const int M2_RIGHT = 9;
static const int M3_LEFT = 10;
static const int M3_RIGHT = 11;
int Motor_Status = 0;

void defaultMotorSetup(void)
{
  digitalWrite(M1_LEFT, HIGH);
  digitalWrite(M1_RIGHT, HIGH);
  digitalWrite(M2_LEFT, HIGH);
  digitalWrite(M2_RIGHT, HIGH);
  digitalWrite(M3_LEFT, HIGH);
  digitalWrite(M3_RIGHT, HIGH);
}

void Motor_Setup(void)
{
  /* Motor Setup */
  pinMode(STB, OUTPUT);
  pinMode(M1_LEFT, OUTPUT);   //M1 sw l
  pinMode(M1_RIGHT, OUTPUT);  //M1 sw r
  pinMode(M2_LEFT, OUTPUT);   //M2 sw l
  pinMode(M2_RIGHT, OUTPUT);  //M2 sw r
  pinMode(M3_LEFT, OUTPUT);   //M3 sw l
  pinMode(M3_RIGHT, OUTPUT);  //M3 sw r

  defaultMotorSetup();        //Avoid motors shortage.
  digitalWrite(STB, LOW);
  Motor_Status = 0;
}

void changeDirection(String name, int pwm, int leftPin, int rightPin)
{
  Serial.print(name);
  Serial.print(pwm);
  Serial.print(" ");
  if (pwm < 0)
  {
    digitalWrite(leftPin,HIGH);
    analogWrite(rightPin, (pwm < 0) ? -pwm : pwm);
  }
  else if (pwm > 0) 
  {
    analogWrite(leftPin, (pwm < 0) ? -pwm : pwm);
    digitalWrite(rightPin,HIGH);
  }
  else
  {
    digitalWrite(leftPin, HIGH);    
    digitalWrite(rightPin, HIGH);
  }
}

void Standby()
{
  if (Motor_Status != MOTOR_ON)
  {
    Motor_Status = MOTOR_ON;
    digitalWrite(STB, HIGH);
    Serial.println("[Motor]: ON");
  }
  else
  {
    Motor_Status = MOTOR_OFF;
    Serial.println("[Motor]: OFF");
    digitalWrite(STB, LOW);
  }
}

void SetMotor()
{
  const int NUMBER_OF_FIELDS = 3;   // how many comma separated fields we expect
  int fieldIndex = 0;               // the current field being received
  int values[NUMBER_OF_FIELDS];     // array holding values for all the fields
  String buffer = "";

  while (true)
  {
    char ch = Serial.read();
    if ((ch >= '0' && ch <= '9') || ch == '-')
    {
      buffer += ch;
    }
    else if (ch == ',')             // comma is our separator, so move on to the next field
    {
      values[fieldIndex] = buffer.toInt();
      buffer = "";
      fieldIndex++;                 // increment field index  
      if (fieldIndex >= NUMBER_OF_FIELDS)
      {
        /*-----Motor 1-----*/
        changeDirection("[PWM1]: ", values[0], M1_LEFT, M1_RIGHT);
        /*-----Motor 2-----*/
        changeDirection("[PWM2]: ", values[1], M2_LEFT, M2_RIGHT);
        /*-----Motor 3-----*/
        changeDirection("[PWM3]: ", values[2], M3_LEFT, M3_RIGHT);

        Serial.println();
        return;
      }
    }
  }
}

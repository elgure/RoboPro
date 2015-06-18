#include <Wire.h>

#define OUTPUT__BAUD_RATE 57600

static const int MODE_NUMBERS = 2;

void Serial_Setup(void)
{
  Serial.begin(OUTPUT__BAUD_RATE);  // start serial for output
}

typedef struct ModeMethods
{
  char mode;
  void (*method)();
} ModeMethods;

ModeMethods modes[MODE_NUMBERS] = { 
                        {'r', &SetMotor},
                        {'s', &Standby}
                      };

void Serial_Read(void)
{
  if (Serial.available())
  {
    char ch = Serial.read();
    for (int i = 0; i < MODE_NUMBERS; i++)
    {
      ModeMethods currentMode = modes[i];
      if (currentMode.mode == ch)
        currentMode.method();
    }
  }
}

void setup()
{
  Serial_Setup();
  I2C_Setup();
  Motor_Setup();
}

void loop()
{
  Serial_Read();
  Read_Magn();
}


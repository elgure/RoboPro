#ifndef __MAGNETOMETER__
#define MAGNETOMADDR 0x1e
#endif

//#define OUTPUT__BAUD_RATE 57600
#define TO_DEG(x) (x * 57.2957795131)  // *180/pi   

// Arduino backward compatibility macros
#if ARDUINO >= 100
  #define WIRE_SEND(b) Wire.write((byte) b) 
  #define WIRE_RECEIVE() Wire.read() 
#else
  #define WIRE_SEND(b) Wire.send(b)
  #define WIRE_RECEIVE() Wire.receive() 
#endif

float magnetom[2];

void I2C_Setup(void)
{
   /* I2C Setup */
  Wire.begin();                     // join i2c bus (address optional for master)
  Magn_Init();                      // init digital compass
  delay(20);                        // add time to get data from the device
}

void Magn_Init()
{
  Wire.beginTransmission(MAGNETOMADDR);
  WIRE_SEND(0x02); 
  WIRE_SEND(0x00);  // Set continuous mode (default 10Hz)
  Wire.endTransmission();
  delay(5);

  Wire.beginTransmission(MAGNETOMADDR);
  WIRE_SEND(0x00);
  WIRE_SEND(0b00011000);  // Set 50Hz
  Wire.endTransmission();
  delay(5);
}

void Read_Magn()
{
  int i = 0;
  byte buff[6];
 
  Wire.beginTransmission(MAGNETOMADDR); 
  WIRE_SEND(0x03);  // Send address to read from
  Wire.endTransmission();
  
  Wire.beginTransmission(MAGNETOMADDR); 
  Wire.requestFrom(MAGNETOMADDR, 6);  // Request 6 bytes
  
  while(Wire.available())  // ((Wire.available())&&(i<6))
  { 
    buff[i] = WIRE_RECEIVE();  // Read one byte
    i++;
  }
  Wire.endTransmission();
  
  if (i == 6)  // All bytes received?
  {
    // MSB byte first, then LSB; Y and Z reversed: X, Z, Y
    magnetom[0] = (((int) buff[0]) << 8) | buff[1];         // X axis (internal sensor x axis)
    magnetom[1] = -1 * ((((int) buff[4]) << 8) | buff[5]);  // Y axis (internal sensor -y axis)
    magnetom[2] = -1 * ((((int) buff[2]) << 8) | buff[3]);  // Z axis (internal sensor -z axis)
  }
  else
  {
    Serial.println("!ERR: reading magnetometer");
  }
  Serial.println(TO_DEG(atan2(-magnetom[0], magnetom[1]))); // Print the Yaw angle
}

//   void setup()
// {
//   Serial.begin(OUTPUT__BAUD_RATE);  // start serial for output
//   Wire.begin();                     // join i2c bus (address optional for master)
//   Magn_Init();                      // init digital compass

//   delay(20);                        // add time to get data from the device
// }
   
// void loop()
// {
//   Read_Magn();
// }

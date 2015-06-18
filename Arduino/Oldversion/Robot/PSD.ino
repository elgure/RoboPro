static const int PSD_1 = 0;
static const int PSD_2 = 1;

void PSD_Read(void)
{
	Serial.print("[PSD1]: ");
	Serial.print(analogRead(PSD_1));
	Serial.print(" ");
	Serial.print("[PSD2]: ");
	Serial.print(" ");
}

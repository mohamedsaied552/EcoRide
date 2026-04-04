#include <WiFi.h>
#include <HTTPClient.h>

#define RELAY_PIN 5

const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASS";

const String backendStatusUrl = "http://your-backend.com/scooter_status";

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(backendStatusUrl);
    int httpCode = http.GET();
    if (httpCode > 0) {
      String payload = http.getString();
      Serial.println(payload);

      if (payload.indexOf("unlock") >= 0) {
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("Scooter Unlocked");
      } else {
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("Scooter Locked");
      }
    }
    http.end();
  }
  delay(2000);
}

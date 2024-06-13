// INCLUSÃO DE BIBLIOTECAS
#include <SPI.h>
#include <Ethernet.h>
#include <MySQL_Connection.h>
#include <MySQL_Cursor.h>
#include <DHT.h>

// INCLUSÃO DE SEGREDOS
#include "arduino_secrets.h"

// DEFINIÇÕES
#define DHTPIN 2 // Pino digital conectado ao sensor DHT
#define DHTTYPE DHT11 // Defina DHT11 ou DHT22
#define BOMBA_PIN 9 // Pino digital para controlar a bomba
#define FLUXO_PIN 3 // Pino digital para ler o sensor de fluxo

DHT dht(DHTPIN, DHTTYPE);

// Defina o endereço MAC e IP do Ethernet Shield
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 3, 177);

// DECLARAÇÃO DE VARIÁVEIS PARA MySQL
IPAddress server_addr(52, 67, 231, 97);  // IP do servidor MySQL
char user[] = SECRET_USERDB;              // Nome de usuário do MySQL
char password[] = SECRET_PASSDB;          // Senha do MySQL

char INSERT_SQL[] = "INSERT INTO sql10712925.temperature_data (temperature, humidity) VALUES (%s, %s)";
char query[256];
char temp_str[10];
char hum_str[10];

// INSTANCIANDO OBJETOS
EthernetClient client;
MySQL_Connection conn((Client *)&client);

// DECLARAÇÃO DE VARIÁVEIS PARA CONTROLE DA BOMBA
volatile int contadorPulsos = 0; // Contador de pulsos do sensor de fluxo
float quantidadeDesejada = 1000.0; // Quantidade desejada em ml
float fatorCalibracao = 7.5; // Fator de calibração do sensor (pode variar)
boolean bombaLigada = false;

// DECLARAÇÃO DE FUNÇÕES
void enviaDados(float temperature, float humidity);
void contarPulsos();

void setup() { // ***************** INÍCIO DO SETUP *************************
  Serial.begin(9600);
  
  // Inicializa o DHT
  dht.begin();
  
  // Inicializa o Ethernet
  Ethernet.begin(mac, ip);

  // Conecta no MySQL
  while (!conn.connect(server_addr, 3306, user, password)) {
    Serial.println("Conexão SQL falhou.");
    conn.close();
    delay(1000);
    Serial.println("Conectando SQL novamente.");
  }
  Serial.println("Conectado ao servidor SQL.");
  digitalWrite(LED_BUILTIN, HIGH);

  // Configurações para a bomba e sensor de fluxo
  pinMode(BOMBA_PIN, OUTPUT); // Define o pino da bomba como saída
  pinMode(FLUXO_PIN, INPUT); // Define o pino do sensor de fluxo como entrada
  attachInterrupt(digitalPinToInterrupt(FLUXO_PIN), contarPulsos, RISING); // Interrupção para contar pulsos
}
// ***************** FIM DO SETUP ***************************

// ***************** INÍCIO DO LOOP *************************
void loop() {
  // Leitura da temperatura e umidade do sensor DHT
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Verifica se as leituras são válidas
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Falha na leitura do sensor DHT!");
  } else {
    enviaDados(temperature, humidity);
  }

  // Controle da quantidade de líquido
  if (!bombaLigada) {
    contadorPulsos = 0; // Reseta o contador de pulsos
    digitalWrite(BOMBA_PIN, HIGH); // Liga a bomba
    bombaLigada = true;
  }

  float volumeAtual = (contadorPulsos / fatorCalibracao); // Calcula o volume atual em ml
  Serial.print("Volume Atual: ");
  Serial.print(volumeAtual);
  Serial.println(" ml");

  if (volumeAtual >= quantidadeDesejada) {
    digitalWrite(BOMBA_PIN, LOW); // Desliga a bomba
    Serial.println("Quantidade desejada alcançada!");
    bombaLigada = false;
    delay(600000); // Aguarda 10 minutos antes de reiniciar o processo
  }
}
// ***************** FIM DO LOOP ***************************

void enviaDados(float temperature, float humidity) {
  // Converte os valores de float para string
  dtostrf(temperature, 4, 2, temp_str);
  dtostrf(humidity, 4, 2, hum_str);

  // Constrói a consulta SQL com os valores
  sprintf(query, "INSERT INTO sql10712925.temperature_data (temperature, humidity) VALUES (%s, %s)", temp_str, hum_str);
  
  // Cria a instância da classe de consulta
  MySQL_Cursor *cur_mem = new MySQL_Cursor(&conn);
  
  // Executa a consulta
  if (cur_mem->execute(query)) {
    Serial.println("Informações Enviadas");
  } else {
    Serial.println("Falha ao enviar informações");
  }
  
  // Libera a memória usada pela instância da consulta
  delete cur_mem;
}

void contarPulsos() {
  contadorPulsos++; // Incrementa o contador de pulsos
}

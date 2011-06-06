// EtherShield webserver restduino for ENC28J60
//
// Based on RESTduino http://jasongullickson.posterous.com/restduino-arduino-hacking-for-the-rest-of-us
//
// By Andrew Lindsay June 2011
// http://blog.thiseldo.co.uk

// Use first line to include debug output, second line to remove it
#define DEBUG 1
//#undef DEBUG

#include "EtherShield.h"

// please modify the following three lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static uint8_t mymac[6] = { 0x54,0x55,0x58,0x10,0x20,0x35}; 
static uint8_t myip[4] = { 192,168,1,177};

// listen port for tcp/www (max range 1-254)
#define MYWWWPORT 80   

#define BUFFER_SIZE 800
static uint8_t buf[BUFFER_SIZE+1];
#define STR_BUFFER_SIZE 22
static char strbuf[STR_BUFFER_SIZE+1];

EtherShield es=EtherShield();

uint16_t http200ok(void)
{
  return(es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nPragma: no-cache\r\n\r\n")));
}

uint16_t http404(void)
{
  return(es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 404 OK\r\nContent-Type: text/html\r\n\r\n")));
}

// prepare the webpage by writing the data to the tcp send buffer
uint16_t print_webpage(uint8_t *buf)
{
  uint16_t plen;
  plen=http200ok();
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<html><body>Invalid option selected</body></html>"));

  return(plen);
}


#define CMDBUF 50

int16_t process_request(char *str)
{
  int8_t r=-1;
  int8_t i = 0;
  char clientline[CMDBUF];
  int index = 0;
  int plen = 0;
  
#ifdef DEBUG
//  Serial.println( str );
#endif

  char ch = str[index];
  
  while( ch != ' ' && index < CMDBUF) {
    clientline[index] = ch;
    index++;
    ch = str[index];
  }
  clientline[index] = '\0';

#ifdef DEBUG
  Serial.println( clientline );
#endif

  // convert clientline into a proper
  // string for further processing
  String urlString = String(clientline);

  // extract the operation
  String op = urlString.substring(0,urlString.indexOf(' '));

  // we're only interested in the first part...
  urlString = urlString.substring(urlString.indexOf('/'), urlString.indexOf(' ', urlString.indexOf('/')));

  // put what's left of the URL back in client line
  urlString.toCharArray(clientline, CMDBUF);

  // get the first two parameters
  char *pin = strtok(clientline,"/");
  char *value = strtok(NULL,"/");

  // this is where we actually *do something*!
  char outValue[10] = "MU";
  //outValue = "MU";
//  String jsonOut = String();
  char jsonOut[50];

  if(pin != NULL){
    if(value != NULL){

      // set the pin value
#ifdef DEBUG
      Serial.println("setting pin");
#endif
            
      // select the pin
      int selectedPin = pin[0] -'0';
#ifdef DEBUG
      Serial.println(selectedPin);
#endif
            
      // set the pin for output
      pinMode(selectedPin, OUTPUT);
            
      // determine digital or analog (PWM)
      if(strncmp(value, "HIGH", 4) == 0 || strncmp(value, "LOW", 3) == 0){
              
        // digital
#ifdef DEBUG
        Serial.println("digital");
#endif
              
        if(strncmp(value, "HIGH", 4) == 0){
#ifdef DEBUG
          Serial.println("HIGH");
#endif
          digitalWrite(selectedPin, HIGH);
        }
              
        if(strncmp(value, "LOW", 3) == 0){
#ifdef DEBUG
          Serial.println("LOW");
#endif
          digitalWrite(selectedPin, LOW);
        }
              
      } else {
              
        // analog
#ifdef DEBUG
        Serial.println("analog");
#endif
              
        // get numeric value
        int selectedValue = atoi(value);
#ifdef DEBUG
        Serial.println(selectedValue);
#endif
              
        analogWrite(selectedPin, selectedValue);
              
      }
      // return status
      return( http200ok() );
        
    } else {

      // read the pin value
#ifdef DEBUG
      Serial.println("reading pin");
#endif

      // determine analog or digital
      if(pin[0] == 'a' || pin[0] == 'A'){

        // analog
        int selectedPin = pin[1] - '0';

#ifdef DEBUG
        Serial.println(selectedPin);
        Serial.println("analog");
#endif

        sprintf(outValue,"%d",analogRead(selectedPin));
              
#ifdef DEBUG
        Serial.println(outValue);
#endif

      } else if(pin[0] != NULL) {

        // digital
        int selectedPin = pin[0] - '0';

#ifdef DEBUG
        Serial.println(selectedPin);
        Serial.println("digital");
#endif

        pinMode(selectedPin, INPUT);
              
        int inValue = digitalRead(selectedPin);
              
        if(inValue == 0){
          sprintf(outValue,"%s","LOW");
          //sprintf(outValue,"%d",digitalRead(selectedPin));
        }
              
        if(inValue == 1){
          sprintf(outValue,"%s","HIGH");
        }
              
#ifdef DEBUG
        Serial.println(outValue);
#endif
      }

      // assemble the json output
      sprintf( jsonOut, "{\"%s\":\"%s\"}", pin, outValue );
#ifdef DEBUG
      Serial.println( jsonOut );
#endif
      // return value
      plen=http200ok();
      plen=es.ES_fill_tcp_data(buf,plen,jsonOut);
      return(plen);
    }
  } else {
          
    // error
#ifdef DEBUG
    Serial.println("erroring");
#endif
    plen = http404();
  }
 
  return plen;
}



void setup(){
  // Init SPI
   es.ES_enc28j60SpiInit();
  
  // initialize enc28j60
  es.ES_enc28j60Init(mymac);  //, 8);

  //init the ethernet/ip layer:
  es.ES_init_ip_arp_udp_tcp(mymac,myip,80);

#ifdef DEBUG
  Serial.begin(19200);
  Serial.println("ENC28J60 RESTduino");

  Serial.print( "ENC28J60 version " );
  Serial.println( es.ES_enc28j60Revision(), HEX);
  if( es.ES_enc28j60Revision() <= 0 ) 
    Serial.println( "Failed to access ENC28J60");
#endif

#ifdef DEBUG
  Serial.println("Ready");
#endif

}

void loop(){
  uint16_t plen, dat_p;
  int8_t cmd;

  while(1) {
    // read packet, handle ping and wait for a tcp packet:
   dat_p=es.ES_packetloop_icmp_tcp(buf,es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));

    /* dat_p will be unequal to zero if there is a valid http get */
    if(dat_p==0){
      // no http request
      continue;
    }

    // tcp port 80 begin
    if (strncmp("GET ",(char *)&(buf[dat_p]),4)!=0){
      // head, post and other methods:
      dat_p = print_webpage(buf);
      goto SENDTCP;
    }

    // just one web page in the "root directory" of the web server
    if (strncmp("/ ",(char *)&(buf[dat_p+4]),2)==0){
#ifdef DEBUG
      Serial.println("GET / request");
#endif
      dat_p=print_webpage(buf);
      goto SENDTCP;
    }
    dat_p = process_request((char *)&(buf[dat_p+4]));
    
SENDTCP:

    es.ES_www_server_reply(buf,dat_p); // send web page data
    // tcp port 80 end
  }

}



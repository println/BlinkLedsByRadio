#include "BlinkLedsByRadio.h"

configuration BlinkLedsByRadioAppC {}
implementation {
  components MainC, BlinkLedsByRadioC as App, LedsC;
  components new AMSenderC(RADIO_CHANNEL);
  components new AMReceiverC(RADIO_CHANNEL);
  components new TimerMilliC() as TimerMilliC1;
  components new TimerMilliC() as TimerMilliC2;
  components new TimerMilliC() as TimerMilliC3;
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;  
  App.MilliTimer -> TimerMilliC1;
  App.CheckMilliTimer -> TimerMilliC2;
  App.BlinkMilliTimer -> TimerMilliC3;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}



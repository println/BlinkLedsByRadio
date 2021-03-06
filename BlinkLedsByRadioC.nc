#include "Timer.h"
#include "BlinkLedsByRadio.h"

module BlinkLedsByRadioC @safe() {
	uses {
		interface Leds;
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface Timer<TMilli> as CheckMilliTimer;
		interface Timer<TMilli> as BlinkMilliTimer;
		interface SplitControl as AMControl;
		interface Packet;
		interface Random;
	}
}

implementation {

	void trigger_timers_oneshot_event(uint16_t delay);
	void trigger_blinking_led_event(uint16_t delay);
	uint16_t generate_token(uint16_t current_token);
	bool is_correct_token(AM_MESSAGE_t* message, uint16_t token);

	message_t _packet;
	bool _locked;
	bool _checking;
	bool _initialized;
	bool _checking_running;
	uint16_t _led = LED0;
	uint16_t _elapsed_time = 0;
	uint16_t _message_token = 0;

	uint16_t _bliking_count = 0;


	event void Boot.booted() {		
			call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {		
		if (err == SUCCESS) {	
			if(TOS_NODE_ID == MASTER_RADIO_ID){/*somente o master eh inicializado*/
				_message_token = generate_token(_message_token);
				call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);/*servico de checagem eh ligado*/
				trigger_blinking_led_event(BLINK_DELAY);/*piscada inicial do led*/
				_initialized = TRUE;
				_checking_running = TRUE;				
			}
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}

	event void CheckMilliTimer.fired() {/*servico de checagem*/
		atomic{
			_elapsed_time = _elapsed_time + CHECKING_INTERVAL;

			if(_elapsed_time >= INACTIVE_TIME_LIMIT){
				_elapsed_time = _elapsed_time - CHECKING_INTERVAL;
				_checking = TRUE;
				trigger_timers_oneshot_event(1);
				call CheckMilliTimer.startOneShot(_elapsed_time);
			}
			else{
				_checking = FALSE;
				call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);
			}
		}
	}

	 event void MilliTimer.fired(){/*envio de mensagem*/	
		if (_locked) {/*renviar mensagem se o radio estiver ocupado*/
				if(!_checking){/*nao reenvia se for uma mensagem de checagem*/
					trigger_timers_oneshot_event(SEND_DELAY);
				}
				return;/*sai do evento*/
		}
		else {
			AM_MESSAGE_t* rcm = (AM_MESSAGE_t*)call Packet.getPayload(&_packet, sizeof(AM_MESSAGE_t));
			
			if (rcm == NULL) {
				return;
			}

			if(TOS_NODE_ID == MASTER_RADIO_ID){/*seletor de mote de destino pelo valor da id*/
				rcm->next_node_id = SECONDARY_RADIO_ID;
			}
			else if(TOS_NODE_ID == SECONDARY_RADIO_ID){
				rcm->next_node_id = TERTIARY_RADIO_ID;
			}
			else{
				rcm->next_node_id = MASTER_RADIO_ID;
			}

			rcm->token = _message_token;
			rcm->led_id = _led;/*leds que devem ser acionados*/

			if (call AMSend.send(AM_BROADCAST_ADDR, &_packet, sizeof(AM_MESSAGE_t)) == SUCCESS) {/*envio de mensagem*/
				_locked = TRUE;
			}
		}
	}

	event message_t* Receive.receive(message_t* bufPtr,void* payload, uint8_t len) {/*recebimento de mensagem*/

		if (len != sizeof(AM_MESSAGE_t)) {
			return bufPtr;
		}
		else {			

			AM_MESSAGE_t* rcm = (AM_MESSAGE_t*)payload;

					

			if (rcm->next_node_id == TOS_NODE_ID) {

				if (!is_correct_token(rcm,_message_token)){
					return bufPtr;
				}

				_elapsed_time = 0;

				if (rcm->next_node_id == MASTER_RADIO_ID) {/*master faz o chaveamento dos leds*/
					_message_token = generate_token(_message_token);
					_led++;
					if(_led == 3){
						_led = LED0;
					}
				}
				else{/*os outros apenas realizam a atribuicao de leds*/
					_elapsed_time = 0;
					_message_token = rcm->token;
					_led = rcm->led_id;
					_initialized = TRUE;
				}

				trigger_blinking_led_event(BLINK_DELAY);/*inicia piscada do led*/
								
			}
			return bufPtr;
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {/*envio com sucesso*/
		if (&_packet == bufPtr) {
			_locked = FALSE;
		}
	}

	event void BlinkMilliTimer.fired(){
		if(_bliking_count < LED_BLINK_TOTAL){
			if (_led == LED0) {/*um aceso*/
				call Leds.led0Toggle();
			}
			else if (_led == LED1) {/*dois aceso*/				
				call Leds.led1Toggle();
			}
			else if (_led == LED2) {/*tres aceso*/
				call Leds.led2Toggle();
			}

			_bliking_count++;

			trigger_blinking_led_event(BLINK_DELAY);
		}
		else{
			
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();

			_bliking_count = 0;

			trigger_timers_oneshot_event(SEND_DELAY);

			if(_initialized && !_checking_running){/*ativacao do evento de checagem para nos sem ser o master*/
				call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);
				_checking_running = TRUE;			
			}
		}
	}

	void trigger_timers_oneshot_event(uint16_t delay){/*funcao para disparar o envio de mensagem, com delay*/
		call MilliTimer.startOneShot(delay);
	}

	void trigger_blinking_led_event(uint16_t delay){/*funcao para disparar a piscada do led, com delay*/
		call BlinkMilliTimer.startOneShot(delay);
	}

	uint16_t generate_token(uint16_t current_token){
		uint16_t new_token = current_token;
		while(new_token == current_token){
			new_token = call Random.rand16();
		}
		return new_token;
	}

	bool is_correct_token(AM_MESSAGE_t* message, uint16_t token){
		uint16_t node_id = TOS_NODE_ID;

		if(MASTER_RADIO_ID == node_id){
			if(message->token == token){
				return TRUE;
			}
		}
		else{
			if(message->token != token){
				return TRUE;
			}
		}

		return FALSE;
	}
}





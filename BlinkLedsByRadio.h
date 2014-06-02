#ifndef BLINK_LEDS_BY_RADIO_H
#define BLINK_LEDS_BY_RADIO_H

enum {
  RADIO_CHANNEL = 6,
  MASTER_RADIO_ID = 1,
  SECONDARY_RADIO_ID = 2,
  TERTIARY_RADIO_ID = 3,
  LED0 = 0,
  LED1 = 1,
  LED2 = 2,
  LED_BLINK_TOTAL = 6,
  SEND_DELAY = 50, /*milliseconds*/
  BLINK_DELAY = 400,
  /*time to checking*/
  CHECKING_INTERVAL = (LED_BLINK_TOTAL * BLINK_DELAY) + SEND_DELAY,
  INACTIVE_TIME_LIMIT = (CHECKING_INTERVAL * 6),
};

typedef nx_struct AM_MESSAGE {
  nx_uint8_t next_node_id; /* next node id */
  nx_uint8_t led_id; /* led id */
  nx_uint16_t token;
} AM_MESSAGE_t;
#endif

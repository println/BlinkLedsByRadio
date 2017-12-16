# Real Time and Embedded Systems

A simple test application to blink radio's led on data transfer process

### Tecnology
- nesC
- [MICAz](http://tinyos.stanford.edu/tinyos-wiki/index.php/MICAz)
- [IRIS](http://tinyos.stanford.edu/tinyos-wiki/index.php/Iris)


### Implementar um aplicativo que use 3 nós.

1. O primeiro nó pisca um LED e manda o segundo nó piscar um LED.
1. O segundo nó pisca seu LED e manda o terceiro nó piscar um LED.
1. O terceiro nó pisca seu LED e manda o primeiro nó piscar um LED.
1. O aplicativo roda indefinidamente.

Mostrar o resultado no TOSSIM e com nós reais (eu fornecerei os nós no dia da apresentação)

## Detalhes úteis

#### Pegar id do nó

```
TOS_NODE_ID
```

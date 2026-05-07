class_name StatModifier
## Representa un modificador temporal de una estadística (buff/debuff).

## Estadística afectada: "attack", "defense", "speed"
var stat: String = ""

## Cantidad a sumar (puede ser positiva o negativa)
var value: int = 0

## Turnos restantes (1 turno = un ciclo de combate)
var remaining_turns: int = 0

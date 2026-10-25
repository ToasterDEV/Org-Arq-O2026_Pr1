###############################################################################
# Torres de Hanói - Implementación recursiva en ensamblador
# Por Joshna Alessandro Lomelí Briones y Arturo Javier Alejandro Morán Rouzaud
#
# Organización de memoria (8 words por fila):
#   - Cada torre es una columna: A = +0, B = +4, C = +8.
#   - Cada nivel de la torre es una fila (separación de 32 bytes = 0x20).
#   - Fila 0 = nivel superior; fila N-1 = base de la torre.
#   - Un disco se representa con su tamaño (1 = más pequeño, N = más grande).
#   - Un 0 significa "posición vacía".
#
# Uso de registros:
#   s0 = N (número de discos)
#   s1 = apuntador torre A (origen)
#   s2 = apuntador torre B (auxiliar)
#   s3 = apuntador torre C (destino)
#   s4 = N*32 (bytes que ocupa una columna)
#   a0 = n de la llamada actual
#   a1 = origen
#   a2 = auxiliar
#   a3 = destino
###############################################################################

.data

torres: .space 2048 # Reserva espacio para las torres (hasta 64 niveles)

.text

main:

addi s0, zero, 3       # Número de discos (último valor en la línea).

# Apuntadores a las tres torres (columnas del data segment)

lui   s1, 0x10010       # s1 = 0x10010000 -> torre A (columna +0)
addi  s2, s1, 4         # s2 = 0x10010004 -> torre B (columna +4)
addi  s3, s1, 8         # s3 = 0x10010008 -> torre C (columna +8)
slli  s4, s0, 5         # s4 = N * 32 = bytes de una columna completa (sirve para saber dónde termina cada torre)

# Inicialización: colocar los discos del 1 al total (N) en la torre A. Fila 0 recibe el disco 1 (arriba), fila N-1 el disco N (base).

addi  t0, zero, 1       # t0 = tamaño del disco a colocar (empieza en 1)
add   t1, s1, zero      # t1 = dirección del nivel actual en torre A
init_loop:
blt   s0, t0, init_fin  # si N < disco, ya se colocaron todos -> salir
sw    t0, 0(t1)         # escribir el disco en el nivel actual
addi  t0, t0, 1         # siguiente disco (uno más grande)
addi  t1, t1, 32        # bajar un nivel (siguiente fila)
jal   zero, init_loop   # repetir (jal con rd=zero = salto simple)
init_fin:

# Llamada inicial a función recursiva

add   a0, s0, zero      # a0 = n = N
add   a1, s1, zero      # a1 = origen   = torre A
add   a2, s2, zero      # a2 = auxiliar = torre B
add   a3, s3, zero      # a3 = destino  = torre C
jal   ra, hanoi         # llamar a la función recursiva

# Finalizar el programa
addi  a7, zero, 10      # código de servicio 10 = terminar
ecall

# hanoi(a0 = n, a1 = origen, a2 = auxiliar, a3 = destino)
#
# if n != 1: hanoi(n-1, origen, destino, auxiliar)   # Paso 1
#   mover disco superior de origen a destino         # Paso 2
# if n != 1: hanoi(n-1, auxiliar, origen, destino)   # Paso 3

hanoi:                    # Preprocesado: Guardar contexto en la pila/stack

  addi  sp, sp, -20       # reservar 5 words en el stack
  sw    ra, 16(sp)        # dirección de retorno
  sw    a0, 12(sp)        # número de discos n
  sw    a1, 8(sp)         # apuntador torre origen
  sw    a2, 4(sp)         # apuntador torre auxiliar
  sw    a3, 0(sp)         # apuntador torre destino

# Caso base: n == 1 -> solo mover

  addi  t0, zero, 1       # t0 = 1
  beq   a0, t0, mover     # si n == 1, saltar directo a mover el disco

# Paso 1: hanoi(n-1, origen, destino, auxiliar)

  addi  a0, a0, -1        # n = n - 1, así quitamos uno del contador
  add   t1, a2, zero      # intercambiar auxiliar y destino:
  add   a2, a3, zero      #   nuevo auxiliar = destino
  add   a3, t1, zero      #   nuevo destino  = auxiliar
  jal   ra, hanoi         # llamada recursiva

# Recuperar los argumentos de esta llamada (la recursión los modificó)

  lw    a0, 12(sp)        # n
  lw    a1, 8(sp)         # origen
  lw    a2, 4(sp)         # auxiliar
  lw    a3, 0(sp)         # destino

# Paso 2: Mover disco de origen (a1) a destino (a3)

mover: # Buscar el disco superior de la torre origen: recorrer desde la fila 0 hacia abajo hasta encontrar un valor distinto de 0. (La torre origen nunca debería estar vacía cuando se llega aquí.)
  add   t1, a1, zero        # t1 == dirección de la fila 0 de origen

buscar_origen:

  lw    t2, 0(t1)           # t2 == contenido del nivel actual
  bne   t2, zero, quitar    # si hay disco, es el superior y hay que quitarlo
  addi  t1, t1, 32          # si no, bajar un nivel
  jal   zero, buscar_origen # repetir

quitar:
  sw    zero, 0(t1)       # quitar el disco de origen (dejar 0). t2 conserva el tamaño del disco movido.

# Buscar el lugar libre en la torre destino: recorrer desde la fila 0 hacia abajo hasta encontrar un disco o salir de la torre. El disco se coloca en la fila inmediatamente superior.

  add   t3, a3, zero      # t3 = dirección de la fila 0 de destino
  add   t4, a3, s4        # t4 = dirección justo debajo de la base

buscar_destino:

  beq   t3, t4, colocar   # si se pasó la base, la torre está vacía
  lw    t5, 0(t3)         # t5 = contenido del nivel actual
  bne   t5, zero, colocar # si hay un disco, colocar encima de él
  addi  t3, t3, 32        # si está vacío, bajar un nivel
  jal   zero, buscar_destino

colocar:

   addi  t3, t3, -32       # subir un nivel (primer espacio libre)
   sw    t2, 0(t3)         # colocar el disco en la torre destino

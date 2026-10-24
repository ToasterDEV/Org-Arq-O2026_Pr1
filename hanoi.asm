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
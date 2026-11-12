###############################################################################
# TORRES DE HANOI - PROPUESTA DE OPTIMIZACION (IA, RV32I, CORREGIDA)
# Autoria de equipo original: Joshna Alessandro Lomeli Briones,
#                             Arturo Javier Alejandro Moran Rouzaud.
# Propuesta tecnica de IA: OpenAI GPT-6 (10 de noviembre de 2026).
# Validar en RARS 1.6, memoria Default, RV32.
# Sin pseudoinstrucciones ni extensiones M/F/D.
# Correccion RARS: jalr usa la sintaxis de tres operandos: rd, rs1, imm.
# Modificacion 1: caso base no reserva marco de stack.
# Modificacion 2: t3,t4,t5 guardan punteros al disco superior en A,B,C.
#   Puntero de torre vacia = base + N*32.
#   Cada POP pone 0 y suma 32 al puntero superior.
#   Cada PUSH resta 32 al puntero y guarda el disco.
# La .data y TODOS los discos/ceros ocupan las mismas direcciones que en origen.
# Breakpoint en ver_movimiento (se ejecuta una vez por movimiento completo).
# Cambiar N en 'addi s0, zero, 3': valores recomendados 1..64.
###############################################################################
.data
torres: .space 2048
.text
.globl main
main:
  addi s0, zero, 15       # N discos (1 a 64)
  addi t6, zero, 1
  blt  s0, t6, error_n   # impedir N menor que 1
  addi t6, zero, 64
  blt  t6, s0, error_n   # impedir N mayor que 64
  lui  s1, 0x10010       # base de A
  addi s2, s1, 4        # base de B
  addi s3, s1, 8        # base de C
  slli s4, s0, 5        # 32*N bytes por torre
  addi t0, zero, 1
  add  t1, s1, zero
init_loop:
  blt  s0, t0, init_fin
  sw   t0, 0(t1)
  addi t0, t0, 1
  addi t1, t1, 32
  jal  zero, init_loop
init_fin:
  # Punteros al disco superior: t3=A, t4=B, t5=C.
  add  t3, s1, zero     # A tiene N discos; parte arriba
  add  t4, s2, s4       # B vacia; posicion posterior a la base
  add  t5, s3, s4       # C vacia; posicion posterior a la base
  add  a0, s0, zero
  add  a1, s1, zero
  add  a2, s2, zero
  add  a3, s3, zero
  jal  ra, hanoi
fin_programa:
  addi a7, zero, 10
  ecall
error_n:
  addi a7, zero, 10
  ecall

hanoi:
  addi t0, zero, 1
  beq  a0, t0, mover   # caso base: no guardar contexto en el stack

  # Solo las llamadas no basicas necesitan conservar su estado.
  addi sp, sp, -20
  sw   ra, 16(sp)
  sw   a0, 12(sp)
  sw   a1, 8(sp)
  sw   a2, 4(sp)
  sw   a3, 0(sp)

  # Paso 1: hanoi(n-1, origen, destino, auxiliar)
  addi a0, a0, -1
  add  t1, a2, zero
  add  a2, a3, zero
  add  a3, t1, zero
  jal  ra, hanoi
  lw   a0, 12(sp)
  lw   a1, 8(sp)
  lw   a2, 4(sp)
  lw   a3, 0(sp)

mover:
  # Sacar el disco superior de la torre origen.
  # Los registros t3, t4, t5 son estado global de las tres torres.
  beq  a1, s1, sacar_A
  beq  a1, s2, sacar_B
sacar_C:
  lw   t2, 0(t5)
  sw   zero, 0(t5)
  addi t5, t5, 32
  jal  zero, elegir_destino
sacar_A:
  lw   t2, 0(t3)
  sw   zero, 0(t3)
  addi t3, t3, 32
  jal  zero, elegir_destino
sacar_B:
  lw   t2, 0(t4)
  sw   zero, 0(t4)
  addi t4, t4, 32

  # Introducir disco en la torre destino.
elegir_destino:
  beq  a3, s1, poner_A
  beq  a3, s2, poner_B
poner_C:
  addi t5, t5, -32
  sw   t2, 0(t5)
  jal  zero, ver_movimiento
poner_A:
  addi t3, t3, -32
  sw   t2, 0(t3)
  jal  zero, ver_movimiento
poner_B:
  addi t4, t4, -32
  sw   t2, 0(t4)

ver_movimiento:
  # Situar el breakpoint aqui, despues de terminar las DOS escrituras.
  addi t0, zero, 1
  beq  a0, t0, retorno_base

  # Paso 3: hanoi(n-1, auxiliar, origen, destino)
  addi a0, a0, -1
  add  t1, a1, zero
  add  a1, a2, zero
  add  a2, t1, zero
  jal  ra, hanoi

  # Solo llamadas no basicas tienen marco de stack.
  lw   ra, 16(sp)
  addi sp, sp, 20
  jalr zero, ra, 0
retorno_base:
  jalr zero, ra, 0

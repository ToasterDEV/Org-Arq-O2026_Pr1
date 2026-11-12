###############################################################################
# Torres de Hanói - V4 (RV32I, sin pseudoinstrucciones)
# a1/a2/a3 = apuntador al disco superior de origen/auxiliar/destino
# (torre vacía: base + 32N). hanoi los devuelve ACTUALIZADOS y en el mismo
# orden; preserva a0 y sp. Breakpoint: ver_movimiento. N válido: 1..64.
# Hecho por Claude Opus 5.5 inspirado en implementaciones previas
###############################################################################
.data
torres: .space 2048
.text
main:
  addi s0, zero, 15          # N
  lui  s1, 0x10010          # base torre A
  slli s4, s0, 5            # 32*N
  addi t0, zero, 1
  add  t1, s1, zero
init_loop:                  # do-while (N >= 1)
  sw   t0, 0(t1)
  addi t0, t0, 1
  addi t1, t1, 32
  bge  s0, t0, init_loop
  add  a0, s0, zero         # n = N
  add  a1, s1, zero         # tope A = fila 0
  add  a2, s1, s4
  addi a2, a2, 4            # tope B (vacía) = B + 32N
  add  a3, s1, s4
  addi a3, a3, 8            # tope C (vacía) = C + 32N
  jal  ra, hanoi
  addi a7, zero, 10
  ecall

hanoi:
  addi t0, zero, 1          # t0 = 1 = disco del caso base
  bne  a0, t0, recursivo
mover:                      # mueve el disco t0 de la torre a1 a la torre a3
  sw   zero, 0(a1)          # quitar de origen
  addi a1, a1, 32           # nuevo tope de origen
  addi a3, a3, -32          # nuevo tope de destino
  sw   t0, 0(a3)            # colocar en destino
ver_movimiento:             # <<< BREAKPOINT (movimiento ya visible)
  jalr zero, ra, 0
recursivo:
  addi sp, sp, -4
  sw   ra, 0(sp)            # solo se guarda ra
  addi a0, a0, -1
  add  t1, a2, zero         # hanoi(n-1, origen, destino, auxiliar)
  add  a2, a3, zero
  add  a3, t1, zero
  jal  ra, hanoi
  add  t1, a2, zero         # restaurar orden (origen, auxiliar, destino)
  add  a2, a3, zero
  add  a3, t1, zero
  addi t0, a0, 1            # disco n
  jal  ra, mover            # ra ya está en el stack
  add  t1, a1, zero         # hanoi(n-1, auxiliar, origen, destino)
  add  a1, a2, zero
  add  a2, t1, zero
  jal  ra, hanoi
  add  t1, a1, zero         # restaurar orden
  add  a1, a2, zero
  add  a2, t1, zero
  addi a0, a0, 1            # restaurar n
  lw   ra, 0(sp)
  addi sp, sp, 4
  jalr zero, ra, 0

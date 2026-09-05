@echo off
nasm -f bin boot.asm -o staros.img
if errorlevel 1 (
  echo NASM failed. Is NASM installed?
  pause
  exit /b 1
)
echo Built staros.img
qemu-system-i386 -drive format=raw,file=staros.img
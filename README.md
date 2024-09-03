# Capgemini Assembly tasks
All tasks are implemented for the NASM assembler in Linux environment.

## Getting Started
### Work environment preperation
`git clone https://github.com/denyskryvytskyi/capgemini-assembly`

`sudo apt update`

`sudo apt install nasm gdb gcc`

### Compilation and linking
`nasm -f elf64 task_<n>.asm`

`ld -o task_<n> task_<n>.o`

`./task_<n>`

#### C program compile
`gcc -o task_<n> task_<n>.c`

`./task_<n>`

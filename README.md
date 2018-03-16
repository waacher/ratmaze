MAZE
=========

### A maze game written in assembly 

- The assembly is executed by microprocessor written in VHDL and implemented on a [Basys 3 board from Digilent](https://www.xilinx.com/products/boards-and-kits/1-54wqge.html).
The game is displayed on a VGA monitor connected to the Basys 3 board's VGA output. 

## Files:

Folders include VHDL sources, assembly program file, and a VHDL hardware testbench. 

## Features:

- Counter: The 7-segment display of the Basys 3 board displays the current number of moves.
- Directional LED's: The four right-most LED's light up to show the direction of travel.
- Reset: Pressing the center button resets the game while saving the previous attempt.
- Color warning: The maze changes color when the player runs into a wall.
- Ending: The game displays a win screen upon completion of the maze.


## Controls:

Action | Control
------ | -----------
Up/down | btnU/btnD
Left/right | btnL/btnR
Move | Switch 1-8 (Any one of the 8 rightmost switches)
Reset | btnC


## Technology:

Implementations:

 - Collision detection and color change
 - VGA Output
 - Button debouncing for accurate user actions
 - RAT microprocessor     
    - I/O 
    - Interrupt support
 - VGA buffer
    - VGA driver
    - RAM 
 - 7-seg driver
 - Assembly program

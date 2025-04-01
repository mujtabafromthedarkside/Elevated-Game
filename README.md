# Elevated game

## Idea
A simple game programmed in Flutter, inspired by Flappy Bird. The player controls a rotating square object. Obstacles fall from above.

## Instructions
- Tap anywhere to jump.
- Tilt your phone to move sideways.
- Do not let the square fall down.
- Dodge the falling obstacles.

## How I Made It
- There's no animation plugin being used. It's all primitives being moved around by changing their states.
- Each object you see on the screen has two components: a state object and a visualizer
- It's mostly simple except rotating a state object. The visualizer can be rotated by built-in functions.
- Rotating a state of an object (i.e. the values of the pixels) requires writing your own **trigonometry**. This was the fun part.

## Screenshots
<div align="center">
    <img src="readme/home.jpg" alt="Home Screen" width="230"/>
    <img src="readme/start.jpg" alt="Start Screen" width="230"/>
</div>
<div align="center">
    <img src="readme/play.jpg" alt="Play Screen" width="230"/>
    <img src="readme/game_over.jpg" alt="Game Over Screen" width="230"/>
</div>

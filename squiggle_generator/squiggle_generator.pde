// Squiggle Generator
// "Take a Dot for a Walk"

import processing.svg.*;

float px, py, angle;
float maxTurn;
float scale;
float minStep, maxStep;
float numBigTurns, numSmallTurns;
float bigThreshold;
int fileIndex;
int series;
int numPoints;

void setup() {
  size(1056, 816); // Letter: 11"x8.5" at 96 DPI.
  fileIndex = 1;
  series = (int)random(1000);

  // Tweak to change the look of the line
  numPoints = 80;
  scale = 100.0;
  minStep = 20;
  maxStep = 100;
  maxTurn = QUARTER_PI + PI/8; // Don't turn faster than this (Quarter = circles, Half = squares, PI = starbursts)
  bigThreshold = 0.80; // Higher percent, more loops
}

void draw() {
  noiseSeed(millis());
  background(255);
  //showField();

  // Start in center, angled up
  px = width/2; // center
  py = height/2; // center
  angle = HALF_PI; // Up

  numBigTurns = 0;
  numSmallTurns = 0;

  String filename = "generated/squiggle-" + series + "-" + fileIndex + ".svg";
  beginRecord(SVG, filename);
  noFill();
  stroke(0, 0, 0);
  strokeWeight(2);

  beginShape();
  curveVertex(px, py);
  curveVertex(px, py);

  for (int i = 0; i < numPoints; i++) {
    float pNoise = noise(px/scale, py/scale); //0..1

    float deltaAngle = map(pNoise, 0, 1, -TWO_PI, TWO_PI);
    float step = map(pNoise, 0, 1, minStep, maxStep);

    // If turn is too big, turn maxTurn instead
    // Count number of maxed out turns vs. allowed turns
    if (abs(deltaAngle) > maxTurn) {
      angle += maxTurn;
      numBigTurns++;
    } else {
      angle += deltaAngle;
      numSmallTurns++;
    }

    // Calculate new point
    px += step * cos(angle);
    py += step * sin(angle);

    for (int k = 0; k < 50; k++) {
      if (checkBounds(px, py)) {
        break;
      } else {
        // Out of bounds. Attempt to fix the coords
        float nudgeAngle = random(PI/32, PI);
        angle = -1 * angle + nudgeAngle;
        px += step * cos(angle);
        py += step * sin(angle);
      }
    }

    if (checkBounds(px, py)) {
      curveVertex(px, py);
    } else {
      // Was unable to fix the out of bounds in the number of loops
      break;
    }
  }
  endShape();
  endRecord();
  noLoop();

  // If good result, increment the filename counter to protect from overwrite
  // If bad result, make another attempt and then overwrite the bad file
  float percentBig = numBigTurns / (numBigTurns + numSmallTurns);
  if (percentBig > bigThreshold) {
    println("bad art, trying again...");
    loop();
  } else {
    // good art
    //fileIndex++;
  }
}

boolean checkBounds(float px, float py) {
  int buffer = 50;
  if (px >= width-buffer || px <= buffer || py >= height-buffer || py <= buffer) {
    return false;
  } else {
    return true;
  }
}

void keyPressed() {
  if (key == 's') {
    fileIndex++;
  }
}

void showField() {
  noStroke();

  for (int y=0; y<height; y+=5) {
    for (int x=0; x<width; x+=5) {
      float nShading = noise(x/scale, y/scale);
      float shading = map(nShading, 0, 1, 75, 255);
      fill(shading);
      rect(x, y, 5, 5);
    }
  }
}

void mousePressed() {
  loop();
}

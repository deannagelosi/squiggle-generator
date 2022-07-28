// Squiggle Generator
// "Take a Dot for a Walk"

// save the points and angles, export them to a text file
// work on addative code later, using those saved points

import processing.svg.*;

float px, py, angle;
float maxTurn;
float scale;
float minStep, maxStep;
float numBigTurns, numSmallTurns;
float bigThreshold;
int fileIndex;
int series;
int numSteps;
int reload;
int canvasH, canvasW;
int centerX, centerY;
int buffer;
int squiggleLength;
String[] points = {};

void setup() {
  // w:352, h:408; // 11"x8.5" at 96 DPI split into 2 rows, 3 columns
  // w:1056, h:816; // 11"x8.5" at 96 DPI.
  // size(w,h)
  size(352, 408); 
  
  fileIndex = 1;
  series = (int)random(1000);

  // Tweak to change the look of the line
  numSteps = 80;
  minStep = 20;
  maxStep = 100;
  buffer = 35;
  scale = 100.0; // position on the Perlin noise field
  maxTurn = QUARTER_PI + PI/8; // Don't turn faster than this (Quarter = circles, Half = squares, PI = starbursts)
  bigThreshold = 0.80; // Higher percent, more loops

}

void draw() {
  noiseSeed(millis());
  background(255);
  //showField();

  squiggleLength = 0;

  // Start in center, angled up
  centerX = width/2; // center
  centerY = height/2; // center
  px = centerX;
  py = centerY;
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
  points = append(points, "px: " + px + ", py: " + py);
  points = append(points, "px: " + px + ", py: " + py);

  // Lays down points of a line
  for (int i = 0; i < numSteps; i++) {

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
      squiggleLength += step;
      curveVertex(px, py);
      points = append(points, "px: " + px + ", py: " + py);
    } else {
      // Unable to fix out of bounds in number of loops, end line
      break;
    }
  }
  // println("Line length: " + squiggleLength);
  endShape();
  endRecord();
  saveStrings("generated/points-" + series + "-" + fileIndex + ".txt", points);
  noLoop();

  // If good result, increment the filename counter to protect from overwrite
  // If bad result, make another attempt and then overwrite the bad file
  float percentBig = numBigTurns / (numBigTurns + numSmallTurns);
  if (percentBig > bigThreshold || squiggleLength < 1500 || squiggleLength > 3000) {
    println("bad art, trying again...");
    loop();
  } else {
    // good art
  }
}

boolean checkBounds(float px, float py) {
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

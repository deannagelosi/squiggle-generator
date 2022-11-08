// Squiggle Generator
// "Take a Dot for a Walk"

import processing.svg.*;

float maxTurn;
float scale;
float bigThreshold;
int minSteps, maxSteps;
int minDistance, maxDistance;
int minLength, maxLength;
int centerX, centerY;
int buffer;
int reloadAmount;
int seed;
boolean showField;
Point[] squigglePoints;

void setup() {
  // w:1056, h:816; // 11"x8.5" at 96 DPI.
  // w:432, h:288; // 4.5x3" 2x2 grid with 1" margins on a 12x9"
  // w:352, h:408; // 11"x8.5" at 96 DPI split into 2 rows, 3 columns
  // size(w,h)
  size(432, 288);

  centerX = width/2; // center
  centerY = height/2; // center

  // Tweak to change the look of the line
  reloadAmount = 3; // amount of paint collected for additive
  minSteps = 20; // number of points a line could have
  maxSteps = 80;
  minDistance = 20; // how far a point can be from the previous point
  maxDistance = 100;
  minLength = 1500;
  maxLength = 3000;
  buffer = 35;
  scale = 100.0; // position on the Perlin noise field
  maxTurn = QUARTER_PI + PI/8; // Max turn speed (QUARTER_PI = circles, HALF_PI = squares, PI = starbursts)
  bigThreshold = 0.80; // Higher percent, more loops
  seed = 1; // increment on each attempt
  showField = false;
}

void draw() {
  
  
  squigglePoints = generateSquigglePoints();
  drawSquiggle(squigglePoints);

  // reloadPaint();
  // drawSquiggle((Point[])subset(allPoints, 0, 10)); // 0 + 10 = 10
  // reloadPaint();
  // drawSquiggle((Point[])subset(allPoints, 10 - 3, 10)); // 10 - 3 + 9 = 16
  // reloadPaint();
  // drawSquiggle((Point[])subset(allPoints, 17 - 2, 10)); // 17 - 2 + 9 = 24 
  // reloadPaint();
  // drawSquiggle((Point[])subset(allPoints, 24 - 2, 10 + 6)); // 24 - 2 = 22
  
  noLoop();
}

Point[] generateSquigglePoints() {
  // generate array of Points

  Point[] pointsArray = new Point[0];

  boolean goodArt = false; 

  while (goodArt == false) { // loop until good art is made
    // Set the Perlin noise seed
    noiseSeed(seed);
    pointsArray = new Point[0]; // blank out points array

    // Start in center, angled up
    float px = centerX;
    float py = centerY;
    float angle = HALF_PI; // Up

    // Reset Bad Art Check params
    int squiggleLength = 0;
    int numBigTurns = 0;
    int numSmallTurns = 0;

    for (int i = 0; i < maxSteps; i++) {
      // Sample Perlin at current point
      float pNoise = noise(px/scale, py/scale); //0..1
      // Select angle and distance to next point
      float deltaAngle = map(pNoise, 0, 1, -TWO_PI, TWO_PI);
      float distance = map(pNoise, 0, 1, minDistance, maxDistance);

      // If turn is too big, use maxTurn instead
      if (abs(deltaAngle) > maxTurn) {
        angle += maxTurn;
        numBigTurns++; // count # of turn types for bad art analysis
      } else {
        angle += deltaAngle;
        numSmallTurns++;
      }

      // Calculate next point coords
      px += distance * cos(angle);
      py += distance * sin(angle);

      // If out of bounds, attempt to turn away from the border
      for (int k = 0; k < 50; k++) {
        if (checkBounds(px, py)) {
          // No longer out of bounds. Stop nudging.
          break; 
        } else {
          // Out of bounds. Attempt to fix the coords
          // Sample new noise with k as offest
          float newNoise = noise((px+(k*10))/scale, py/scale);
          // Nudge the direction by a new angle
          float nudgeAngle = map(newNoise, 0, 1, PI/32, PI);
          angle = -1 * angle + nudgeAngle;
          
          // Calc new next point with the nudge
          px += distance * cos(angle);
          py += distance * sin(angle);
        }
      }

      if (checkBounds(px, py)) {
        // Succesfully nudged back into bounds within k loops.
        // Add point and track current line length
        Point newPoint = new Point(px, py);
        pointsArray = addPoint(pointsArray, newPoint);
        squiggleLength += distance;
        // Carry on with loop and add more points.
      } else {
        // Unable to fix out-of-bounds within k loops. End the line.
        break;
      }
    }

    // Check if all the points made a good line
    float percentBig = numBigTurns / (numBigTurns + numSmallTurns);
    if (percentBig > bigThreshold || squiggleLength < minLength || squiggleLength > maxLength) {
      // Bad art, try again with the next seed
      goodArt = false;
      seed++;
    } else {
      // good art, end the while loop
      goodArt = true;
    }
  }
  
  return pointsArray;
}

boolean checkBounds(float px, float py) {
  if (px >= width-buffer || px <= buffer || py >= height-buffer || py <= buffer) {
    return false;
  } else {
    return true;
  }
}

void drawSquiggle(Point[] points) {
  background(255);

  if (showField == true) {
    showField();
  }
  
  noFill();
  stroke(0, 0, 0);
  strokeWeight(2);

  beginShape();
  curveVertex(points[0].x, points[0].y);
  for (int i = 0; i < points.length; i++) {
    curveVertex(points[i].x, points[i].y);
  }
  endShape();
}

// void reloadPaint() {
//   // Additive mode, draw circles where extra pain is located
//   int paintX = centerX;
//   int paintY = centerY + height;
//   // ellipse(a, b, c, d)  a/b are center, c/d are diameter
//   //noFill();
//   for (int i = 0; i < reloadAmount; i++) {
//     ellipse(paintX, paintY, 10, 10);
//   }
// }

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

void keyPressed() {
  if (key == 's') {
    String filename = "generated/squiggle-seed" + seed + ".svg";
    beginRecord(SVG, filename);
    drawSquiggle(squigglePoints);
    endRecord();
  } else if (key == 'f') {
    // Toggle the show field boolean
    showField = !showField;
    loop();
  }
}

void mousePressed() {
  // try next seed
  seed++;
  loop();
}

class Point {
  float x, y;
  // constructor
  Point(float x_, float y_) {
    x = x_;
    y = y_;
  }
}

Point[] addPoint(Point[] points, Point newPoint) {
  Point[] modifiedPoints = new Point[points.length + 1];
  for (int i = 0; i < points.length; i++) {
    modifiedPoints[i] = points[i];
  }
  modifiedPoints[points.length] = newPoint;

  return modifiedPoints;
}
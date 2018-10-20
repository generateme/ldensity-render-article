void setup() {
  size(800, 800);
  smooth(8);
  noStroke();
  fill(250, 5); // alpha = 2%
  background(15);
  noiseSeed(1234); // initialize noise function
}

int pointsNo = 500000; // number of points rendered in one frame

void draw() {
  translate(400, 400); // set (0,0) in the middle
  for (int i=0; i<pointsNo; i++) { // draw points batch in a loop 
    PVector np = calcNebulaPoint(); // retrieve random point
    rect(np.x, np.y, 1, 1); //draw
  }
  
  println("Points: " + frameCount*pointsNo);
}

float noiseScale = 50.0; 

PVector calcNebulaPoint() {
  float x = randomGaussian(); // take random point from gaussian distribution
  float y = randomGaussian();

  float r = noiseScale * sqrt(x*x+y*y); // calculate noise scaling factor from distance

  float nx = r * (noise(x, y) - 0.5); // shift x 
  float ny = r * (noise(y-1.1, x+1.1, 0.4) - 0.5); // shift y

  return new PVector(100.0*x+nx, 100.0*y+ny);
}

void keyPressed() {
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

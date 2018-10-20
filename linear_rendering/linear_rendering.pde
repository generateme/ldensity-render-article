void setup() {
  size(800, 800);
  noiseSeed(1234); // initialize noise function
}

LinearRenderer lr = new LinearRenderer(800, 800); // create renderer 

int pointsNo = 1000000; // number of points rendered in one frame

void draw() {
  for (int i=0; i<pointsNo; i++) { // draw points batch in a loop
    PVector np = calcNebulaPoint();  // retrieve random point
    lr.add(np.x, np.y); // increment hits
  } 

  PImage result = lr.render(color(15), color(250)); // final rendering

  image(result, 0, 0); // to the screen
  
  println("Points: " + frameCount*pointsNo);
}

float noiseScale = 50.0;

PVector calcNebulaPoint() {
  float x = randomGaussian(); // take random point from gaussian distribution
  float y = randomGaussian();

  float r = noiseScale * sqrt(x*x+y*y); // calculate noise scaling factor from distance

  float nx = r * (noise(x, y) - 0.5); // shift x
  float ny = r * (noise(y-1.1, x+1.1, 0.4) - 0.5); // shift y

  return new PVector(400.0+100.0*x+nx, 400.0+100.0*y+ny);
}

void keyPressed() {
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

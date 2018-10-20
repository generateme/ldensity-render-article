void setup() {
  size(800, 800);
  noiseSeed(1234);
}

ColorLogRenderer lr = new ColorLogRenderer(800, 800); // create renderer 

float gamma = 1.8; // darken
int pointsNo = 1000000; // number of points rendered in one frame

// three nebula colors
color c1 = #6699cc;
color c2 = #aa6633;
color c3 = #ffdd88;

// lerp between colors
color lerpNebulaColors(float t) {
  if (t < 0.5)
    return lerpColor(c1, c2, t*2.0);
  else
    return lerpColor(c2, c3, t*2.0-1.0);
}

float noiseScale = 50.0;

void draw() {
  for (int i=0; i<1000000; i++) {
    // take random point from gaussian distribution
    float x = randomGaussian(); 
    float y = randomGaussian();

    // calculate noise scaling factor from distance
    float r = noiseScale * sqrt(x*x+y*y);

    float t1 = noise(x, y);
    float t2 = noise(y-1.1, x+1.1, 0.4);

    // shift
    float nx = r * (t1 - 0.5);
    float ny = r * (t2 - 0.5);

    // point
    float px = 400.0+100.0*x+nx;
    float py = 400.0+100.0*y+ny;

    // color factor
    float t = sqrt(t1*t2);

    lr.add(px, py, lerpNebulaColors(t));
  }

  image(lr.render(color(15), gamma), 0, 0);

  println("Points: " + frameCount*pointsNo);
}

void keyPressed() {
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

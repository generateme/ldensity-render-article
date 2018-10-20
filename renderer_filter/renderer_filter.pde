import java.awt.Color;

void setup() {
  size(800, 800);
  noiseSeed(1234);
}

Renderer lr = new Renderer(800, 800, new Gaussian()); // create renderer 

float gamma = 0.85; // alpha gamma
float cgamma = 2.0; // color gamma
float color_mix = 0.5; // mix between color averaged and gamma corrected
float brightness = 1.6; // brightness factor
float contrast = 1.2; // contrast factor
float saturation = 1.2; // saturation factor

int pointsNo = 1000000; // number of points rendered in one frame

color c1 = #6699cc;
color c2 = #aa6633;
color c3 = #ffdd88;

color lerpNebulaColors(float t) {
  if (t < 0.5)
    return lerpColor(c1, c2, t*2.0);
  else
    return lerpColor(c2, c3, t*2.0-1.0);
}

float noiseScale = 50.0;

void drawNebula() {
  for (int i=0; i<pointsNo; i++) {
    float x = randomGaussian(); 
    float y = randomGaussian();

    float r = noiseScale * sqrt(x*x+y*y);

    float t1 = noise(x, y);
    float t2 = noise(y-1.1, x+1.1, 0.4);

    float nx = r * (t1 - 0.5);
    float ny = r * (t2 - 0.5);

    float px = 400.0+100.0*x+nx;
    float py = 400.0+100.0*y+ny;

    float t = sqrt(t1*t2);

    lr.add(px, py, lerpNebulaColors(t));
  }
}

void drawPattern() {
  for (int i=0; i<pointsNo; i++) {
    float x = random(-1, 1);
    float y = random(-1, 1);
    float angle = atan2(y, x);
    float r = 1.0+x*x+y*y;

    color c = color(255*sq(sq(sin(200/r*angle))));

    lr.add(400.0+x*400, 400+y*400, c);
  }
}


void draw() {  
  //drawPattern();
  drawNebula();

  int time = millis();
 
  image(lr.render(color(15), gamma, cgamma, color_mix, brightness, contrast, saturation), 0, 0);

  println("Points: " + frameCount*pointsNo + "; time=" + (millis()-time) + "ms");
}

void keyPressed() {
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

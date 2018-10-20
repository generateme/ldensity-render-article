// Visualize filter points
// move mouse
// press 0-3 for different filters

int size = 15;
void setup() {
  size(600, 800);
  smooth(0);
  rectMode(CENTER);
}

int filter_type = 0;

AFilter makeFilter(float a, float b) {
  switch(filter_type) {
  case 1: 
    return new Sinc(a, b);
  case 2: 
    return new BlackmanHarris(a, b);
  case 3: 
    return new Triangle(a, b);
  case 4:
    return new Hann(a, b);
  default: 
    return new Gaussian(a, b);
  }
}

String filterName() {
  switch(filter_type) {
  case 1: 
    return "Sinc";
  case 2: 
    return "BlackmanHarris";
  case 3: 
    return "Triangle";
  case 4:
    return "Hann";
  default: 
    return "Gaussian";
  }
}

void keyPressed() {
  filter_type = (int)key - 48;
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

void draw() {
  background(15);
  stroke(20, 220);

  float vx = 0.05*(int)map(mouseX, 0, width, 0.0001, 200);
  float vy = 0.05*(int)map(mouseY, 0, width, 0.0001, 200);
  AFilter f = makeFilter(vx, vy);
  int off=0;

  fill(255);
  text(filterName(), 10, 12);
  text("Radius: " + vx, 10, 26);
  text("Second parameter: " + vy, 10, 40);

  translate(300, 300);
  for (int x=0; x<16; x++) {
    for (int y=0; y<16; y++) {
      float fv =(float)(256.0*f.filterTable[off]);
      if (fv<0) {
        fill(abs(fv), 0, 0);
      } else {
        fill(fv);
      }
      rect(x*size, y*size, size, size);
      rect(-x*size, y*size, size, size);
      rect(x*size, -y*size, size, size);
      rect(-x*size, -y*size, size, size);
      off++;
    }
  }

  float fx = 100; 
  float fy = 100;
  int p0x = (int)Math.ceil(fx-0.5-f.radius);
  int p0y = (int)Math.ceil(fy-0.5-f.radius);
  int p1x = (int)Math.floor(fx-0.5+f.radius)+1;
  int p1y = (int)Math.floor(fy-0.5+f.radius)+1;

  int diffx = p1x-p0x;
  int diffy = p1y-p0y;

  if (diffx>0 && diffy>0) {

    int[] ifx = new int[diffx];
    int[] ify = new int[diffy];

    for (int x=p0x; x<p1x; x++) {
      double v = Math.abs( (x-fx)*f.iradius16);
      ifx[x-p0x] = Math.min((int)Math.floor(v), 15);
    }

    for (int y=p0y; y<p1y; y++) {
      double v = Math.abs( (y-fy)*f.iradius16);
      ify[y-p0y] = Math.min((int)Math.floor(v), 15);
    }

    fill(10, 255, 100, 50);
    for (int x=p0x; x<p1x; x++) {
      int xx = ifx[x-p0x];
      for (int y=p0y; y<p1y; y++) {
        int yy = ify[y-p0y];
        rect(xx*size, yy*size, size/2, size/2);
        rect(-xx*size, yy*size, size/2, size/2);
        rect(xx*size, -yy*size, size/2, size/2);
        rect(-xx*size, -yy*size, size/2, size/2);
      }
    }

    stroke(200, 50);
    for (int x=p0x; x<p1x; x++) {
      int xx = ifx[x-p0x];
      line(xx*size, 250, xx*size, 500);
      line(-xx*size, 250, -xx*size, 500);
    }
  }

  stroke(100, 100, 255);
  noFill();
  line(-300, 400, 300, 400);

  stroke(250, 200);
  noFill();

  beginShape();
  for (int x=-16*size; x<16*size; x+=2) {
    float xx = map(x, -16*size, 16*size, (float)-f.radius, (float)f.radius);
    float yy = (float)(100*f.evaluate(xx, 0));

    vertex(x, 400-yy);
  }
  endShape();
}

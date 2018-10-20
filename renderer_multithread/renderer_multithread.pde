import java.awt.Color;
import java.util.concurrent.*;
import java.util.List;

// reconstruction filter
AFilter filter = new Gaussian(1.0,2.0);
// rendering buffer
Renderer buffer = new Renderer(800, 800, filter);

void setup() {
  size(800, 800);
  noiseSeed(1234);

  // draw some points first to have rough sketch
  drawNebula(buffer, 100000);
}

// final rendering parameters
float gamma = 0.95; // alpha gamma
float cgamma = 2.0; // color gamma
float color_mix = 0.5; // mix between color averaged and gamma corrected
float brightness = 1.6; // brightness factor
float contrast = 1.2; // contrast factor
float saturation = 1.2; // saturation factor

int pointsNo = 500000; // number of points rendered in one frame

// nebula colors
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

void drawNebula(Renderer lr, int points) {
  for (int i=0; i<points; i++) {
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

// Task drawing nebula in separate thread
// Drawing is done on own buffer, which is returned finally
class DrawNebulaTask implements Callable<Renderer> {
  Renderer call() {
    Renderer lr = new Renderer(800, 800, filter); // create renderer
    drawNebula(lr, pointsNo);
    return lr;
  }
}

// run thread and merge collected results into buffer
void drawAndMergeNebulas() throws InterruptedException, ExecutionException {
  Runner<Renderer> threads = new Runner<Renderer>(executor);
  for (int i=0; i<numberOfProcessors; i++) {
    threads.addTask(new DrawNebulaTask());
  }

  for (Renderer r : threads.runAndGet()) {
    buffer.merge(r);
  }
}

// render to screen
void draw() {
  try {
    image(buffer.render(color(15), gamma, cgamma, color_mix, brightness, contrast, saturation), 0, 0);
    if (frameCount>1) drawAndMergeNebulas();
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}

void keyPressed() {
  if (keyCode == 32) {
    saveFrame(hex((int)random(0x10000)) + "_#####.png");
    println("image saved");
  }
}

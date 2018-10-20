class LinearRenderer { 
  int[] hits; // pixels buffer, count hits
  int w, h;  // dimensions
  PImage img; // PImage buffer

  // initialize
  public LinearRenderer(int w, int h) { 
    this.w = w; 
    this.h = h; 
    hits = new int[w*h];
    img = createImage(w, h, RGB); // create PImage buffer
  } 

  // add point at specific position
  void add(float x, float y) { 
    int xx = floor(x); 
    int yy = floor(y); 
    if (xx>=0 && xx<w && y>=0 && yy<h) { // check boundaries 
      hits[yy*w+xx]++; // increment counter
    }
  } 

  // render image for given background and foreground colors
  // correct calculated alpha with gamma factor
  PImage render(color background, color foreground, float gamma) { 
    
    // first find maximum number of hits
    float mx = 0; 
    for (int i=0; i<hits.length; i++) {
      if (hits[i]>mx) mx=hits[i];
    } 

    img.loadPixels();  // prepare pixels table
    
    for (int i=0; i<hits.length; i++) { // for each pixel
      if (hits[i]>0) { // if there are some hits
        float alpha = pow(hits[i]/mx, gamma); // scale lineary number of hits to the values between 0 and 1. Apply gamma factor with pow() 
        img.pixels[i] = lerpColor(background, foreground, alpha); // interpolate lineary between background and foreground colors
      } else { 
        img.pixels[i] = background; // no hits? set background color
      }
    } 

    img.updatePixels(); // upload pixels table
    return img; // return image
  }
} 

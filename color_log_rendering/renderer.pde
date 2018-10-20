class ColorLogRenderer {

  int[] hits; // pixels buffer, count hits
  int[] r, g, b; // color channel buffer, values
  int w, h; // dimensions
  PImage img; // PImage buffer

  // initialize
  public ColorLogRenderer(int w, int h) {
    this.w = w;
    this.h = h;

    int size = w*h;
    hits = new int[size];
    r = new int[size];
    g = new int[size];
    b = new int[size];

    img = createImage(w, h, RGB); // create PImage buffer
  }

  // add color at specific position
  void add(float x, float y, color c) {
    int xx = floor(x);
    int yy = floor(y);
    if (xx>=0 && xx<w && yy>=0 && yy<h) {
      int idx = yy*w+xx;

      hits[idx]++;
      r[idx] += (c >> 16) & 0xff; // extract red
      g[idx] += (c >> 8) & 0xff; // extract green
      b[idx] += c & 0xff; // extract blue
    }
  }

  // render image for given background
  // treat alpha as log scaled
  // calculate color as an average of all hits
  // correct calculated alpha with gamma factor
  PImage render(color background, float gamma) {

    // find maximum number of hits
    float mx = 0;
    for (int i=0; i<hits.length; i++) {
      if (hits[i]>mx) mx=hits[i];
    }

    float lmx = log(mx + 1.0); // calculate maximum number of hits in log scale

    img.loadPixels();

    for (int i=0; i<hits.length; i++) { // for each pixel
      int hitsNo = hits[i]; 
      if (hitsNo > 0) { // if there are some hits
        // Scale lineary number of hits to the values between 0 and 1.
        // Hits are in log scale now
        // Apply gamma factor with pow()
        float alpha = pow(log(hits[i]+1.0)/lmx, gamma); 

        // calculate average for each channel separately
        int rr = (int)(r[i]/hitsNo); // simple average 
        int gg = (int)(g[i]/hitsNo); 
        int bb = (int)(b[i]/hitsNo);

        // pack channels into 32bit integer (same as color(rr,gg,bb))
        int foreground = 0xff000000 | (rr << 16) | (gg << 8) | bb;

        // interpolate lineary between background and foreground colors
        img.pixels[i] = lerpColor(background, foreground, alpha);
      } else {
        // no hits? set background color
        img.pixels[i] = background;
      }
    }

    img.updatePixels(); // upload pixels table
    return img; // return image
  }
}

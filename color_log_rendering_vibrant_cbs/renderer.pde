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

  private int[] calcBrightnessContrastLut(float brightness, float contrast) {
    int[] lut = new int[256];

    for (int i=0; i<256; i++) {
      lut[i] = constrain((int)(0.5 + 255.0 * (((i / 255.0) * brightness - 0.5) * contrast + 0.5)), 0, 255);
    }

    return lut;
  }

  // render image and apply all of the modifiers
  PImage render(color background, float gamma, float cgamma, float color_mix, float brightness, float contrast, float saturation) {
    // extract gamma colors
    int backg_r = (background >> 16) & 0xff;
    int backg_g = (background >> 8) & 0xff;
    int backg_b = background & 0xff;

    // prepare flags 
    boolean do_saturation = saturation != 1.0;
    boolean do_bc = (brightness != 1.0) || (contrast != 1.0);
    boolean do_color_mix = color_mix > 0.0;
    boolean do_gamma = gamma != 1.0;

    // find maximum number of hits
    float mx = 0;
    for (int i=0; i<hits.length; i++) { // find max hits
      if (hits[i]>mx) mx=hits[i];
    }

    float lmx = log(mx + 1.0); // calculate maximum number of hits in log scale

    // prepare LUT for brightness and contrast
    int[] bc_lut = calcBrightnessContrastLut(brightness, contrast);

    img.loadPixels();

    for (int i=0; i<hits.length; i++) { // for each pixel
      int rr, gg, bb; // placeholders for final color
      int hitsNo = hits[i];

      if (hitsNo>0) {
        // calculate alpha
        float alpha = do_gamma ? pow(log(hits[i]+1.0)/lmx, gamma) : log(hits[i]+1.0)/lmx;

        // calulate color as average
        float fr = r[i]/hitsNo;
        float fg = g[i]/hitsNo;
        float fb = b[i]/hitsNo;

        // if color vibrancy, lerp between average and gamma corrected color
        if (do_color_mix) {
          rr = (int)lerp(fr, 255.0*pow(fr/255.0, cgamma), color_mix);
          gg = (int)lerp(fg, 255.0*pow(fg/255.0, cgamma), color_mix);
          bb = (int)lerp(fb, 255.0*pow(fb/255.0, cgamma), color_mix);
        } else { // or just leave unchanged
          rr = (int)fr;
          gg = (int)fg;
          bb = (int)fb;
        }

        // interpolate channels with alpha value
        rr = (int)lerp(backg_r, rr, alpha);
        gg = (int)lerp(backg_g, gg, alpha);
        bb = (int)lerp(backg_b, bb, alpha);
      } else { // or just use background
        rr = backg_r;
        gg = backg_g;
        bb = backg_b;
      }

      // modify contrast and brighness if necessary
      if (do_bc) {
        rr = bc_lut[rr];
        gg = bc_lut[gg];
        bb = bc_lut[bb];
      }

      // modify saturation if necessary and pack into int32
      if (do_saturation) {
        float[] hsb = Color.RGBtoHSB(rr, gg, bb, null);
        hsb[1] = constrain(hsb[1]*saturation, 0.0, 1.0);
        img.pixels[i] = Color.HSBtoRGB(hsb[0], hsb[1], hsb[2]);
      } else {      
        img.pixels[i] = 0xff000000 | (rr << 16) | (gg << 8) | bb;
      }
    }

    img.updatePixels();
    return img;
  }
}

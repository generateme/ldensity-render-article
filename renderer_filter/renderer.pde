class Renderer {
  double[] weights; // sum of weights
  double[] r, g, b;
  int w, h;
  AFilter filter;
  PImage img;

  private int wdec, hdec;

  public Renderer(int w, int h, AFilter filter) {
    this.w = w;
    this.h = h;
    this.filter = filter;

    wdec = w - 1;
    hdec = h - 1;

    int size = w*h;
    weights = new double[size];
    r = new double[size];
    g = new double[size];
    b = new double[size];
    
    img = createImage(w, h, RGB);
  }

  public Renderer(int w, int h) {
    this(w, h, null);
  }

  //
  void add(double x, double y, color c) {
    if (filter == null) {
      int xx = (int)Math.floor(x);
      int yy = (int)Math.floor(y);
      if (xx>=0 && xx<w && yy>=0 && yy<h) {
        int idx = yy*w+xx;

        weights[idx]++;
        r[idx] += (c >> 16) & 0xff;
        g[idx] += (c >> 8) & 0xff;
        b[idx] += c & 0xff;
      }
    } else {
      addFiltered(x, y, c);
    }
  }

  // pbrt way of setting point
  // http://www.pbr-book.org/3ed-2018/Sampling_and_Reconstruction/Film_and_the_Imaging_Pipeline.html
  public void addFiltered(double fx, double fy, color c) {
    int p0x = Math.max((int)Math.ceil(fx-0.5-filter.radius), 0);
    int p0y = Math.max((int)Math.ceil(fy-0.5-filter.radius), 0);
    int p1x = Math.min((int)Math.floor(fx-0.5+filter.radius)+1, wdec);
    int p1y = Math.min((int)Math.floor(fy-0.5+filter.radius)+1, hdec);

    int diffx = p1x-p0x;
    int diffy = p1y-p0y;

    if (diffx>0 && diffy>0) {

      int[] ifx = new int[diffx];
      int[] ify = new int[diffy];

      for (int x=p0x; x<p1x; x++) {
        double v = Math.abs( (x-fx)*filter.iradius16);
        ifx[x-p0x] = Math.min((int)Math.floor(v), 15);
      }

      for (int y=p0y; y<p1y; y++) {
        double v = Math.abs( (y-fy)*filter.iradius16);
        ify[y-p0y] = Math.min((int)Math.floor(v), 15);
      }

      int rr = (c >> 16) & 0xff;
      int gg = (c >> 8) & 0xff;
      int bb = c & 0xff;

      for (int x=p0x; x<p1x; x++) {
        for (int y=p0y; y<p1y; y++) {
          int off = (ify[y-p0y]<<4)+ifx[x-p0x];
          add(x, y, rr,gg,bb, filter.filterTable[off]);
        }
      }
    }
  }

  void add(int x, int y, int red, int green, int blue, double weight) {
    int idx = y*w+x;
    weights[idx] += weight;
    r[idx] += weight*red;
    g[idx] += weight*green;
    b[idx] += weight*blue;
  }

  private int[] calcBrightnessContrastLut(double brightness, double contrast) {
    int[] lut = new int[256];

    for (int i=0; i<256; i++) {
      lut[i] = constrain((int)(0.5 + 255.0 * (((i / 255.0) * brightness - 0.5) * contrast + 0.5)), 0, 255);
    }

    return lut;
  }

  double lerp(double a, double b, double t) { 
    return a + t * (b - a);
  }

  PImage render(color background, double gamma, double cgamma, double color_mix, double brightness, double contrast, double saturation) {    
    int backg_r = (background >> 16) & 0xff;
    int backg_g = (background >> 8) & 0xff;
    int backg_b = background & 0xff;

    boolean do_saturation = saturation != 1.0;
    boolean do_bc = (brightness != 1.0) || (contrast != 1.0);
    boolean do_color_mix = color_mix > 0.0;
    boolean do_gamma = gamma != 1.0;

    double mx = 0;
    for (int i=0; i<weights.length; i++) {
      if (weights[i]>mx) mx=weights[i];
    }

    double lmx = Math.log(mx + 1.0);

    int[] bc_lut = calcBrightnessContrastLut(brightness, contrast);

    img.loadPixels();

    for (int i=0; i<weights.length; i++) {
      int rr, gg, bb;
      double weights_val = weights[i];
      // create clamped number of weights (no negative) for alpha
      double weights_val0 = weights_val < 0 ? 0.0 : weights_val;

      if (weights_val>0.0) {
        double alpha = do_gamma ? Math.pow(Math.log(weights_val0+1.0)/lmx, gamma) : Math.log(weights_val0+1.0)/lmx;

        // some reconstruction filters can give negative values
        // clamp them
        double fr = Math.min(Math.max(r[i]/weights_val, 0.0), 255.0);
        double fg = Math.min(Math.max(g[i]/weights_val, 0.0), 255.0);
        double fb = Math.min(Math.max(b[i]/weights_val, 0.0), 255.0);

        if (do_color_mix) {
          rr = (int)lerp(fr, 255.0*Math.pow(fr/255.0, cgamma), color_mix);
          gg = (int)lerp(fg, 255.0*Math.pow(fg/255.0, cgamma), color_mix);
          bb = (int)lerp(fb, 255.0*Math.pow(fb/255.0, cgamma), color_mix);
        } else {
          rr = (int)fr;
          gg = (int)fg;
          bb = (int)fb;
        }

        rr = (int)lerp(backg_r, rr, alpha);
        gg = (int)lerp(backg_g, gg, alpha);
        bb = (int)lerp(backg_b, bb, alpha);
      } else {
        rr = backg_r;
        gg = backg_g;
        bb = backg_b;
      }

      if (do_bc) {
        rr = bc_lut[rr];
        gg = bc_lut[gg];
        bb = bc_lut[bb];
      }

      if (do_saturation) {
        float[] hsb = Color.RGBtoHSB(rr, gg, bb, null);
        hsb[1] = (float)Math.min(Math.max(hsb[1]*saturation, 0.0), 1.0);
        img.pixels[i] = Color.HSBtoRGB(hsb[0], hsb[1], hsb[2]);
      } else {      
        img.pixels[i] = 0xff000000 | (rr << 16) | (gg << 8) | bb;
      }
    }

    img.updatePixels();
    return img;
  }
}

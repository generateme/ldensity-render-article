// Various reconstruction filters

public abstract class AFilter {
  public double radius, iradius, iradius16;
  public double[] filterTable = new double[16*16];

  protected void init() {
    double r = radius/16.0;
    int off=0;

    for (int x=0; x<16; x++) {
      for (int y=0; y<16; y++) {
        double px = (0.5 + x) * r;
        double py = (0.5 + y) * r;

        filterTable[off] = evaluate(px, py);
        off++;
      }
    }
  }

  public AFilter(double radius) {
    this.radius = radius<0.5?0.5:radius;
    iradius = 1.0 / radius;
    iradius16 = iradius * 16.0;
  }

  public abstract double evaluate(double x, double y);
}

public class Gaussian extends AFilter {
  double alpha;
  double expx, expy;

  public Gaussian(double radius, double alpha) {
    super(radius);
    this.alpha = alpha;

    expx = Math.exp(-alpha*radius*radius);
    expy = Math.exp(-alpha*radius*radius);
    init();
  }

  public Gaussian() {
    this(2.0, 2.0);
  }

  public double evaluate(double x, double y) {
    return Math.max(0, Math.exp(-alpha*x*x)-expx) * Math.max(0, Math.exp(-alpha*y*y)-expy);
  }
}

double sinc(double v) {
  double vv = Math.abs(v);
  if (vv<1.0e-5) return 1.0;
  double pv = Math.PI*vv;
  return Math.sin(pv)/pv;
}

public class Sinc extends AFilter {
  double tau;

  public Sinc(double radius, double tau) {
    super(radius);
    this.tau = tau;
    init();
  }

  public Sinc() {
    this(2.0, 2.0);
  }

  private double windowedSinc(double v, double r) {
    double vv = Math.abs(v);
    if (vv>r) return 0.0;
    return sinc(v)*sinc(v/tau);
  }

  public double evaluate(double x, double y) {
    return windowedSinc(x, radius)*windowedSinc(y, radius);
  }
}

public class Hann extends AFilter {
  double factor;

  public Hann(double radius, double factor) {
    super(radius);
    this.factor = 1.0/factor;
    init();
  }

  public Hann() {
    this(2.0,1.25);
  }

  private double hannSinc(double v) {
    double vv = Math.abs(v);
    if (vv>radius) return 0.0;
    return sinc(v)*(0.5+0.5*Math.cos(Math.PI*vv/radius));
  }

  public double evaluate(double x, double y) {
    return hannSinc(x*factor)*hannSinc(y*factor);
  }
}

public class BlackmanHarris extends AFilter {
  private final static double A0 =  0.35875;
  private final static double A1 = -0.48829;
  private final static double A2 =  0.14128;
  private final static double A3 = -0.01168;
  double factor;

  public BlackmanHarris(double radius, double factor) {
    super(radius);
    this.factor = 1.0/factor;
    init();
  }

  public BlackmanHarris() {
    this(2.0, 2.0);
  }

  private double BlackmanHarris1d(double x) {
    if (x < -1.0 || x > 1.0)
      return 0.0;
    x = (x + 1.0) * 0.5;
    x *= Math.PI;

    return A0 + A1 * Math.cos(2.0 * x) + A2 * Math.cos(4.0 * x) + A3 * Math.cos(6.0 * x);
  }

  public double evaluate(double x, double y) {
    return BlackmanHarris1d(x*factor) * BlackmanHarris1d(y*factor);
  }
}

public class Triangle extends AFilter {
  double factor;

  public Triangle(double radius, double factor) {
    super(radius);
    this.factor = 1.0/factor;
    init();
  }

  public Triangle() {
    this(2.0, 1.25);
  }

  public double evaluate(double x, double y) {
    return Math.max(0.0, (1.0-Math.abs(x*factor)))*Math.max(0.0, (1.0-Math.abs(y*factor)));
  }
}

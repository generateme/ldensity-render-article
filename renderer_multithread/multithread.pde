// how much cores we have?
int numberOfProcessors = Runtime.getRuntime().availableProcessors();
// thread pool
ExecutorService executor = Executors.newCachedThreadPool();

// Runner class is a wrapper for futures machinery
// Futures are threads which return values. 
//
// To use this class, follow:
// 1. Create instance of the class with external ExecutorService.
//    Type of the class should be type object returned by your task function
// 2. Add a number of tasks via addTask(). Task is a Callable class with call() function returning value.
// 3. Call run() to start execution
// 4. do other stuff
// 5. When you need values, call get() to get list of objects returned by Callable call function.
//    Futures are blocking. That means that your code will hand until all tasks are done.
// You can also call runAndGet() to combine points 3 and 5
class Runner<T> {
  ExecutorService pool;
  ArrayList<Callable<T>> tasks;
  List<Future<T>> futures;

  // initialize with pool of threads (ExecutorService class)
  Runner(ExecutorService pool) {
    this.pool = pool;

    tasks = new ArrayList<Callable<T>>();
  }

  // add task, do not run yet!
  void addTask(Callable<T> t) {
    tasks.add(t);
  }

  // clear your tasks and futures queue. Avoid calling this function.
  // Instead create another instance of Runner
  void clearTasks() {
    tasks.clear();
    if(futures != null) {
      for(Future f : futures) {
        if(!f.isDone()) {
          f.cancel(true);
        }
      }
      futures = null;
    }
  }

  // Run your tasks!
  List<Future<T>> run() throws InterruptedException {
    futures = pool.invokeAll(tasks);
    return futures;
  }

  // Get list of values returned by tasks. This call is blocking.
  List<T> get() throws InterruptedException, ExecutionException {
    if (futures == null) return null;
    ArrayList<T> values = new ArrayList<T>(futures.size());

    for (Future<T> f : futures) {
      values.add(f.get());
    }

    return values;
  }

  // just run and get values in one function call
  List<T> runAndGet() throws InterruptedException, ExecutionException {
    run();
    return get();
  }
}

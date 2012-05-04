public class LibTest {
  public static void main(String[] args) {
    System.out.println(">> " + System.getProperty("java.library.path"));
    try {
      System.loadLibrary("getenv");
      System.loadLibrary("toscomm");
    } catch(Exception ex) {
      ex.printStackTrace();
    }
  }
}



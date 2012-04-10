/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'SentMsg'
 * message type.
 */

public class SentMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 5;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 2;

    /** Create a new SentMsg of size 5. */
    public SentMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new SentMsg of the given data_length. */
    public SentMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg with the given data_length
     * and base offset.
     */
    public SentMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg using the given byte array
     * as backing store.
     */
    public SentMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public SentMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public SentMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg embedded in the given message
     * at the given base offset.
     */
    public SentMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SentMsg embedded in the given message
     * at the given base offset and length.
     */
    public SentMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <SentMsg> \n";
      try {
        s += "  [error=0x"+Long.toHexString(get_error())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [pkt_num=0x"+Long.toHexString(get_pkt_num())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [serial=0x"+Long.toHexString(get_serial())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: error
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'error' is signed (false).
     */
    public static boolean isSigned_error() {
        return false;
    }

    /**
     * Return whether the field 'error' is an array (false).
     */
    public static boolean isArray_error() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'error'
     */
    public static int offset_error() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'error'
     */
    public static int offsetBits_error() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'error'
     */
    public short get_error() {
        return (short)getUIntBEElement(offsetBits_error(), 8);
    }

    /**
     * Set the value of the field 'error'
     */
    public void set_error(short value) {
        setUIntBEElement(offsetBits_error(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'error'
     */
    public static int size_error() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'error'
     */
    public static int sizeBits_error() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: pkt_num
    //   Field type: int, unsigned
    //   Offset (bits): 8
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'pkt_num' is signed (false).
     */
    public static boolean isSigned_pkt_num() {
        return false;
    }

    /**
     * Return whether the field 'pkt_num' is an array (false).
     */
    public static boolean isArray_pkt_num() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'pkt_num'
     */
    public static int offset_pkt_num() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'pkt_num'
     */
    public static int offsetBits_pkt_num() {
        return 8;
    }

    /**
     * Return the value (as a int) of the field 'pkt_num'
     */
    public int get_pkt_num() {
        return (int)getUIntBEElement(offsetBits_pkt_num(), 16);
    }

    /**
     * Set the value of the field 'pkt_num'
     */
    public void set_pkt_num(int value) {
        setUIntBEElement(offsetBits_pkt_num(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'pkt_num'
     */
    public static int size_pkt_num() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'pkt_num'
     */
    public static int sizeBits_pkt_num() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: serial
    //   Field type: int, unsigned
    //   Offset (bits): 24
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'serial' is signed (false).
     */
    public static boolean isSigned_serial() {
        return false;
    }

    /**
     * Return whether the field 'serial' is an array (false).
     */
    public static boolean isArray_serial() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'serial'
     */
    public static int offset_serial() {
        return (24 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'serial'
     */
    public static int offsetBits_serial() {
        return 24;
    }

    /**
     * Return the value (as a int) of the field 'serial'
     */
    public int get_serial() {
        return (int)getUIntBEElement(offsetBits_serial(), 16);
    }

    /**
     * Set the value of the field 'serial'
     */
    public void set_serial(int value) {
        setUIntBEElement(offsetBits_serial(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'serial'
     */
    public static int size_serial() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'serial'
     */
    public static int sizeBits_serial() {
        return 16;
    }

}

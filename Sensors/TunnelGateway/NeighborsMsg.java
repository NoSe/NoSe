/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'NeighborsMsg'
 * message type.
 */

public class NeighborsMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 45;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 124;

    /** Create a new NeighborsMsg of size 45. */
    public NeighborsMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new NeighborsMsg of the given data_length. */
    public NeighborsMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg with the given data_length
     * and base offset.
     */
    public NeighborsMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg using the given byte array
     * as backing store.
     */
    public NeighborsMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public NeighborsMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public NeighborsMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg embedded in the given message
     * at the given base offset.
     */
    public NeighborsMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new NeighborsMsg embedded in the given message
     * at the given base offset and length.
     */
    public NeighborsMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <NeighborsMsg> \n";
      try {
        s += "  [length=0x"+Long.toHexString(get_length())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [node=";
        for (int i = 0; i < 22; i++) {
          s += "0x"+Long.toHexString(getElement_node(i) & 0xffff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: length
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'length' is signed (false).
     */
    public static boolean isSigned_length() {
        return false;
    }

    /**
     * Return whether the field 'length' is an array (false).
     */
    public static boolean isArray_length() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'length'
     */
    public static int offset_length() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'length'
     */
    public static int offsetBits_length() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'length'
     */
    public short get_length() {
        return (short)getUIntBEElement(offsetBits_length(), 8);
    }

    /**
     * Set the value of the field 'length'
     */
    public void set_length(short value) {
        setUIntBEElement(offsetBits_length(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'length'
     */
    public static int size_length() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'length'
     */
    public static int sizeBits_length() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: node
    //   Field type: int[], unsigned
    //   Offset (bits): 8
    //   Size of each element (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'node' is signed (false).
     */
    public static boolean isSigned_node() {
        return false;
    }

    /**
     * Return whether the field 'node' is an array (true).
     */
    public static boolean isArray_node() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'node'
     */
    public static int offset_node(int index1) {
        int offset = 8;
        if (index1 < 0 || index1 >= 22) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 16;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'node'
     */
    public static int offsetBits_node(int index1) {
        int offset = 8;
        if (index1 < 0 || index1 >= 22) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 16;
        return offset;
    }

    /**
     * Return the entire array 'node' as a int[]
     */
    public int[] get_node() {
        int[] tmp = new int[22];
        for (int index0 = 0; index0 < numElements_node(0); index0++) {
            tmp[index0] = getElement_node(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'node' from the given int[]
     */
    public void set_node(int[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_node(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a int) of the array 'node'
     */
    public int getElement_node(int index1) {
        return (int)getUIntBEElement(offsetBits_node(index1), 16);
    }

    /**
     * Set an element of the array 'node'
     */
    public void setElement_node(int index1, int value) {
        setUIntBEElement(offsetBits_node(index1), 16, value);
    }

    /**
     * Return the total size, in bytes, of the array 'node'
     */
    public static int totalSize_node() {
        return (352 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'node'
     */
    public static int totalSizeBits_node() {
        return 352;
    }

    /**
     * Return the size, in bytes, of each element of the array 'node'
     */
    public static int elementSize_node() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'node'
     */
    public static int elementSizeBits_node() {
        return 16;
    }

    /**
     * Return the number of dimensions in the array 'node'
     */
    public static int numDimensions_node() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'node'
     */
    public static int numElements_node() {
        return 22;
    }

    /**
     * Return the number of elements in the array 'node'
     * for the given dimension.
     */
    public static int numElements_node(int dimension) {
      int array_dims[] = { 22,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

}
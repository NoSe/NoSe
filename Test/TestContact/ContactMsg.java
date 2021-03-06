/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'ContactMsg'
 * message type.
 */

public class ContactMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 18;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 121;

    /** Create a new ContactMsg of size 18. */
    public ContactMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new ContactMsg of the given data_length. */
    public ContactMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg with the given data_length
     * and base offset.
     */
    public ContactMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg using the given byte array
     * as backing store.
     */
    public ContactMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public ContactMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public ContactMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg embedded in the given message
     * at the given base offset.
     */
    public ContactMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ContactMsg embedded in the given message
     * at the given base offset and length.
     */
    public ContactMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <ContactMsg> \n";
      try {
        s += "  [time_stamp_m=0x"+Long.toHexString(get_time_stamp_m())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [time_stamp_l=0x"+Long.toHexString(get_time_stamp_l())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [source=0x"+Long.toHexString(get_source())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [neigh_ID=0x"+Long.toHexString(get_neigh_ID())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [pkt_ID=0x"+Long.toHexString(get_pkt_ID())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [rssi=0x"+Long.toHexString(get_rssi())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [lqi=0x"+Long.toHexString(get_lqi())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [channel_ID=0x"+Long.toHexString(get_channel_ID())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [pot=0x"+Long.toHexString(get_pot())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [len=0x"+Long.toHexString(get_len())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: time_stamp_m
    //   Field type: int, unsigned
    //   Offset (bits): 0
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'time_stamp_m' is signed (false).
     */
    public static boolean isSigned_time_stamp_m() {
        return false;
    }

    /**
     * Return whether the field 'time_stamp_m' is an array (false).
     */
    public static boolean isArray_time_stamp_m() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'time_stamp_m'
     */
    public static int offset_time_stamp_m() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'time_stamp_m'
     */
    public static int offsetBits_time_stamp_m() {
        return 0;
    }

    /**
     * Return the value (as a int) of the field 'time_stamp_m'
     */
    public int get_time_stamp_m() {
        return (int)getSIntBEElement(offsetBits_time_stamp_m(), 32);
    }

    /**
     * Set the value of the field 'time_stamp_m'
     */
    public void set_time_stamp_m(int value) {
        setSIntBEElement(offsetBits_time_stamp_m(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'time_stamp_m'
     */
    public static int size_time_stamp_m() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'time_stamp_m'
     */
    public static int sizeBits_time_stamp_m() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: time_stamp_l
    //   Field type: int, unsigned
    //   Offset (bits): 32
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'time_stamp_l' is signed (false).
     */
    public static boolean isSigned_time_stamp_l() {
        return false;
    }

    /**
     * Return whether the field 'time_stamp_l' is an array (false).
     */
    public static boolean isArray_time_stamp_l() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'time_stamp_l'
     */
    public static int offset_time_stamp_l() {
        return (32 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'time_stamp_l'
     */
    public static int offsetBits_time_stamp_l() {
        return 32;
    }

    /**
     * Return the value (as a int) of the field 'time_stamp_l'
     */
    public int get_time_stamp_l() {
        return (int)getSIntBEElement(offsetBits_time_stamp_l(), 32);
    }

    /**
     * Set the value of the field 'time_stamp_l'
     */
    public void set_time_stamp_l(int value) {
        setSIntBEElement(offsetBits_time_stamp_l(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'time_stamp_l'
     */
    public static int size_time_stamp_l() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'time_stamp_l'
     */
    public static int sizeBits_time_stamp_l() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: source
    //   Field type: int, unsigned
    //   Offset (bits): 64
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'source' is signed (false).
     */
    public static boolean isSigned_source() {
        return false;
    }

    /**
     * Return whether the field 'source' is an array (false).
     */
    public static boolean isArray_source() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'source'
     */
    public static int offset_source() {
        return (64 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'source'
     */
    public static int offsetBits_source() {
        return 64;
    }

    /**
     * Return the value (as a int) of the field 'source'
     */
    public int get_source() {
        return (int)getUIntBEElement(offsetBits_source(), 16);
    }

    /**
     * Set the value of the field 'source'
     */
    public void set_source(int value) {
        setUIntBEElement(offsetBits_source(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'source'
     */
    public static int size_source() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'source'
     */
    public static int sizeBits_source() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: neigh_ID
    //   Field type: int, unsigned
    //   Offset (bits): 80
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'neigh_ID' is signed (false).
     */
    public static boolean isSigned_neigh_ID() {
        return false;
    }

    /**
     * Return whether the field 'neigh_ID' is an array (false).
     */
    public static boolean isArray_neigh_ID() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'neigh_ID'
     */
    public static int offset_neigh_ID() {
        return (80 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'neigh_ID'
     */
    public static int offsetBits_neigh_ID() {
        return 80;
    }

    /**
     * Return the value (as a int) of the field 'neigh_ID'
     */
    public int get_neigh_ID() {
        return (int)getUIntBEElement(offsetBits_neigh_ID(), 16);
    }

    /**
     * Set the value of the field 'neigh_ID'
     */
    public void set_neigh_ID(int value) {
        setUIntBEElement(offsetBits_neigh_ID(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'neigh_ID'
     */
    public static int size_neigh_ID() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'neigh_ID'
     */
    public static int sizeBits_neigh_ID() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: pkt_ID
    //   Field type: short, unsigned
    //   Offset (bits): 96
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'pkt_ID' is signed (false).
     */
    public static boolean isSigned_pkt_ID() {
        return false;
    }

    /**
     * Return whether the field 'pkt_ID' is an array (false).
     */
    public static boolean isArray_pkt_ID() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'pkt_ID'
     */
    public static int offset_pkt_ID() {
        return (96 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'pkt_ID'
     */
    public static int offsetBits_pkt_ID() {
        return 96;
    }

    /**
     * Return the value (as a short) of the field 'pkt_ID'
     */
    public short get_pkt_ID() {
        return (short)getUIntBEElement(offsetBits_pkt_ID(), 8);
    }

    /**
     * Set the value of the field 'pkt_ID'
     */
    public void set_pkt_ID(short value) {
        setUIntBEElement(offsetBits_pkt_ID(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'pkt_ID'
     */
    public static int size_pkt_ID() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'pkt_ID'
     */
    public static int sizeBits_pkt_ID() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: rssi
    //   Field type: short, unsigned
    //   Offset (bits): 104
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'rssi' is signed (false).
     */
    public static boolean isSigned_rssi() {
        return false;
    }

    /**
     * Return whether the field 'rssi' is an array (false).
     */
    public static boolean isArray_rssi() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'rssi'
     */
    public static int offset_rssi() {
        return (104 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'rssi'
     */
    public static int offsetBits_rssi() {
        return 104;
    }

    /**
     * Return the value (as a short) of the field 'rssi'
     */
    public short get_rssi() {
        return (short)getUIntBEElement(offsetBits_rssi(), 8);
    }

    /**
     * Set the value of the field 'rssi'
     */
    public void set_rssi(short value) {
        setUIntBEElement(offsetBits_rssi(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'rssi'
     */
    public static int size_rssi() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'rssi'
     */
    public static int sizeBits_rssi() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: lqi
    //   Field type: short, unsigned
    //   Offset (bits): 112
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'lqi' is signed (false).
     */
    public static boolean isSigned_lqi() {
        return false;
    }

    /**
     * Return whether the field 'lqi' is an array (false).
     */
    public static boolean isArray_lqi() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'lqi'
     */
    public static int offset_lqi() {
        return (112 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'lqi'
     */
    public static int offsetBits_lqi() {
        return 112;
    }

    /**
     * Return the value (as a short) of the field 'lqi'
     */
    public short get_lqi() {
        return (short)getUIntBEElement(offsetBits_lqi(), 8);
    }

    /**
     * Set the value of the field 'lqi'
     */
    public void set_lqi(short value) {
        setUIntBEElement(offsetBits_lqi(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'lqi'
     */
    public static int size_lqi() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'lqi'
     */
    public static int sizeBits_lqi() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: channel_ID
    //   Field type: short, unsigned
    //   Offset (bits): 120
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'channel_ID' is signed (false).
     */
    public static boolean isSigned_channel_ID() {
        return false;
    }

    /**
     * Return whether the field 'channel_ID' is an array (false).
     */
    public static boolean isArray_channel_ID() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'channel_ID'
     */
    public static int offset_channel_ID() {
        return (120 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'channel_ID'
     */
    public static int offsetBits_channel_ID() {
        return 120;
    }

    /**
     * Return the value (as a short) of the field 'channel_ID'
     */
    public short get_channel_ID() {
        return (short)getUIntBEElement(offsetBits_channel_ID(), 8);
    }

    /**
     * Set the value of the field 'channel_ID'
     */
    public void set_channel_ID(short value) {
        setUIntBEElement(offsetBits_channel_ID(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'channel_ID'
     */
    public static int size_channel_ID() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'channel_ID'
     */
    public static int sizeBits_channel_ID() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: pot
    //   Field type: short, unsigned
    //   Offset (bits): 128
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'pot' is signed (false).
     */
    public static boolean isSigned_pot() {
        return false;
    }

    /**
     * Return whether the field 'pot' is an array (false).
     */
    public static boolean isArray_pot() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'pot'
     */
    public static int offset_pot() {
        return (128 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'pot'
     */
    public static int offsetBits_pot() {
        return 128;
    }

    /**
     * Return the value (as a short) of the field 'pot'
     */
    public short get_pot() {
        return (short)getUIntBEElement(offsetBits_pot(), 8);
    }

    /**
     * Set the value of the field 'pot'
     */
    public void set_pot(short value) {
        setUIntBEElement(offsetBits_pot(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'pot'
     */
    public static int size_pot() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'pot'
     */
    public static int sizeBits_pot() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: len
    //   Field type: short, unsigned
    //   Offset (bits): 136
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'len' is signed (false).
     */
    public static boolean isSigned_len() {
        return false;
    }

    /**
     * Return whether the field 'len' is an array (false).
     */
    public static boolean isArray_len() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'len'
     */
    public static int offset_len() {
        return (136 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'len'
     */
    public static int offsetBits_len() {
        return 136;
    }

    /**
     * Return the value (as a short) of the field 'len'
     */
    public short get_len() {
        return (short)getUIntBEElement(offsetBits_len(), 8);
    }

    /**
     * Set the value of the field 'len'
     */
    public void set_len(short value) {
        setUIntBEElement(offsetBits_len(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'len'
     */
    public static int size_len() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'len'
     */
    public static int sizeBits_len() {
        return 8;
    }

}

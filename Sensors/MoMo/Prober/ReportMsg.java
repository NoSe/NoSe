/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'ReportMsg'
 * message type.
 */

public class ReportMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 14;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 1;

    /** Create a new ReportMsg of size 14. */
    public ReportMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new ReportMsg of the given data_length. */
    public ReportMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg with the given data_length
     * and base offset.
     */
    public ReportMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg using the given byte array
     * as backing store.
     */
    public ReportMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public ReportMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public ReportMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg embedded in the given message
     * at the given base offset.
     */
    public ReportMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new ReportMsg embedded in the given message
     * at the given base offset and length.
     */
    public ReportMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <ReportMsg> \n";
      try {
        s += "  [data.cmd_type_=0x"+Long.toHexString(get_data_cmd_type_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data.sample_=0x"+Long.toHexString(get_data_sample_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data.pkt_num_=0x"+Long.toHexString(get_data_pkt_num_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data.serial_=0x"+Long.toHexString(get_data_serial_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data.age_=0x"+Long.toHexString(get_data_age_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.version_=0x"+Long.toHexString(get_ctrl_version_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.cmd_type_=0x"+Long.toHexString(get_ctrl_cmd_type_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.lpl_duty_=0x"+Long.toHexString(get_ctrl_lpl_duty_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.threshold_=0x"+Long.toHexString(get_ctrl_threshold_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.sampling_p_=0x"+Long.toHexString(get_ctrl_sampling_p_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [ctrl.collecting_p_=0x"+Long.toHexString(get_ctrl_collecting_p_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [join.sink_id_=0x"+Long.toHexString(get_join_sink_id_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [join.node_id_=0x"+Long.toHexString(get_join_node_id_())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data.cmd_type_
    //   Field type: short
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data.cmd_type_' is signed (false).
     */
    public static boolean isSigned_data_cmd_type_() {
        return false;
    }

    /**
     * Return whether the field 'data.cmd_type_' is an array (false).
     */
    public static boolean isArray_data_cmd_type_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'data.cmd_type_'
     */
    public static int offset_data_cmd_type_() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data.cmd_type_'
     */
    public static int offsetBits_data_cmd_type_() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'data.cmd_type_'
     */
    public short get_data_cmd_type_() {
        return (short)getUIntBEElement(offsetBits_data_cmd_type_(), 8);
    }

    /**
     * Set the value of the field 'data.cmd_type_'
     */
    public void set_data_cmd_type_(short value) {
        setUIntBEElement(offsetBits_data_cmd_type_(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'data.cmd_type_'
     */
    public static int size_data_cmd_type_() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'data.cmd_type_'
     */
    public static int sizeBits_data_cmd_type_() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data.sample_
    //   Field type: int
    //   Offset (bits): 8
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data.sample_' is signed (false).
     */
    public static boolean isSigned_data_sample_() {
        return false;
    }

    /**
     * Return whether the field 'data.sample_' is an array (false).
     */
    public static boolean isArray_data_sample_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'data.sample_'
     */
    public static int offset_data_sample_() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data.sample_'
     */
    public static int offsetBits_data_sample_() {
        return 8;
    }

    /**
     * Return the value (as a int) of the field 'data.sample_'
     */
    public int get_data_sample_() {
        return (int)getUIntBEElement(offsetBits_data_sample_(), 16);
    }

    /**
     * Set the value of the field 'data.sample_'
     */
    public void set_data_sample_(int value) {
        setUIntBEElement(offsetBits_data_sample_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'data.sample_'
     */
    public static int size_data_sample_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'data.sample_'
     */
    public static int sizeBits_data_sample_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data.pkt_num_
    //   Field type: int
    //   Offset (bits): 24
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data.pkt_num_' is signed (false).
     */
    public static boolean isSigned_data_pkt_num_() {
        return false;
    }

    /**
     * Return whether the field 'data.pkt_num_' is an array (false).
     */
    public static boolean isArray_data_pkt_num_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'data.pkt_num_'
     */
    public static int offset_data_pkt_num_() {
        return (24 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data.pkt_num_'
     */
    public static int offsetBits_data_pkt_num_() {
        return 24;
    }

    /**
     * Return the value (as a int) of the field 'data.pkt_num_'
     */
    public int get_data_pkt_num_() {
        return (int)getUIntBEElement(offsetBits_data_pkt_num_(), 16);
    }

    /**
     * Set the value of the field 'data.pkt_num_'
     */
    public void set_data_pkt_num_(int value) {
        setUIntBEElement(offsetBits_data_pkt_num_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'data.pkt_num_'
     */
    public static int size_data_pkt_num_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'data.pkt_num_'
     */
    public static int sizeBits_data_pkt_num_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data.serial_
    //   Field type: int
    //   Offset (bits): 40
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data.serial_' is signed (false).
     */
    public static boolean isSigned_data_serial_() {
        return false;
    }

    /**
     * Return whether the field 'data.serial_' is an array (false).
     */
    public static boolean isArray_data_serial_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'data.serial_'
     */
    public static int offset_data_serial_() {
        return (40 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data.serial_'
     */
    public static int offsetBits_data_serial_() {
        return 40;
    }

    /**
     * Return the value (as a int) of the field 'data.serial_'
     */
    public int get_data_serial_() {
        return (int)getUIntBEElement(offsetBits_data_serial_(), 16);
    }

    /**
     * Set the value of the field 'data.serial_'
     */
    public void set_data_serial_(int value) {
        setUIntBEElement(offsetBits_data_serial_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'data.serial_'
     */
    public static int size_data_serial_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'data.serial_'
     */
    public static int sizeBits_data_serial_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data.age_
    //   Field type: long
    //   Offset (bits): 56
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data.age_' is signed (false).
     */
    public static boolean isSigned_data_age_() {
        return false;
    }

    /**
     * Return whether the field 'data.age_' is an array (false).
     */
    public static boolean isArray_data_age_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'data.age_'
     */
    public static int offset_data_age_() {
        return (56 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data.age_'
     */
    public static int offsetBits_data_age_() {
        return 56;
    }

    /**
     * Return the value (as a long) of the field 'data.age_'
     */
    public long get_data_age_() {
        return (long)getUIntBEElement(offsetBits_data_age_(), 32);
    }

    /**
     * Set the value of the field 'data.age_'
     */
    public void set_data_age_(long value) {
        setUIntBEElement(offsetBits_data_age_(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'data.age_'
     */
    public static int size_data_age_() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'data.age_'
     */
    public static int sizeBits_data_age_() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.version_
    //   Field type: short
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.version_' is signed (false).
     */
    public static boolean isSigned_ctrl_version_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.version_' is an array (false).
     */
    public static boolean isArray_ctrl_version_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.version_'
     */
    public static int offset_ctrl_version_() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.version_'
     */
    public static int offsetBits_ctrl_version_() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'ctrl.version_'
     */
    public short get_ctrl_version_() {
        return (short)getUIntBEElement(offsetBits_ctrl_version_(), 8);
    }

    /**
     * Set the value of the field 'ctrl.version_'
     */
    public void set_ctrl_version_(short value) {
        setUIntBEElement(offsetBits_ctrl_version_(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.version_'
     */
    public static int size_ctrl_version_() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.version_'
     */
    public static int sizeBits_ctrl_version_() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.cmd_type_
    //   Field type: short
    //   Offset (bits): 8
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.cmd_type_' is signed (false).
     */
    public static boolean isSigned_ctrl_cmd_type_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.cmd_type_' is an array (false).
     */
    public static boolean isArray_ctrl_cmd_type_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.cmd_type_'
     */
    public static int offset_ctrl_cmd_type_() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.cmd_type_'
     */
    public static int offsetBits_ctrl_cmd_type_() {
        return 8;
    }

    /**
     * Return the value (as a short) of the field 'ctrl.cmd_type_'
     */
    public short get_ctrl_cmd_type_() {
        return (short)getUIntBEElement(offsetBits_ctrl_cmd_type_(), 8);
    }

    /**
     * Set the value of the field 'ctrl.cmd_type_'
     */
    public void set_ctrl_cmd_type_(short value) {
        setUIntBEElement(offsetBits_ctrl_cmd_type_(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.cmd_type_'
     */
    public static int size_ctrl_cmd_type_() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.cmd_type_'
     */
    public static int sizeBits_ctrl_cmd_type_() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.lpl_duty_
    //   Field type: int
    //   Offset (bits): 16
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.lpl_duty_' is signed (false).
     */
    public static boolean isSigned_ctrl_lpl_duty_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.lpl_duty_' is an array (false).
     */
    public static boolean isArray_ctrl_lpl_duty_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.lpl_duty_'
     */
    public static int offset_ctrl_lpl_duty_() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.lpl_duty_'
     */
    public static int offsetBits_ctrl_lpl_duty_() {
        return 16;
    }

    /**
     * Return the value (as a int) of the field 'ctrl.lpl_duty_'
     */
    public int get_ctrl_lpl_duty_() {
        return (int)getUIntBEElement(offsetBits_ctrl_lpl_duty_(), 16);
    }

    /**
     * Set the value of the field 'ctrl.lpl_duty_'
     */
    public void set_ctrl_lpl_duty_(int value) {
        setUIntBEElement(offsetBits_ctrl_lpl_duty_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.lpl_duty_'
     */
    public static int size_ctrl_lpl_duty_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.lpl_duty_'
     */
    public static int sizeBits_ctrl_lpl_duty_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.threshold_
    //   Field type: int
    //   Offset (bits): 32
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.threshold_' is signed (false).
     */
    public static boolean isSigned_ctrl_threshold_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.threshold_' is an array (false).
     */
    public static boolean isArray_ctrl_threshold_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.threshold_'
     */
    public static int offset_ctrl_threshold_() {
        return (32 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.threshold_'
     */
    public static int offsetBits_ctrl_threshold_() {
        return 32;
    }

    /**
     * Return the value (as a int) of the field 'ctrl.threshold_'
     */
    public int get_ctrl_threshold_() {
        return (int)getUIntBEElement(offsetBits_ctrl_threshold_(), 16);
    }

    /**
     * Set the value of the field 'ctrl.threshold_'
     */
    public void set_ctrl_threshold_(int value) {
        setUIntBEElement(offsetBits_ctrl_threshold_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.threshold_'
     */
    public static int size_ctrl_threshold_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.threshold_'
     */
    public static int sizeBits_ctrl_threshold_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.sampling_p_
    //   Field type: long
    //   Offset (bits): 48
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.sampling_p_' is signed (false).
     */
    public static boolean isSigned_ctrl_sampling_p_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.sampling_p_' is an array (false).
     */
    public static boolean isArray_ctrl_sampling_p_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.sampling_p_'
     */
    public static int offset_ctrl_sampling_p_() {
        return (48 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.sampling_p_'
     */
    public static int offsetBits_ctrl_sampling_p_() {
        return 48;
    }

    /**
     * Return the value (as a long) of the field 'ctrl.sampling_p_'
     */
    public long get_ctrl_sampling_p_() {
        return (long)getUIntBEElement(offsetBits_ctrl_sampling_p_(), 32);
    }

    /**
     * Set the value of the field 'ctrl.sampling_p_'
     */
    public void set_ctrl_sampling_p_(long value) {
        setUIntBEElement(offsetBits_ctrl_sampling_p_(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.sampling_p_'
     */
    public static int size_ctrl_sampling_p_() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.sampling_p_'
     */
    public static int sizeBits_ctrl_sampling_p_() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: ctrl.collecting_p_
    //   Field type: long
    //   Offset (bits): 80
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'ctrl.collecting_p_' is signed (false).
     */
    public static boolean isSigned_ctrl_collecting_p_() {
        return false;
    }

    /**
     * Return whether the field 'ctrl.collecting_p_' is an array (false).
     */
    public static boolean isArray_ctrl_collecting_p_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'ctrl.collecting_p_'
     */
    public static int offset_ctrl_collecting_p_() {
        return (80 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'ctrl.collecting_p_'
     */
    public static int offsetBits_ctrl_collecting_p_() {
        return 80;
    }

    /**
     * Return the value (as a long) of the field 'ctrl.collecting_p_'
     */
    public long get_ctrl_collecting_p_() {
        return (long)getUIntBEElement(offsetBits_ctrl_collecting_p_(), 32);
    }

    /**
     * Set the value of the field 'ctrl.collecting_p_'
     */
    public void set_ctrl_collecting_p_(long value) {
        setUIntBEElement(offsetBits_ctrl_collecting_p_(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'ctrl.collecting_p_'
     */
    public static int size_ctrl_collecting_p_() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'ctrl.collecting_p_'
     */
    public static int sizeBits_ctrl_collecting_p_() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: join.sink_id_
    //   Field type: int
    //   Offset (bits): 0
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'join.sink_id_' is signed (false).
     */
    public static boolean isSigned_join_sink_id_() {
        return false;
    }

    /**
     * Return whether the field 'join.sink_id_' is an array (false).
     */
    public static boolean isArray_join_sink_id_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'join.sink_id_'
     */
    public static int offset_join_sink_id_() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'join.sink_id_'
     */
    public static int offsetBits_join_sink_id_() {
        return 0;
    }

    /**
     * Return the value (as a int) of the field 'join.sink_id_'
     */
    public int get_join_sink_id_() {
        return (int)getUIntBEElement(offsetBits_join_sink_id_(), 16);
    }

    /**
     * Set the value of the field 'join.sink_id_'
     */
    public void set_join_sink_id_(int value) {
        setUIntBEElement(offsetBits_join_sink_id_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'join.sink_id_'
     */
    public static int size_join_sink_id_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'join.sink_id_'
     */
    public static int sizeBits_join_sink_id_() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: join.node_id_
    //   Field type: int
    //   Offset (bits): 16
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'join.node_id_' is signed (false).
     */
    public static boolean isSigned_join_node_id_() {
        return false;
    }

    /**
     * Return whether the field 'join.node_id_' is an array (false).
     */
    public static boolean isArray_join_node_id_() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'join.node_id_'
     */
    public static int offset_join_node_id_() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'join.node_id_'
     */
    public static int offsetBits_join_node_id_() {
        return 16;
    }

    /**
     * Return the value (as a int) of the field 'join.node_id_'
     */
    public int get_join_node_id_() {
        return (int)getUIntBEElement(offsetBits_join_node_id_(), 16);
    }

    /**
     * Set the value of the field 'join.node_id_'
     */
    public void set_join_node_id_(int value) {
        setUIntBEElement(offsetBits_join_node_id_(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'join.node_id_'
     */
    public static int size_join_node_id_() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'join.node_id_'
     */
    public static int sizeBits_join_node_id_() {
        return 16;
    }

}

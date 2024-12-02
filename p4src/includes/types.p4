// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP  0x0806

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_IPV4   4
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17

#define UDP_PORT_HEIMDALL 5450
#define CPU_PORT 320

typedef PortId_t switch_port_t;
typedef bit<1>  ingress_port_type;
const ingress_port_type INGRESS_PORT_TYPE_DL = 0;
const ingress_port_type INGRESS_PORT_TYPE_UL = 1;

// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------
#define MIN_TABLE_SIZE 512

// Bloom filter size
#define BLOOM_FILTER_CELL_SIZE 8
#define BLOOM_FILTER_IDX_WIDTH 17
#define BLOOM_FILTER_SIZE 1 << (BLOOM_FILTER_IDX_WIDTH)

// Up to 4294967296 users supported by the system
#define SESSION_ID_WIDTH 32
#define MAX_NUM_USERS 1 << (SESSION_ID_WIDTH)

// Up to 65536 users in the HAG
#define REGISTER_IDX_WIDTH 16
#define NUM_USERS 1 << (REGISTER_IDX_WIDTH)         

// Up to 16384 split rules 
#define SPLIT_USER_IDX_WIDTH 14
#define NUM_SPLIT_USERS (1 << SPLIT_USER_IDX_WIDTH)

// Nexthop --------------------------------------------------------------------
typedef bit<2> switch_nexthop_type_t;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_IP = 0;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_TUNNEL_ENCAP = 1;

// Heimdall  --------------------------------------------------------------------
typedef bit<2> heimdall_direction_t;
const heimdall_direction_t HEIMDALL_TYPE_UPLINK = 1;
const heimdall_direction_t HEIMDALL_TYPE_DOWNLINK = 2;

typedef bit<BLOOM_FILTER_IDX_WIDTH> heimdall_bf_hash_idx_t;
typedef bit<BLOOM_FILTER_CELL_SIZE> heimdall_bf_res_t;

typedef bit<32> heimdall_pkt_seq_t;
typedef bit<SESSION_ID_WIDTH> heimdall_session_t;
typedef bit<REGISTER_IDX_WIDTH> heimdall_assigned_idx_t;

typedef bit<2>  heimdall_policy_t;
const heimdall_policy_t HEIMDALL_POLICY_SWITCH = 0;     // switch is similar to "static" steering
const heimdall_policy_t HEIMDALL_POLICY_STEER = 1;      // steer is similar to "dynamic" steering
const heimdall_policy_t HEIMDALL_POLICY_SPLIT = 2;      // split is only available to specific traffic

typedef bool heimdall_policy_override_t;

typedef bit<4>  heimdall_policy_action_t;
const heimdall_policy_action_t HEIMDALL_SWITCH_PRIMARY_3GPP = 0;
const heimdall_policy_action_t HEIMDALL_SWITCH_PRIMARY_N3GPP = 1;

const heimdall_policy_action_t HEIMDALL_STEER_MIN_RTT = 0;
const heimdall_policy_action_t HEIMDALL_STEER_MIN_PLR = 1;

const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_3GPP = 0;         // meter split; overflow to N3GPP
const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_3GPP_LB = 1;      // 50:50 split
const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28 = 2;   // 20:80 split

const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_N3GPP = 8;        // meter split; overflow to N3GPP
const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_N3GPP_LB = 9;     // 50:50 split
const heimdall_policy_action_t HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28 = 10; // 20:80 split

// typedef bit<32> heimdall_split_assigned_idx_t;
// typedef bit<32> heimdall_split_meter_idx_t;
typedef bit<SPLIT_USER_IDX_WIDTH> heimdall_split_assigned_idx_t;
typedef bit<8> heimdall_split_meter_color_t;
typedef bit<2> heimdall_split_primary_t;
const heimdall_split_primary_t HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP = 1;
const heimdall_split_primary_t HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP = 2;
typedef bit<2> heimdall_split_type_t;
const heimdall_split_type_t HEIMDALL_SPLIT_TYPE_METER = 1;
const heimdall_split_type_t HEIMDALL_SPLIT_TYPE_LB = 2;

typedef bit<8> heimdall_path_weights_t;

struct heimdall_downlink_dest_t {
    ipv4_addr_t downlink_3gpp;
    ipv4_addr_t downlink_n3gpp;
}
typedef bit<2> heimdall_downlink_avail_t;
const heimdall_downlink_avail_t HEIMDALL_DOWNLINK_AVAIL_NONE = 0;
const heimdall_downlink_avail_t HEIMDALL_DOWNLINK_AVAIL_3GPP = 1;
const heimdall_downlink_avail_t HEIMDALL_DOWNLINK_AVAIL_N3GPP = 2;
const heimdall_downlink_avail_t HEIMDALL_DOWNLINK_AVAIL_BOTH = 3;

typedef bool heimdall_is_multipath_t;

typedef bit<2> heimdall_downlink_choice_t;
const heimdall_downlink_choice_t HEIMDALL_DL_CHOICE_TYPE_INVALID = 0;
const heimdall_downlink_choice_t HEIMDALL_DL_CHOICE_TYPE_3GPP = 1;
const heimdall_downlink_choice_t HEIMDALL_DL_CHOICE_TYPE_N3GPP = 2;

struct heimdall_downlink_options_t {
    heimdall_downlink_dest_t dl_destinations;

    heimdall_downlink_avail_t dl_avail;
    heimdall_downlink_avail_t is_3gpp_avail;
    heimdall_downlink_avail_t is_n3gpp_avail;

    heimdall_path_weights_t path_weight_3gpp;
    heimdall_path_weights_t path_weight_n3gpp;

    heimdall_is_multipath_t is_multipath;

    /* used for SPLIT only */
    heimdall_split_assigned_idx_t split_assigned_idx;
    heimdall_split_type_t split_type;
    heimdall_split_primary_t  split_primary;
    heimdall_split_meter_color_t split_meter_color;
    
    heimdall_downlink_choice_t dl_choice;
}

typedef bit<1>  heimdall_uplink_options_t;
const heimdall_uplink_options_t HEIMDALL_UL_OPTIONS_NORMAL = 0;
const heimdall_uplink_options_t HEIMDALL_UL_OPTIONS_REORDER = 1;

typedef bit<16> num_reorder_users_t;

struct heimdall_ingress_metadata_t {
    heimdall_direction_t dir;           // UL, DL           
    
    heimdall_session_t  sess_id;        // consider session token rotation -- see SPINE
    heimdall_bf_hash_idx_t hash_idx0;
    heimdall_bf_hash_idx_t hash_idx1;
    heimdall_bf_res_t bf_res0;
    heimdall_bf_res_t bf_res1;

    heimdall_pkt_seq_t  pkt_seq_num;    // packet sequence number
    heimdall_assigned_idx_t assigned_idx;

    heimdall_policy_override_t policy_override;
    heimdall_policy_t policy;
    heimdall_policy_action_t policy_action;
    
    heimdall_uplink_options_t ul_options;
    heimdall_downlink_options_t dl_options;    
}

struct heimdall_egress_metadata_t {
    // TODO
}

// Local Metadata  --------------------------------------------------------------------
struct switch_local_metadata_t {
    ingress_port_type traffic_direction;
    switch_port_t ingress_port;
    switch_port_t egress_port;

    bool    reject_pkt; 
    bool    to_cpu;
    bool    checksum_upd_ipv4;


    bit<8>  l3_proto;
    bit<32> l3_src_addr;
    bit<32> l3_dst_addr;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

    bit<32> src_addr;
    bit<32> dst_addr;

    heimdall_ingress_metadata_t heimdall;
    switch_nexthop_type_t nexthop;    

    // reorder
#ifdef REORDER
    num_reorder_users_t reorder_idx;
    bool    is_tail;
    bool    bypass_reorder;
    bit<32> reorder_epoch;
    bit<4>  queue_table_idx0;
    bit<32> queue_matched0;
    bit<4>  queue_table_idx1;
    bit<32> queue_matched1;
    bit<7>  queue_idx;
#endif
}

header switch_bridged_metadata_h {
    // TODO
}

struct switch_header_t {
    switch_bridged_metadata_h bridge;
    ethernet_h ethernet;
    arp_h arp;
    ipv4_h ipv4;
    udp_h udp;
    tcp_h tcp;
    heimdall_h heimdall;
    ipv4_h inner_ipv4;
    icmp_h inner_icmp;
    udp_h inner_udp;
    tcp_h inner_tcp;
}   

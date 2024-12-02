#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "includes/headers.p4"
#include "includes/types.p4"
#include "includes/parde.p4"

#include "includes/tunnel.p4"

control SwitchIngress(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    HeimdallEncap() heimdall_encap;
    HeimdallDecap() heimdall_decap;

    action drop() {
        ig_dprsr_md.drop_ctl = 0x01;
    }
    
    // IPv4 Forward --------------------------------------------------------------------
    action ipv4_forward_action(bit<9> port) {
        ig_tm_md.ucast_egress_port = port;
    }
        
    table ipv4_forward {
        key = {
            local_md.dst_addr : lpm;
        }
        actions = {
            NoAction;
            ipv4_forward_action;
        }
        default_action = NoAction;
    }

    // Write Dest. MAC --------------------------------------------------------------------
    action dest_mac_write_action(bit<48> dest_mac) {
        hdr.ethernet.dst_addr = dest_mac;
    }

    table dest_mac_write {
        key = {
            ig_tm_md.ucast_egress_port : exact;
        }
        actions = {
            dest_mac_write_action;
            NoAction;
        }
        default_action = NoAction();
    }


    // Mark Ingress Port  --------------------------------------------------------------------
    action mark_ingress_port_action(ingress_port_type type) {
        local_md.traffic_direction = type;
    }

    table mark_ingress_port {
        key = {
            local_md.ingress_port : exact;
        }
        actions = {
            mark_ingress_port_action;
            drop;
        }
        // Example
        // const entries = {
        //     0 : mark_ingress_port_action(INGRESS_PORT_TYPE_UL);
        //     8 : mark_ingress_port_action(INGRESS_PORT_TYPE_DL);
        // }
        default_action = drop();
        size = MIN_TABLE_SIZE;
    }

    // Mark Heimdall UL/DL --------------------------------------------------------------------
    action mark_heimdall_ul_action() {
        local_md.heimdall.dir = HEIMDALL_TYPE_UPLINK;
    }

    action mark_heimdall_dl_action() {
        local_md.heimdall.dir = HEIMDALL_TYPE_DOWNLINK;
    }

    table mark_heimdall_ul_dl {
        key = {
            /* INGRESS_PORT_TYPE_UL = 1 */
            (local_md.traffic_direction & (bit<1>) hdr.heimdall.isValid()) : exact @name("uplink_with_heimdall");
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
        }
        actions = {
            NoAction;
            mark_heimdall_dl_action;
            mark_heimdall_ul_action;
        }
        // Example
        // const entries = {
        //     (1, (0xac100000 & 0xfff00000), (0xac1ffffe & 0xffffffff)) : mark_heimdall_ul_action();      // UL originated from 172.16.0.0/12; destined to 172.31.255.255/12
        //     (1, (0xc0a80000 & 0xffff0000), (0xc0a8fffe & 0xffffffff)) : mark_heimdall_ul_action();      // UL originated from 192.168.0.0/16; destined to 192.168.255.255/16                             
        //     (0, _, (0x0a000000 & 0xff000000)) : mark_heimdall_dl_action();    // DL destined to 10.0.0.0/8; originated from INTERNET        
        // }
        default_action = NoAction();
        size = MIN_TABLE_SIZE;
    }

    // Heimdall UL Verify Session -------------------------------------------------------------------    
    // NOTE: This is updated by the control plane only.
    Hash<bit<BLOOM_FILTER_IDX_WIDTH>>(HashAlgorithm_t.CRC32) bf0_hash;
    Hash<bit<BLOOM_FILTER_IDX_WIDTH>>(HashAlgorithm_t.CRC32) bf1_hash;

    Register</*T=*/ bit<BLOOM_FILTER_CELL_SIZE>, /*I=*/ bit<BLOOM_FILTER_IDX_WIDTH>> (/* size = */ BLOOM_FILTER_SIZE, /* init = */ 1) verify_session_bf0;
    RegisterAction</*T=*/ bit<BLOOM_FILTER_CELL_SIZE>, /*I=*/ bit<BLOOM_FILTER_IDX_WIDTH>, /*U=*/ bit<BLOOM_FILTER_CELL_SIZE>> (verify_session_bf0) bf0_query = {
        void apply(inout bit<BLOOM_FILTER_CELL_SIZE> val, out bit<BLOOM_FILTER_CELL_SIZE> rv) {
            rv = val;
        }
    };

    Register<bit<BLOOM_FILTER_CELL_SIZE>, bit<BLOOM_FILTER_CELL_SIZE>> (BLOOM_FILTER_SIZE, 1) verify_session_bf1;
    RegisterAction</*T=*/ bit<BLOOM_FILTER_CELL_SIZE>, /*I=*/ bit<BLOOM_FILTER_IDX_WIDTH>, /*U=*/ bit<BLOOM_FILTER_CELL_SIZE>> (verify_session_bf1) bf1_query = {
        void apply(inout bit<BLOOM_FILTER_CELL_SIZE> val, out bit<BLOOM_FILTER_CELL_SIZE> rv) {
            rv = val;
        }
    };

    @hidden
    action get_bf_idx0() {
        local_md.heimdall.hash_idx0 = bf0_hash.get( { local_md.heimdall.sess_id } );
    }

    @hidden
    action get_bf_idx1() {
        local_md.heimdall.hash_idx1 = bf1_hash.get( { (bit<16>) local_md.heimdall.sess_id } );
    }

    @hidden
    action get_bf_res0() {
        local_md.heimdall.bf_res0 = bf0_query.execute(local_md.heimdall.hash_idx0);
    }

    @hidden 
    action get_bf_res1() {
        local_md.heimdall.bf_res1 = bf1_query.execute(local_md.heimdall.hash_idx1);
    }

    // Heimdall UL Actions  -------------------------------------------------------------------    
    action get_heimdall_ul_options_action(heimdall_uplink_options_t option) {
        local_md.heimdall.ul_options = option;
    }

    table get_heimdall_ul_options {
        key = {
            hdr.heimdall.sess_id : exact;
        }
        actions = {
            NoAction;
            get_heimdall_ul_options_action;
        }
        // TODO: if table miss, send to software GW
        default_action = NoAction();
        size = NUM_USERS;
    }

    // Heimdall DL Preparation --------------------------------------------------------------------
    action prepare_heimdall_dl_action(heimdall_session_t sess_id, heimdall_assigned_idx_t assigned_idx, ipv4_addr_t ip_3gpp, ipv4_addr_t ip_n3gpp) {
        local_md.heimdall.sess_id = sess_id;
        local_md.heimdall.assigned_idx = assigned_idx;
        if(ip_3gpp != 0) {
            local_md.heimdall.dl_options.dl_destinations.downlink_3gpp = ip_3gpp;
            local_md.heimdall.dl_options.is_3gpp_avail = HEIMDALL_DOWNLINK_AVAIL_3GPP;
            // HEIMDALL_DOWNLINK_AVAIL_3GPP = 1;
        }

        if(ip_n3gpp != 0) {
            local_md.heimdall.dl_options.dl_destinations.downlink_n3gpp = ip_n3gpp;
            local_md.heimdall.dl_options.is_n3gpp_avail = HEIMDALL_DOWNLINK_AVAIL_N3GPP;
            // HEIMDALL_DOWNLINK_AVAIL_N3GPP = 2;
        } 
    }

    table prepare_heimdall_dl {
        key = {
            hdr.ipv4.dst_addr : exact;      // virtual IP address
        }
        actions = {
            prepare_heimdall_dl_action;
            // drop;   // Don't drop; forward to CPU instead
            NoAction;
        }
        // const entries = {
        //     0x0a000001 : prepare_heimdall_dl_action(1234, 16384, 0xac100001, 0xc0a80001);
        // }
        default_action = NoAction();
        size = NUM_USERS;
    }

    @hidden
    action get_heimdall_dl_avail_action() {
        local_md.heimdall.dl_options.dl_avail = local_md.heimdall.dl_options.is_3gpp_avail | local_md.heimdall.dl_options.is_n3gpp_avail;
    }

    // Heimdall DL Global Policy --------------------------------------------------------------------
    action get_heimdall_global_policy_action(heimdall_policy_t policy, heimdall_policy_action_t policy_action) {
        local_md.heimdall.policy = policy;
        local_md.heimdall.policy_action = policy_action;
        local_md.heimdall.policy_override = true;
    }

    table get_heimdall_global_policy {
        key = {
            local_md.l3_src_addr : exact;
            local_md.l3_proto : exact;
            local_md.l4_src_port : exact;
        }
        actions = {
            get_heimdall_global_policy_action;
            NoAction;
        }
        // Example
        // const entries =  {
        //     (17, 5060) : get_heimdall_global_policy_action(HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP);
        // }
        default_action = NoAction();
        size = MIN_TABLE_SIZE;
    }

    // Heimdall DL User Specific Policy --------------------------------------------------------------------
    action get_heimdall_user_specific_policy_action(heimdall_policy_t policy, heimdall_policy_action_t policy_action) {
        local_md.heimdall.policy = policy;
        local_md.heimdall.policy_action = policy_action;
        local_md.heimdall.policy_override = true;
    }

    table get_heimdall_user_specific_policy {
        key = {
            local_md.heimdall.sess_id : exact;
            local_md.l3_src_addr : exact;
            local_md.l3_proto : exact;
            local_md.l4_src_port : exact;
        }
        actions = {
            NoAction;
            get_heimdall_user_specific_policy_action;
        }
        // const entries = {
        //     (1234, 0x08080808, 17, 8080) : get_heimdall_user_specific_policy_action(HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP);
        // }
        default_action = NoAction();
        size = (NUM_USERS) * 2;
    }

    // Heimdall DL User Default Policy --------------------------------------------------------------------
    action set_heimdall_default_policy() {
        local_md.heimdall.policy = HEIMDALL_POLICY_SWITCH;
        local_md.heimdall.policy_action = HEIMDALL_SWITCH_PRIMARY_N3GPP;
    }

    action get_heimdall_user_default_policy_action(heimdall_policy_t policy, heimdall_policy_action_t policy_action) {
        local_md.heimdall.policy = policy;
        local_md.heimdall.policy_action = policy_action;
    }

    table get_heimdall_user_default_policy {
        key = {
            local_md.heimdall.sess_id : exact;
        }
        actions = {
            set_heimdall_default_policy;
            get_heimdall_user_default_policy_action;
        }
        default_action = set_heimdall_default_policy();
        size = NUM_USERS / 2;
    }

    // Heimdall DL Split Get Assigned Idx --------------------------------------------------------------------
    action get_heimdall_assigned_idx_action(heimdall_split_assigned_idx_t split_assigned_idx) {
        local_md.heimdall.dl_options.split_assigned_idx = split_assigned_idx;
    }

    table get_heimdall_split_assigned_idx {
        key = {
            local_md.heimdall.sess_id : exact;
        }
        actions = {
            drop;
            get_heimdall_assigned_idx_action;
        }
        default_action = drop();
        size = NUM_SPLIT_USERS;
    }

    // Heimdall DL Split: Packet Sequencing --------------------------------------------------------------------
    Register<bit<32>, _> (NUM_SPLIT_USERS) split_pkt_sequence;
    RegisterAction<bit<32>, _, bit<32>>(split_pkt_sequence) get_split_pkt_sequence = {
        void apply(inout bit<32> val, out bit<32> rv) {
            val = val + 1;
            rv = val;
        }
    };

    // Heimdall Register: Path Weights --------------------------------------------------------------------
    Register<bit<8>, _> (NUM_USERS) path_weight_3gpp;
    RegisterAction<bit<8>, _, bit<8>>(path_weight_3gpp) get_path_weight_3gpp = {
        void apply(inout bit<8> val, out bit<8> rv) {
            rv = val;
        }
    };
    RegisterAction<bit<8>, _, bit<8>>(path_weight_3gpp) set_path_weight_3gpp = {
        void apply(inout bit<8> val, out bit<8> rv) {
            // TODO
            val = 1;
            rv = 0;
        }
    };

    Register<bit<8>, _> (NUM_USERS) path_weight_n3gpp;
    RegisterAction<bit<8>, _, bit<8>>(path_weight_n3gpp) get_path_weight_n3gpp = {
        void apply(inout bit<8> val, out bit<8> rv) {
            rv = val;
        }
    };
    RegisterAction<bit<8>, _, bit<8>>(path_weight_n3gpp) set_path_weight_n3gpp = {
        void apply(inout bit<8> val, out bit<8> rv) {
            // TODO
            val = 1;
            rv = 0;
        }
    };

    @hidden
    action get_path_weight_3gpp_action() {
        local_md.heimdall.dl_options.path_weight_3gpp = get_path_weight_3gpp.execute(local_md.heimdall.assigned_idx);
    }
    
    @hidden
    action get_path_weight_n3gpp_action() {
        local_md.heimdall.dl_options.path_weight_n3gpp = get_path_weight_n3gpp.execute(local_md.heimdall.assigned_idx);
    }

    // Heimdall: Get DL Avail
    action get_dl_avail_action(heimdall_downlink_avail_t dl_avail) {
        local_md.heimdall.dl_options.dl_avail = dl_avail;
    }

    table get_dl_avail {
        key = {
            local_md.heimdall.dl_options.path_weight_3gpp : ternary;
            local_md.heimdall.dl_options.path_weight_n3gpp : ternary;
        }
        actions = {
            get_dl_avail_action;
        }
        const entries = {
            (0, 0) : get_dl_avail_action(HEIMDALL_DOWNLINK_AVAIL_NONE);
            (_, 0) : get_dl_avail_action(HEIMDALL_DOWNLINK_AVAIL_3GPP);
            (0, _) : get_dl_avail_action(HEIMDALL_DOWNLINK_AVAIL_N3GPP);
        }
        default_action = get_dl_avail_action(HEIMDALL_DOWNLINK_AVAIL_BOTH);
        size = MIN_TABLE_SIZE;
    }

    // Heimdall: Split Meter
    // REGISTER_IDX_WIDTH = 16
    Meter<bit<SPLIT_USER_IDX_WIDTH>>(NUM_SPLIT_USERS, MeterType_t.BYTES) split_meter;

    // Heimdall: Perform Policies
    #include "includes/policy.p4"

    // Heimdall: split additional operations
    #include "includes/split.p4"

    // Heimdall Map DL Choice to Dst Addr
    action map_dl_choice_3gpp_action() {
        local_md.src_addr = 0xc0a80164;
        local_md.dst_addr = local_md.heimdall.dl_options.dl_destinations.downlink_3gpp;
    }

    action map_dl_choice_n3gpp_action() {
        local_md.src_addr = 0xc0a80165;
        local_md.dst_addr = local_md.heimdall.dl_options.dl_destinations.downlink_n3gpp;
    }

    table map_dl_choice {
        key = {
            local_md.heimdall.dl_options.dl_choice : exact;
        }
        actions = {
            map_dl_choice_3gpp_action;
            map_dl_choice_n3gpp_action;
            NoAction;
        }
        default_action = NoAction();
        const entries = {
            HEIMDALL_DL_CHOICE_TYPE_3GPP : map_dl_choice_3gpp_action();
            HEIMDALL_DL_CHOICE_TYPE_N3GPP : map_dl_choice_n3gpp_action();
        }
    }

#ifdef REORDER
    // Reordering Buffer
    #include "includes/reorder.p4"
#endif

    apply {
        if(hdr.ipv4.isValid()) {
            if(hdr.heimdall.isValid()) {
                get_bf_idx0();
                get_bf_idx1();
            }

            mark_ingress_port.apply();
            mark_heimdall_ul_dl.apply();
            if(local_md.heimdall.dir == HEIMDALL_TYPE_UPLINK) {

                // 1. Verify user session ID
                // 2. Decapsulate the packet
                get_bf_res0();
                get_bf_res1();

                if(local_md.heimdall.bf_res0 != 0 && local_md.heimdall.bf_res1 != 0) {
                    heimdall_decap.apply(hdr, local_md);
                }

#ifdef REORDER
                if(hdr.heimdall.flags == 0xff) {
                    local_md.is_tail = true;
                }
                // 3. TODO: Reorder?
                if(is_user_need_reorder.apply().hit) {
                    if(local_md.is_tail) {
                        update_reorder_reg.execute(local_md.reorder_idx);
                        // TODO: also need to unpause the queue
                        // ig_dprsr_md.adv_flow_ctl = 2283831296 + 0;
                    } else {
                        local_md.reorder_epoch = get_reorder_reg.execute(local_md.reorder_idx);
                        if(local_md.reorder_epoch == local_md.heimdall.pkt_seq_num) {
                            // no need to buffer, just forward
                            local_md.bypass_reorder = true;
                        } else {
                            // we assume that seq_num > reorder epoch
                            // TODO: what if the number of tofino is smaller
                            // then buffer here

                            // first, find a queue index to use
                            // out-of-order

                            // local_md.queue_table_idx0 = local_md.heimdall.sess_id[3:0];
                            // local_md.queue_matched0 = get_find_queue_0.execute(local_md.queue_table_idx0);
                            // if(local_md.queue_matched0 == 0){
                            //     local_md.queue_idx = (bit<7>) local_md.queue_table_idx0;
                            // } else {
                            //     // no queue available
                            //     // just forward
                            //     local_md.bypass_reorder = true;
                                
                            // }
                            local_md.queue_idx = 1;

                            if(!local_md.bypass_reorder) {
                                // QueueId_t
                                // forward to the queue
                                ig_tm_md.qid = local_md.queue_idx;
                                // pause the queue
                                // ig_dprsr_md.adv_flow_ctl = 2283831296 + 1;
                                ig_dprsr_md.adv_flow_ctl = 2785050624 + 1;

                                // 1 is pause
                                // 0 is resume

                            }

                        }
                    }

                    if(local_md.is_tail) {
                        // ig_dprsr_md.adv_flow_ctl = 2283831296 + 0;
                        ig_dprsr_md.adv_flow_ctl = 2785050624 + 0;
                    }
                }
#endif
                // REWORK!!
                // Get UL options - NORMAL or REORDER?
                // TODO: If table miss, should send to CPU for further processing
                // get_heimdall_ul_options.apply();
                // 3. Apply reordering if needed
                // TODO: Keep track of sequence numbers?
                // Apply ConWeave reordering technique
                // For Steering/ Switching
            } else if(local_md.heimdall.dir == HEIMDALL_TYPE_DOWNLINK) {
                // 1. Prepare for Heimdall DL
                // Based on destination, get session ID, assigned index, and tunnel endpoints (tep)
                if(!prepare_heimdall_dl.apply().hit) {
                    // TODO: If table miss, need to fall back to CPU?
                    // local_md.egress_port = CPU_PORT;
                    local_md.to_cpu = true;
                    local_md.dst_addr = 0x0afffffe; // to CPU
                } else {
                    // 2. Check whether both DL destinations are available
                    // get_heimdall_dl_avail_action();

                    // 3. Check if any overriding global policies to apply
                    get_heimdall_global_policy.apply();

                    // 4. Check if any overriding user-specific policies that apply
                    if(!local_md.heimdall.policy_override) {
                        get_heimdall_user_specific_policy.apply();
                        // NOTE: split is only available for certain traffic!!

                        // 6. To support SPLIT, we need dedicated register
                        // For that, we use control plane assigned indexes
                        if(local_md.heimdall.policy == HEIMDALL_POLICY_SPLIT) {
                            get_heimdall_split_assigned_idx.apply();

                            // Get Sequence Number
                            local_md.heimdall.pkt_seq_num = get_split_pkt_sequence.execute(local_md.heimdall.dl_options.split_assigned_idx);
                        }
                    }

                    // 5. Get user default policy
                    if(!local_md.heimdall.policy_override) {
                        get_heimdall_user_default_policy.apply();
                    }

                    // 7. Get Path Weights
                    // Note: 
                    // > Not using SESSION ID as index to allow easier to scale for more users
                    // TODO: Should spread across several registers to improve update times!!
                    get_path_weight_3gpp_action();
                    get_path_weight_n3gpp_action();

                    // 8. Compute DL AVAIL
                    // Get available DL destinations
                    get_dl_avail.apply();

                    // 9. Apply the policies
                    perform_policy.apply();

                    // 10. More work to do with STEER and SPLIT
                    if(local_md.heimdall.dl_options.is_multipath) {
                        // STEER
                        if(local_md.heimdall.policy == HEIMDALL_POLICY_STEER) {
                            heimdall_path_weights_t best_path = max(local_md.heimdall.dl_options.path_weight_3gpp, local_md.heimdall.dl_options.path_weight_n3gpp); 
                            if(best_path == local_md.heimdall.dl_options.path_weight_3gpp) {
                                local_md.heimdall.dl_options.dl_choice = HEIMDALL_DL_CHOICE_TYPE_3GPP;
                            } else {
                                local_md.heimdall.dl_options.dl_choice = HEIMDALL_DL_CHOICE_TYPE_N3GPP;
                            }
                        } 
                        // SPLIT
                        else if(local_md.heimdall.policy == HEIMDALL_POLICY_SPLIT) { 
                            // METER
                            if(local_md.heimdall.dl_options.split_type == HEIMDALL_SPLIT_TYPE_METER) {
                                perform_split_meter_ops.apply();
                            } 
                            // LB
                            else if(local_md.heimdall.dl_options.split_type == HEIMDALL_SPLIT_TYPE_LB) {
                                perform_split_lb_ops.apply();
                            }
                        } 
                    }

                    // 11. Apply DL Choice to DL 
                    map_dl_choice.apply();

                    // 12. Encapsulate the packet
                    heimdall_encap.apply(hdr, local_md);
                }   
            }

            // TODO: modify conditions
            ipv4_forward.apply();
            dest_mac_write.apply();
        }
    }
}

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    apply {
    }
}

Pipeline <switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t> (SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;

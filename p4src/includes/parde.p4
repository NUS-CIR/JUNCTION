//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(packet_in pkt,
                           out switch_header_t hdr,
                           out switch_local_metadata_t local_md,
                           out ingress_intrinsic_metadata_t ig_intr_md) {
    
    state start {
        pkt.extract(ig_intr_md);

        local_md.ingress_port = ig_intr_md.ingress_port;

        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP : parse_arp;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        local_md.l3_proto = hdr.ipv4.protocol;
        local_md.l3_src_addr = hdr.ipv4.src_addr;
        local_md.l3_dst_addr = hdr.ipv4.dst_addr;

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);

        local_md.l4_src_port = hdr.tcp.src_port;
        local_md.l4_dst_port = hdr.tcp.dst_port;

        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);

        local_md.l4_src_port = hdr.udp.src_port;
        local_md.l4_dst_port = hdr.udp.dst_port;

        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (UDP_PORT_HEIMDALL, UDP_PORT_HEIMDALL) : parse_heimdall;
            default : accept;
        }
    }

    state parse_heimdall {
        pkt.extract(hdr.heimdall);

        local_md.heimdall.sess_id = hdr.heimdall.sess_id;
        local_md.heimdall.pkt_seq_num = hdr.heimdall.seq_num;

        transition parse_inner_ipv4;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }
}

//----------------------------------------------------------------------------
// Ingress deparser
//----------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_local_metadata_t local_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Checksum() ipv4_checksum;
    
    apply {
        // Updating and checking of the checksum is done in the deparser.
        // Checksumming units are only available in the parser sections of 
        // the program.
        if (local_md.checksum_upd_ipv4) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.diffserv,
                 hdr.ipv4.total_len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr});
        }

        pkt.emit(hdr);
    }
}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser SwitchEgressParser(packet_in pkt,
                          out switch_header_t hdr,
                          out switch_local_metadata_t local_md,
                          out egress_intrinsic_metadata_t eg_intr_md) {
                        

    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridge;
    }

    state parse_bridge {
        pkt.extract(hdr.bridge);
        transition accept;
    }
}

//----------------------------------------------------------------------------
// Egress deparser
//----------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                             inout switch_header_t hdr,
                             in switch_local_metadata_t local_md,
                             in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}
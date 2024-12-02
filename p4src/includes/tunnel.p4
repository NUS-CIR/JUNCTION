control HeimdallDecap(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md
) {

    // action store_outer_ipv4_fields() {
    //     // local_md.tunnel.decap_tos = hdr.ipv4.diffserv;
    //     // local_md.tunnel.decap_ttl = hdr.ipv4.ttl;
    // }

    action copy_ipv4_header() {
        hdr.ipv4.setValid();

        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flags = hdr.inner_ipv4.flags;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        // Pipe mode is taken care of here; Uniform mode will be handled later in the pipeline
        hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;

        hdr.inner_ipv4.setInvalid();

        // Trigger checksum updates
        local_md.checksum_upd_ipv4 = true;
    }

    action invalidate_outer_udp_header() {
        hdr.udp.setInvalid();
    }
    
    action invalidate_heimdall_header() {
        hdr.heimdall.setInvalid();
    }

    action decap_v4_inner_ipv4() {
        // store_outer_ipv4_fields();
        copy_ipv4_header();
        invalidate_outer_udp_header();
        invalidate_heimdall_header();
    }

    table decap_tunnel_hdr {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.heimdall.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
        }
        actions = {
            decap_v4_inner_ipv4;
        }
        const entries = {
            (true, true, true, true) : decap_v4_inner_ipv4();
        }
    }

    apply {
        decap_tunnel_hdr.apply();
    }
}

control HeimdallEncap(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md
    ) {

    bit<16> payload_len;
    bit<8> ip_proto;

    //
    // ************ Copy outer to inner **************************
    //
    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields except checksum
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }

    action copy_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.inner_udp.setValid();
        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action copy_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action copy_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        ip_proto = IP_PROTOCOLS_IPV4;
    }


    table tunnel_encap_0 {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.tcp.isValid() : exact;
        }

        actions = {
            copy_inner_ipv4_udp;
            copy_inner_ipv4_tcp;
            copy_inner_ipv4_unknown;
        }

        const entries = {
            (true, false, false) : copy_inner_ipv4_unknown();            
            (true, true, false) : copy_inner_ipv4_udp();
            (true, false, true) : copy_inner_ipv4_tcp();
        }
        size = 8;
    }

    //
    // ************ Add outer IP encapsulation **************************
    //

    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        // local_md.lkp.ip_proto = hdr.ipv4.protocol;
        // local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        hdr.ipv4.src_addr = local_md.src_addr;
        hdr.ipv4.dst_addr = local_md.dst_addr; 
    }
    
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
    }

    action add_heimdall_header() {
        hdr.heimdall.setValid();
        hdr.heimdall.sess_id = local_md.heimdall.sess_id;
        hdr.heimdall.flags = 0;
        hdr.heimdall.proto = 0;
        hdr.heimdall.seq_num = local_md.heimdall.pkt_seq_num;
    }

    action encap_ipv4_heimdall(bit<16> heimdall_port) {
        add_ipv4_header(IP_PROTOCOLS_UDP);
        add_udp_header(heimdall_port, heimdall_port);
        add_heimdall_header();
        
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes() + hdr.udp.minSizeInBytes() + hdr.heimdall.minSizeInBytes();

        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes() + hdr.heimdall.minSizeInBytes();

        // Heimdall = packet length 
        hdr.heimdall.length = payload_len;

        // Pkt length
        // local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes() +
        // hdr.udp.minSizeInBytes() + hdr.heimdall.minSizeInBytes();

        // Trigger checksum updates
        local_md.checksum_upd_ipv4 = true;
    }

    table tunnel_encap_1 {
        key = {
            // TODO
            // local_md.nexthop : exact;
        }
        actions = {
            // NoAction;
            encap_ipv4_heimdall;
        }

        const default_action = encap_ipv4_heimdall(UDP_PORT_HEIMDALL);
        // size = MIN_TABLE_SIZE;
    }

    apply {
        tunnel_encap_0.apply();
        tunnel_encap_1.apply();
    }
}

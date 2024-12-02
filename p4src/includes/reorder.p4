action is_user_need_reorder_action(num_reorder_users_t index) {
    local_md.reorder_idx = index;
}

table is_user_need_reorder {
    key = {
        local_md.heimdall.sess_id : exact;
    }
    actions = {
        is_user_need_reorder_action;
        NoAction;
    }
    default_action = NoAction();
    size = 65536;
}


Register</*T=*/ bit<32>, /*I=*/ bit<16>> (/* size = */ 65536, /* init = */ 0) reorder_reg;
RegisterAction</*T=*/ bit<32>, /*I=*/ bit<16>, /*U=*/ bit<32>> (reorder_reg) get_reorder_reg = {
    void apply(inout bit<32> val, out bit<32> rv) {
        rv = val;
    }
};

RegisterAction</*T=*/ bit<32>, /*I=*/ bit<16>, /*U=*/ bit<32>> (reorder_reg) update_reorder_reg = {
    void apply(inout bit<32> val, out bit<32> rv) {
        val = local_md.heimdall.pkt_seq_num + 1;    
        // come back to this later
    }
};


Register<bit<32>, bit<4>> (16) find_queue_0;
Register<bit<32>, bit<4>> (16) find_queue_1;
RegisterAction<bit<32>, bit<4>, bit<32>> (find_queue_0) get_find_queue_0 = {
    void apply(inout bit<32> val, out bit<32> rv) {
        if(val == 0){
            val = local_md.heimdall.sess_id;
            rv = 0;
        } else {
            rv = 1;
        }
    }
};

RegisterAction<bit<32>, bit<4>, bit<32>> (find_queue_1) get_find_queue_1 = {
    void apply(inout bit<32> val, out bit<32> rv) {
        rv = val;
    }
};
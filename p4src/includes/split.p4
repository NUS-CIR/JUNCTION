action perform_split_meter_ops_action(heimdall_downlink_choice_t dl_choice) {
    local_md.heimdall.dl_options.dl_choice = dl_choice;
}

table perform_split_meter_ops {
    key = {
        local_md.heimdall.dl_options.split_meter_color : ternary;
        local_md.heimdall.dl_options.split_primary : exact;
    }
    actions = {
        NoAction;
        perform_split_meter_ops_action;
    }
    const entries = {
        (MeterColor_t.RED, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP) : perform_split_meter_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (MeterColor_t.RED, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP) : perform_split_meter_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (_, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP) : perform_split_meter_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (_, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP) : perform_split_meter_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
    }
    default_action = NoAction();
    size = MIN_TABLE_SIZE;
}

action perform_split_lb_ops_action(heimdall_downlink_choice_t dl_choice) {
    local_md.heimdall.dl_options.dl_choice = dl_choice;
}

table perform_split_lb_ops {
    key = {
        local_md.heimdall.policy_action : exact;
        local_md.heimdall.dl_options.split_primary : exact;
        local_md.heimdall.pkt_seq_num[2:0] : exact;     // take last 3 bits then compute the ratio
    }
    actions = {
        NoAction;
        perform_split_lb_ops_action;
    }
    const entries = {
        /* HEIMDALL_SPLIT_PRIMARY_3GPP_LB: 50:50 split */
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 0) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 1) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 2) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 3) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 4) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 5) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 6) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 7) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);

        /* HEIMDALL_SPLIT_PRIMARY_N3GPP_LB: 50:50 split */
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 0) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 1) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 2) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 3) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 4) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 5) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 6) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 7) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);

        /* HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28: 20:80 split */
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 0) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 1) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 2) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 3) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 4) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 5) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 6) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP, 7) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);

        /* HEIMDALL_SPLIT_PRIMARY_N3GPP_LB: 20:80 split */
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 0) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 1) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 2) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 3) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 4) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 5) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 6) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP, 7) : perform_split_lb_ops_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
    }
    default_action = NoAction();
    size = MIN_TABLE_SIZE;
}
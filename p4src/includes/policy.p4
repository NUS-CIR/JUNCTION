action perform_policy_steer_multipath_action() {
    local_md.heimdall.dl_options.is_multipath = true;
}

action perform_policy_only_option_action(heimdall_downlink_choice_t dl_choice) {
    local_md.heimdall.dl_options.dl_choice = dl_choice;
}

action perform_policy_split_action(heimdall_downlink_choice_t dl_choice) {
    local_md.heimdall.dl_options.dl_choice = dl_choice;
}

action perform_policy_split_lb_action(heimdall_split_primary_t split_primary) {
    local_md.heimdall.dl_options.is_multipath = true;
    local_md.heimdall.dl_options.split_type = HEIMDALL_SPLIT_TYPE_LB;
    local_md.heimdall.dl_options.split_primary = split_primary;
}

action perform_policy_split_with_meter_action(heimdall_downlink_choice_t dl_choice) {
    local_md.heimdall.dl_options.split_type = HEIMDALL_SPLIT_TYPE_METER;
    local_md.heimdall.dl_options.split_meter_color = split_meter.execute(local_md.heimdall.dl_options.split_assigned_idx);
    local_md.heimdall.dl_options.dl_choice = dl_choice;
}

action perform_policy_split_multipath_action(heimdall_split_primary_t split_primary) {
    local_md.heimdall.dl_options.is_multipath = true;
    local_md.heimdall.dl_options.split_type = HEIMDALL_SPLIT_TYPE_METER;
    local_md.heimdall.dl_options.split_primary = split_primary;
    local_md.heimdall.dl_options.split_meter_color = split_meter.execute(local_md.heimdall.dl_options.split_assigned_idx);
}

table perform_policy {
    key = {
        local_md.heimdall.policy : exact;
        local_md.heimdall.policy_action : exact;
        local_md.heimdall.dl_options.dl_avail : exact;
    }
    actions = {
        perform_policy_only_option_action;
        perform_policy_steer_multipath_action;
        perform_policy_split_action;
        perform_policy_split_lb_action;
        perform_policy_split_with_meter_action;
        perform_policy_split_multipath_action;
    }
    const entries = {
        /* SWTICH: PRIMARY 3GPP */
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);
        /* SWTICH: PRIMARY N3GPP */
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SWITCH, HEIMDALL_SWITCH_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);

        /* STEER: RTT */ 
        (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_RTT, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_steer_multipath_action();
        (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_RTT, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_RTT, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_RTT, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);
        /* STEER: PLR */ 
        // (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_PLR, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_steer_action();
        // (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_PLR, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        // (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_PLR, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        // (HEIMDALL_POLICY_STEER, HEIMDALL_STEER_MIN_PLR, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_only_option_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);

        /* SPLIT: PRIMARY 3GPP */ 
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_multipath_action(HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_with_meter_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);
        /* SPLIT: PRIMARY N3GPP */ 
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_multipath_action(HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_with_meter_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);

        // LB MODE SPLIT: PRIMARY 3GPP
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_lb_action(HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);
        // LB MODE SPLIT: PRIMARY N3GPP
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_lb_action(HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID); 

        // TODO: LB MODE SPLIT: add other ratios here 
        // LB MODE SPLIT: PRIMARY 3GPP
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_lb_action(HEIMDALL_SPLIT_PRIMARY_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID);
        // LB MODE SPLIT: PRIMARY N3GPP
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_BOTH): perform_policy_split_lb_action(HEIMDALL_SPLIT_PRIMARY_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_N3GPP): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_N3GPP);
        (HEIMDALL_POLICY_SPLIT, HEIMDALL_SPLIT_PRIMARY_N3GPP_LB_28, HEIMDALL_DOWNLINK_AVAIL_NONE): perform_policy_split_action(HEIMDALL_DL_CHOICE_TYPE_INVALID); 
    }
    size = MIN_TABLE_SIZE;
}
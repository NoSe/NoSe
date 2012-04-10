NETWORK COMMAND

ctrl_msg_ -> threshold_ = MM_DEF_THR;
//ctrl_msg_ -> lpl_duty_ = PERIODIC;
ctrl_msg_ -> lpl_duty_ = 1;
ctrl_msg_ -> cmd_type_ = MM_GET_TEMPERATURE;
ctrl_msg_ -> sampling_p_ = MM_SAMPLING_TIME;
ctrl_msg_ -> collecting_p_ = MM_COLLECTING_TIME;

java SinkCollector 0 1 1 0 9 60
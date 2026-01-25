function correct = verifyTurbSim(turbsim_path)
[res, msg]= system([turbsim_path ' -h']);
msg_lines = splitlines(msg);
correct = res==0 && contains(msg_lines{12}, 'TurbSim-v3.3.0');

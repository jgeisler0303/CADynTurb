function correct = verifyOpenFAST(openfast_path)
[res, msg]= system([openfast_path ' -h']);
msg_lines = splitlines(msg);
correct = res==0 && contains(msg_lines{12}, 'OpenFAST-v3.3.0');

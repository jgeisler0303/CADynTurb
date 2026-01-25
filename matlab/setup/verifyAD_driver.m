function correct = verifyAD_driver(AD_driver)
[res, msg]= system([AD_driver ' -h']);
msg_lines = splitlines(msg);
% if ispc
%     if res~=0
%         error('There is a problem with the AeroDyn standalone driver executable. The cause is often that the libiomp5md.dll from the Intel Fortran compiler cannot be found. Try to copy the DLL into the directory of the AeroDyn program, it should be somewhere in the folders "C:\Program Files (x86)\Common Files\intel" or "C:\Program Files (x86)\Intel\oneAPI\compiler".')
%     end
% end
correct = res==0 && contains(msg_lines{12}, 'AeroDyn_driver-v3.3.0');

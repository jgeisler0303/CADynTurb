function correct = verifyMaxima(maxima_path)
[res, msg]= system([maxima_path ' --version']);
correct = res==0 && contains(msg, 'Maxima');
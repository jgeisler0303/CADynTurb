function ekf_config= T1B1cG_est_RK1_ekf_config
ekf_config.x_ul= [  2;              % tower FA deflection
                10;                 % blade flap defelction
                pi;                 % generator angle offset

                100;                % tower FA deflection speed
                100;                % blade flap defelction speed
                50/30*pi;           % rotor speed
                50/30*pi;           % rotor generator speed difference

                40;                 % wind speed
                ];                
ekf_config.x_ll= [  -2;             % tower FA deflection
                -10;                % blade flap defelction
                -pi;                % generator angle offset

                -100;               % tower FA deflection speed
                -100;               % blade flap defelction speed
                0;                  % rotor speed
                -500/30*pi;         % rotor generator speed difference

                2;                  % wind speed
                ];
                
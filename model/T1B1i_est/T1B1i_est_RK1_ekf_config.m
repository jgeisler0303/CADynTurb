function ekf_config= T1B1i_est_RK1_ekf_config
model_indices

ekf_config.x_ul= [  2;                  % tower FA deflection
                10;                  % blade flap defelction
                10;                  % blade flap defelction
                10;                  % blade flap defelction
                64000;                  % rotor angle

                100;                  % tower FA deflection speed
                100;                  % blade flap defelction speed
                100;                  % blade flap defelction speed
                100;                  % blade flap defelction speed
                50/30*pi; % rotor speed

                40; % wind speed
                5;  %h_shear
                10; % v_shear
                ];                
ekf_config.x_ll= [  -2;                  % tower FA deflection
                -5;                  % blade flap defelction
                -5;                  % blade flap defelction
                -5;                  % blade flap defelction
                -64000;                % rotor angle

                -100;                  % tower FA deflection speed
                -100;                  % blade flap defelction speed
                -100;                  % blade flap defelction speed
                -100;                  % blade flap defelction speed
                0.01; % rotor speed

                2; % wind speed
                -5;  %h_shear
                -5; % v_shear
                ];                 
                

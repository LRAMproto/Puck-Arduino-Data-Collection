% Arduino Data Collector
%
% Refactoring by David Rebhuhn

function Arduino_Data_Collector_2()

% Captures settings between calls.
settings = struct();

% Captures runtime variables during calls.
runtime_vars = struct();

% Captures data during calls.
data = struct();

if ispc
    % Checks if the Windows version of MATLAB is being used.
    % Sets port name accordingly.
    settings.PORT_NAME = 'COM1';
    
elseif ismac
    % Checks if the Macintosh version of MATLAB is being used.
    % Sets port name accordingly
    settings.PORT_NAME ='/dev/ttyACM0';
    
elseif isunix
    % Checks if the UNIX version of MATLAB is being used.
    % Sets port name accordingly.
    settings.PORT_NAME ='/dev/ttyACM0';
    
else
    
    error('Unknown operating system.');
end

%
% Locate Arduino
%

arduino = serial(settings.PORT_NAME,'BaudRate',9600);

% Begin Communication with Arduino
fopen(arduino);

try
    
    % Specify number of runs to collect data from.
    NUM_RUNS = 1001;
    
    % Initiate radio reading with a 1 second pause to filter out cutoff terms
    % pause(1)
    data1 = fscanf(arduino);
    pause(1)
    
    for i = 1:NUM_RUNS
        data = fscanf(arduino,'%f');
        
        % compile data into a vector
        raw(i) = data(1);
        
    end
    
    fclose(arduino)
    
catch err
    
    % This allows the arduino to be closed neatly in the case of some
    % strange error occurring.
    
    fclose(arduino);
    rethrow(err);
end

% Cutoff first 10 terms of Xraw due to communication delays between
% radio read
cut = raw(10:length(raw));

% View compiled acceleration data
accel_vector = reshape(cut,2,[]);


% %
% % *********** Calibration and Conversion **************
% %
% % //// Convert [mV] data into G-forces and calibrate each axis ////
% %

% %
% % X data
% %
x_data = accel_vector(1,:);
xavg = mean(x_data);
%                                      % Arduino Nano_usb = 334.1696 [mV/g]
%                                      % Arduino Nano_bat = 403.8696 [mV/g]
%                                      % Arduino Fio_usb = 502.2153 [mV/g]
%                                      % Arduino Fio_bat = 503.0357 [mV/g]
g_force_x = (x_data ./ 503.0357)-1;
max_g_x = max(g_force_x);

% %
% % Y data
% %
y_data = accel_vector(2,:);
yavg = mean(y_data);
%                                      % Arduino Nano_usb = 338.7065 [mV/g]
%                                      % Arduino Nano_bat = 406.4761 [mV/g]
%                                      % Arduino Fio_usb = 514.9405 [mV/g]
%                                      % Arduino Fio_bat = 516.0575 [mV/g]
g_force_y = (y_data ./ 516.0575)-1;
max_g_y = max(g_force_y);

% %
% % Z data
% %
% z_data = accel_vector(3,:)
% z_data = cut;
% zavg = mean(z_data);
% %                                     % Arduino Nano_usb = 403.6892 [mV/g]
% %                                     % Arduino Nano_bat = 484.2441 [mV/g]
% %                                     % Arduino Fio_usb =
% %                                     % Arduino Fio_bat =
% g_force_z = abs(z_data ./ 405.0106);
% max_g_z = max(g_force_z);



% calculate the resultant
resultant = sqrt(g_force_x.^2 + g_force_y.^2);
maxR = max(abs(resultant))

% %
% % Plot results
% % ********* Data **********
% %
plot([0:length(accel_vector)-1],resultant,'linewidth',1.1)
title('Acceleration resultant vs Time')
ylabel('Acceleration [G force]')
xlabel('Time [unknown units]')
grid on

% axis([0 length(runs)/2 0 3]);


% %
% % Terminate the terminal and clear "arduino"
% %

delete(arduino)
clear arduino


end
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

runtime_vars.arduino = serial(settings.PORT_NAME,'BaudRate',9600);

% Begin Communication with Arduino
fopen(runtime_vars.arduino);

try
    
    % Specify number of runs to collect data from.
    settings.NUM_RUNS = 1001;
    
    % Initiate radio reading with a 1 second pause to filter out cutoff terms
    % pause(1)
    data1 = fscanf(runtime_vars.arduino);
    pause(1)
    
    for i = 1:settings.NUM_RUNS
        input_data = fscanf(runtime_vars.arduino,'%f');
        
        % compile data into a vector
        data.raw(i) = input_data(1);
        
    end
    
    fclose(runtime_vars.arduino)
    
catch err
    
    % This allows the runtime_vars.arduino to be closed neatly in the case of some
    % strange error occurring.
    
    fclose(runtime_vars.arduino);
    rethrow(err);
end

% Cutoff first 10 terms of Xdata.raw due to communication delays between
% radio read
data.cut = data.raw(10:length(data.raw));

% View compiled acceleration data
data.accel_vector = reshape(data.cut,2,[]);


% %
% % *********** Calibration and Conversion **************
% %
% % //// Convert [mV] data into G-forces and calibrate each axis ////
% %

% %
% % X data
% %
data.x_data = data.accel_vector(1,:);
data.xavg = mean(data.x_data);
%                                      % Arduino Nano_usb = 334.1696 [mV/g]
%                                      % Arduino Nano_bat = 403.8696 [mV/g]
%                                      % Arduino Fio_usb = 502.2153 [mV/g]
%                                      % Arduino Fio_bat = 503.0357 [mV/g]
data.g_force_x = (data.x_data ./ 503.0357)-1;
data.max_g_x = max(data.g_force_x);

% %
% % Y data
% %
data.y_data = data.accel_vector(2,:);
data.yavg = mean(data.y_data);
%                                      % Arduino Nano_usb = 338.7065 [mV/g]
%                                      % Arduino Nano_bat = 406.4761 [mV/g]
%                                      % Arduino Fio_usb = 514.9405 [mV/g]
%                                      % Arduino Fio_bat = 516.0575 [mV/g]
data.g_force_y = (data.y_data ./ 516.0575)-1;
data.max_g_y = max(data.g_force_y);

% %
% % Z data
% %
% z_data = data.accel_vector(3,:)
% z_data = data.cut;
% zavg = mean(z_data);
% %                                     % Arduino Nano_usb = 403.6892 [mV/g]
% %                                     % Arduino Nano_bat = 484.2441 [mV/g]
% %                                     % Arduino Fio_usb =
% %                                     % Arduino Fio_bat =
% g_force_z = abs(z_data ./ 405.0106);
% max_g_z = max(g_force_z);



% calculate the data.resultant
data.resultant = sqrt(data.g_force_x.^2 + data.g_force_y.^2);
data.maxR = max(abs(data.resultant));

% %
% % Plot results
% % ********* Data **********
% %
plot([0:length(data.accel_vector)-1],data.resultant,'linewidth',1.1)
title('Acceleration data.resultant vs Time')
ylabel('Acceleration [G force]')
xlabel('Time [unknown units]')
grid on

% axis([0 length(runs)/2 0 3]);


% %
% % Terminate the terminal and clear "runtime_vars.arduino"
% %

delete(runtime_vars.arduino)
clear runtime_vars.arduino


end
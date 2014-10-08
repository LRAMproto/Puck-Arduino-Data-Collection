% Arduino Data Collector
%
% Refactoring by David Rebhuhn

function h = Arduino_Data_Collector_2()

% Captures h.handles between calls.
h.settings = struct();

% Captures runtime variables during calls.
h.runtime_vars = struct();

% Captures h.data during calls.
h.data = struct();

if ispc
    % Checks if the Windows version of MATLAB is being used.
    % Sets port name accordingly.
    h.settings.PORT_NAME = 'COM1';
    
elseif ismac
    % Checks if the Macintosh version of MATLAB is being used.
    % Sets port name accordingly
    h.settings.PORT_NAME ='/dev/ttyACM0';
    
elseif isunix
    % Checks if the UNIX version of MATLAB is being used.
    % Sets port name accordingly.
    h.settings.PORT_NAME ='/dev/ttyACM0';
    
else
    
    error('Unknown operating system.');
end

%
% Locate Arduino
%

h.runtime_vars.arduino = serial(h.settings.PORT_NAME,'BaudRate',9600);

% Begin Communication with Arduino
fopen(h.runtime_vars.arduino);

try
    
    % Specify number of runs to collect h.data from.
    h.settings.NUM_RUNS = 1001;
    
    % Initiate radio reading with a 1 second pause to filter out cutoff terms
    % pause(1)
    h.data1 = fscanf(h.runtime_vars.arduino);
    pause(1)
    
    for i = 1:h.settings.NUM_RUNS
        input_h.data = fscanf(h.runtime_vars.arduino,'%f');
        
        % compile h.data into a vector
        h.data.raw(i) = input_h.data(1);
        
    end
    
    fclose(h.runtime_vars.arduino)
    
catch err
    
    % This allows the h.runtime_vars.arduino to be closed neatly in the case of some
    % strange error occurring.
    
    fclose(h.runtime_vars.arduino);
    rethrow(err);
end

% Cutoff first 10 terms of Xh.data.raw due to communication delays between
% radio read
h.data.cut = h.data.raw(10:length(h.data.raw));

% View compiled acceleration h.data
h.data.accel_vector = reshape(h.data.cut,2,[]);


% %
% % *********** Calibration and Conversion **************
% %
% % //// Convert [mV] h.data into G-forces and calibrate each axis ////
% %

% %
% % X h.data
% %
h.data.x_h.data = h.data.accel_vector(1,:);
h.data.xavg = mean(h.data.x_h.data);
%                                      % Arduino Nano_usb = 334.1696 [mV/g]
%                                      % Arduino Nano_bat = 403.8696 [mV/g]
%                                      % Arduino Fio_usb = 502.2153 [mV/g]
%                                      % Arduino Fio_bat = 503.0357 [mV/g]
h.data.g_force_x = (h.data.x_h.data ./ 503.0357)-1;
h.data.max_g_x = max(h.data.g_force_x);

% %
% % Y h.data
% %
h.data.y_h.data = h.data.accel_vector(2,:);
h.data.yavg = mean(h.data.y_h.data);
%                                      % Arduino Nano_usb = 338.7065 [mV/g]
%                                      % Arduino Nano_bat = 406.4761 [mV/g]
%                                      % Arduino Fio_usb = 514.9405 [mV/g]
%                                      % Arduino Fio_bat = 516.0575 [mV/g]
h.data.g_force_y = (h.data.y_h.data ./ 516.0575)-1;
h.data.max_g_y = max(h.data.g_force_y);

% %
% % Z h.data
% %
% z_h.data = h.data.accel_vector(3,:)
% z_h.data = h.data.cut;
% zavg = mean(z_h.data);
% %                                     % Arduino Nano_usb = 403.6892 [mV/g]
% %                                     % Arduino Nano_bat = 484.2441 [mV/g]
% %                                     % Arduino Fio_usb =
% %                                     % Arduino Fio_bat =
% g_force_z = abs(z_h.data ./ 405.0106);
% max_g_z = max(g_force_z);



% calculate the h.data.resultant
h.data.resultant = sqrt(h.data.g_force_x.^2 + h.data.g_force_y.^2);
h.data.maxR = max(abs(h.data.resultant));

% %
% % Plot results
% % ********* Data **********
% %
plot([0:length(h.data.accel_vector)-1],h.data.resultant,'linewidth',1.1)
title('Acceleration h.data.resultant vs Time')
ylabel('Acceleration [G force]')
xlabel('Time [unknown units]')
grid on

% axis([0 length(runs)/2 0 3]);


% %
% % Terminate the terminal and clear "h.runtime_vars.arduino"
% %

delete(h.runtime_vars.arduino)
clear h.runtime_vars.arduino


end
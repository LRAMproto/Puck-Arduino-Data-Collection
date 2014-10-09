% Arduino Data Collector
%
% Refactoring by David Rebhuhn

function h = Arduino_Data_Collector_2()


% Sets up appropriate variables.
h = ADC_Setup();

% Collects data for a set number of runs.
NUM_RUNS = 1001;
h = ADC_CollectForXRuns(h, NUM_RUNS);

% Processes collected data.
h = ADC_ProcessData(h);

% Plots collected data.
h = ADC_PlotData(h);

end

function h = ADC_Setup()
% Setup function for the Arduino Data Collector.

% Captures h.handles between calls.
h.settings = struct();

% Captures runtime variables during calls.
h.runtime_vars = struct();

% Captures h.data during calls.
h.data = struct();

% Establishes what kind of arduino is being used. For the purposes of this
% test, the type is 'fio_bat', but this can be changed.

h.settings.ARDUINO_TYPE = 'fio_bat';

if ispc
    % Checks if the Windows version of MATLAB is being used. Sets port name
    % accordingly.
    h.settings.PORT_NAME = 'COM1';
    
elseif ismac
    % Checks if the Macintosh version of MATLAB is being used. Sets port
    % name accordingly
    h.settings.PORT_NAME ='/dev/ttyACM0';
    
elseif isunix
    % Checks if the UNIX version of MATLAB is being used. Sets port name
    % accordingly.
    h.settings.PORT_NAME ='/dev/ttyACM0';
    
else
    
    error('Unknown operating system.');
end

end

function h = ADC_CollectForXRuns(h, NUM_RUNS)
% Collects data from the Arduino for a certain number of runs.

%
% Locate Arduino
%

h.runtime_vars.arduino = serial(h.settings.PORT_NAME,'BaudRate',9600);

% Begin Communication with Arduino
fopen(h.runtime_vars.arduino);

try
    
    % Specify number of runs to collect h.data from.
    h.settings.NUM_RUNS = NUM_RUNS;
    
    % Initiate radio reading with a 1 second pause to filter out cutoff
    % terms pause(1)
    h.data1 = fscanf(h.runtime_vars.arduino);
    pause(1)
    
    for i = 1:h.settings.NUM_RUNS
        input_data = fscanf(h.runtime_vars.arduino,'%f');
        
        % compile h.data into a vector
        h.data.raw(i) = input_data(1);
        
    end
    
    fclose(h.runtime_vars.arduino);
    
catch err
    
    % This allows the h.runtime_vars.arduino to be closed neatly in the
    % case of some strange error occurring.
    
    fclose(h.runtime_vars.arduino);
    rethrow(err);
end

% % % Terminate the terminal and clear "h.runtime_vars.arduino" %

delete(h.runtime_vars.arduino)
clear h.runtime_vars.arduino

end

function h = ADC_ProcessData(h)
% Processes data gleaned from the arduino to be used in a meaningful
% fashion.

% Cutoff first 10 terms of Xh.data.raw due to communication delays between
% radio read
h.data.cut = h.data.raw(10:length(h.data.raw));

% View compiled acceleration h.data
h.data.accel_vector = reshape(h.data.cut,2,[]);


% % % *********** Calibration and Conversion ************** % % ////
% Convert [mV] h.data into G-forces and calibrate each axis //// %

% Creates the vector [1, 1, 1] to be used for calibration purposes. The

h.settings.calibration = ones(1,3);

switch (h.settings.ARDUINO_TYPE)

    case 'nano_usb'
        h.settings.calibration(1) = 334.1696; % [mV/g]
        h.settings.calibration(2) = 338.7065; % [mV/g]
        h.settings.calibration(3) = 403.6892; % [mV/g]        
    case 'nano_bat'
        h.settings.calibration(1) = 403.8696; % [mV/g]
        h.settings.calibration(2) = 406.4761; % [mV/g]
        h.settings.calibration(3) = 484.2441; % [mV/g]
    case 'fio_usb'
        h.settings.calibration(1) = 502.2153; % [mV/g]
        h.settings.calibration(2) = 514.9405; % [mV/g]
        % h.settings.calibration(3) = ; % [mV/g]
    case 'fio_bat'
        h.settings.calibration(1) = 503.0357; % [mV/g]
        h.settings.calibration(2) = 516.0575; % [mV/g]
        % h.settings.calibration(3) = 405.0106; % [mV/g]
end

% % % X h.data %
h.data.x_h.data = h.data.accel_vector(1,:);
h.data.xavg = mean(h.data.x_h.data);
%                                      % Arduino Nano_usb = 334.1696 [mV/g]
%                                      % Arduino Nano_bat = 403.8696 [mV/g]
%                                      % Arduino Fio_usb = 502.2153 [mV/g]
%                                      % Arduino Fio_bat = 503.0357 [mV/g]
h.data.g_force_x = (h.data.x_h.data ./ h.settings.calibration(1))-1;
h.data.max_g_x = max(h.data.g_force_x);

% % % Y h.data %
h.data.y_h.data = h.data.accel_vector(2,:);
h.data.yavg = mean(h.data.y_h.data);
%                                      % Arduino Nano_usb = 338.7065 [mV/g]
%                                      % Arduino Nano_bat = 406.4761 [mV/g]
%                                      % Arduino Fio_usb = 514.9405 [mV/g]
%                                      % Arduino Fio_bat = 516.0575 [mV/g]
h.data.g_force_y = (h.data.y_h.data ./ h.settings.calibration(2))-1;
h.data.max_g_y = max(h.data.g_force_y);

% % % Z h.data % z_h.data = h.data.accel_vector(3,:) z_h.data = h.data.cut;
% zavg = mean(z_h.data); %                                     % Arduino
% Nano_usb = 403.6892 [mV/g] %                                     %
% Arduino Nano_bat = 484.2441 [mV/g] %
% % Arduino Fio_usb = %                                     % Arduino
% Fio_bat = g_force_z = abs(z_data ./ h.settings.calibration(2)); max_g_z =
% max(g_force_z);

% calculate the h.data.resultant
h.data.resultant = sqrt(h.data.g_force_x.^2 + h.data.g_force_y.^2);
h.data.maxR = max(abs(h.data.resultant));

end

function h = ADC_PlotData(h)
%Plots the data. Currently uses matlab script commands.

% % % Plot results % ********* Data ********** %
plot([0:length(h.data.accel_vector)-1],h.data.resultant,'linewidth',1.1)
title('Acceleration h.data.resultant vs Time')
ylabel('Acceleration [G force]')
xlabel('Time [unknown units]')
grid on

% axis([0 length(runs)/2 0 3]);

end
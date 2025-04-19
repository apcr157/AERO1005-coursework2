% Weipeng ZHOU
% ssywz8@nottingham.edu.cn


%% PRELIMINARY TASK - ARDUINO AND GIT INSTALLATION [10 MARKS] 

% Clean up the workspace and command windows
clear; clc;

disp('Begin preparatory tasks...');

% Establishing Communication with the Arduino

try
    disp('Connecting to Arduino...');
    % Assign arduino object to variable 'a'
    a = arduino('COM3', 'Uno');
    disp('Arduino connected successfully.');
catch exception
    disp('Error connecting to Arduino.Please check the serial port number and connection.');
    disp(['Error message. ', exception.message]);
    % Stop the script if the connection fails
    return;
end

% Defining LED Pins 

ledPin = 'D9';
disp(['Using LEDs connected to pins. ', ledPin]);

% Blinking LEDs
disp('The LED is blinking 10 times...');
numBlinks = 10; % Number of flashes
blinkInterval = 0.5; % Flashing interval (sec) (0.5 sec on, 0.5 sec off)

for i = 1:numBlinks
    % Turn on LED (High - 5V)
    writeDigitalPin(a, ledPin, 1);
    % Pause at specified intervals
    pause(blinkInterval);

    % Off LED (low - 0V)
    writeDigitalPin(a, ledPin, 0);
    % Pause at specified intervals
    pause(blinkInterval);

    % Display progress (optional)
    % disp(['Blink cycle ', num2str(i), ' Done. ']);
end

disp('Blinking complete.');

% clearance
% Clear the arduino object to release the connection
clear a;
disp('Arduino connection closed。');
disp('End of preparatory mission.');

% END OF PRELIMINARY TASK 

%% TASK 1 - READ TEMPERATURE DATA, PLOT, AND WRITE TO A LOG FILE [20 MARKS]

% Read Temperature Data, Plot, and Write to Log File

disp('Start Task 1');


% Initialization and parameterization
clear a; % Remove any old connections that may exist
clc;

% Connecting the Arduino
try
    port = 'COM3';
    board = 'Uno';
    a = arduino(port, board);
    disp(['Successfully connected to Arduino Uno on port ', port]);
catch exception
    disp('Error: Cannot connect to Arduino. please check:');
    disp('Is the Arduino connected to the computer?');
    disp('Is the serial number correct?');
    disp('Is another program (such as the Arduino IDE Serial Monitor) using the serial port?');
    disp('Is the MATLAB Arduino support package installed correctly?');
    disp(['Detailed error message. ', exception.message]);
    return; % Failed connection exits the task
end

% Defining constants and parameters
duration = 600;         % Total data acquisition time (seconds) = 10 minutes
analogPin = 'A0';       % Actual analog pins connected to VOUT
Tc = 0.010;             % Temperature Coefficient (V/°C) for MCP9700A
Vo0C = 0.500;           % Output Voltage (V) at 0°C for MCP9700A
location = 'Nottingham';  % Location of data recording

% Initialize the datastore array
timeData = 1:duration; % Timeline (1 to 600 seconds)
voltageData = NaN(1, duration);     % Initializing voltage arrays with NaN
temperatureData = NaN(1, duration); % Initialize the temperature array with NaN

disp(['Start of data acquisition, duration. ', num2str(duration), 'second...']);

% 1b: Data Acquisition Cycle
figure; % Create a new graphics window for real-time drawing 
hPlot = plot(timeData, temperatureData, '-b'); % Get drawing handle
xlabel('Time (s)');
ylabel('Temperature (°C)');
title('Real-time temperature monitoring');
grid on;
ylim([-10 40]); % Setting a reasonable temperature range

tic; % start counting
for i = 1:duration
    try
        % Read Voltage
        voltage = readVoltage(a, analogPin);

        % Calculated temperature
        temperature = (voltage - Vo0C) / Tc;

        % Stored Data
        voltageData(i) = voltage;
        temperatureData(i) = temperature;

        % Updates real-time mapping (once per second)
        set(hPlot, 'YData', temperatureData);
        drawnow; % Forcing MATLAB to Update the Graphics Window

        % Pause for about 1 second
        % A more accurate way to do this is to calculate the time spent in each loop and then pause the remaining time
        elapsedTime = toc;
        pauseTime = i - elapsedTime;
        if pauseTime > 0
             pause(pauseTime);
        end

        % Real-time display of readings
        if mod(i, 10) == 0 % Prints status every 10 seconds
             disp(['Acquired ', num2str(i), ' Seconds, current temperature: ', num2str(temperature, '%.2f'), ' °C']);
        end

    catch readException
        disp(['Error reading Arduino (The ', num2str(i), ' seconds): ', readException.message]);
        disp('Trying to continue to collect...');
        % Option to skip incorrect data points or stop acquisition here
        temperatureData(i) = NaN; % Marked as invalid data
        voltageData(i) = NaN;
        pause(1); % Pause even if there is an error to avoid rapid succession of errors
    end
end
totalAcquisitionTime = toc;
disp(['Data acquisition complete, total time. ', num2str(totalAcquisitionTime), ' second']);

% 1b: Calculation of statistics
% Ignore NaN values for calculations
minTemp = min(temperatureData, [], 'omitnan');
maxTemp = max(temperatureData, [], 'omitnan');
avgTemp = mean(temperatureData, 'omitnan');

disp('Statistical results.');
disp(['Minimum temperature: ', num2str(minTemp, '%.2f'), ' °C']);
disp(['Maximum temperature:  ', num2str(maxTemp, '%.2f'), ' °C']);
disp(['Average temperature: ', num2str(avgTemp, '%.2f'), ' °C']);

% 1c: Final drawing
% You can update the final graphic or create a new one.
figure; % Creating the final graphics window
plot(timeData, temperatureData, '-bo'); % Use dots to mark data points
xlabel('Time (s)');
ylabel('Temperature (°C)');
title(['Cabin Temperature Monitoring (', num2str(duration/60), ' mins)']);
grid on;
ylim([floor(minTemp-2) ceil(maxTemp+2)]); % Dynamically adjusts Y-axis range based on data

% 1d: Formatting output to screen 
disp(' '); % line break
disp('Formatting screen output');
currentDate = datestr(now, 'dd/mm/yyyy');

% Construct output string (consistent with Table 1 format)
screenOutput = {}; % Storing per-line strings with cell arrays
screenOutput{end+1} = sprintf('Data logging initiated - %s', currentDate);
screenOutput{end+1} = sprintf('Location - %s', location);
screenOutput{end+1} = sprintf('\n'); % Blank line

% Outputting minute-by-minute data
for minute = 0:10
    index = minute * 60 + 1;
    if index <= duration && ~isnan(temperatureData(index)) % Check that the index is valid and the data is not NaN
        tempAtMinute = temperatureData(index);
        screenOutput{end+1} = sprintf('Minute\t\t%d', minute);
        screenOutput{end+1} = sprintf('Temperature\t%.2f C', tempAtMinute);
        screenOutput{end+1} = sprintf('\n'); % Add blank lines after each set of minutes/temperatures
    else
        screenOutput{end+1} = sprintf('Minute\t\t%d', minute);
        screenOutput{end+1} = sprintf('Temperature\tData N/A'); % If the data is invalid
         screenOutput{end+1} = sprintf('\n');
    end
end

% Output statistics
screenOutput{end+1} = sprintf('Max temp\t%.2f C', maxTemp);
screenOutput{end+1} = sprintf('Min temp\t%.2f C', minTemp);
screenOutput{end+1} = sprintf('Average temp\t%.2f C', avgTemp);
screenOutput{end+1} = sprintf('\n'); % Blank line

% Output end message
screenOutput{end+1} = sprintf('Data logging terminated');

% Line-by-line display to the command window
for k = 1:length(screenOutput)
    disp(screenOutput{k});
end

% 1e: Format output to file
disp(' ');
disp('Write to log file cabin_temperature.txt');
logFileName = 'cabin_temperature.txt';
fileID = fopen(logFileName, 'w'); % Open the file in write mode

if fileID == -1
    disp(['Error: Unable to open file ', logFileName, ' Perform a write.']);
else
    % Writes the contents of the screenOutput cell array line by line to a file.
    for k = 1:length(screenOutput)
        fprintf(fileID, '%s\n', screenOutput{k}); % Use %s to print a string and add newlines
    end
    fclose(fileID); % Close file
    disp(['Data has been successfully written to the file. ', logFileName]);

end

% Clearance
clear a; % Disconnect from Arduino
disp('The Arduino connection is closed.');
disp('End of Task 1');

% END OF TASK 1

%% TASK 2 - LED TEMPERATURE MONITORING DEVICE IMPLEMENTATION [25 MARKS]
disp('start Task 2');
clear a

% Connecting the Arduino
try
    a = arduino('COM3', 'Uno'); 
    disp('Arduino Connection Successful');
catch ME
    disp('Error: unable to connect to Arduino.');
    disp(ME.message)
    return; 
end

% Define pin number 
analogPin = 'A0';  
greenPin  = 'D9';   
yellowPin = 'D10';  
redPin    = 'D11';  


%Calling the Temperature Monitor Function/
disp('Start temperature monitoring system (press Ctrl+C to stop).....');
try
    temp_monitor(a, analogPin, greenPin, yellowPin, redPin);
catch ME
    disp('The monitor function is interrupted or has an error.');
    % Make sure the LED is off
     writeDigitalPin(a, greenPin, 0);
     writeDigitalPin(a, yellowPin, 0);
     writeDigitalPin(a, redPin, 0);
     disp('All LEDs are off.');
    
end

% Cleanup (usually handled inside a function or on interrupt) --
% clear a; % is not cleared here, as the function may need it
disp('Task 2 ends (or is interrupted)');
% END OF TASK 2 
%% TASK 3 - ALGORITHMS – TEMPERATURE PREDICTION [25 MARKS]
clear a
disp('Commencement of Task 3');

% Connecting the Arduino
try
    a = arduino('COM3', 'Uno'); 
    disp('Arduino Connection Successful');
catch ME
    disp('Error: unable to connect to Arduino.');
    disp(ME.message)
    return; 
end


% Define Pin Number
analogPin     = 'A0';   
% Select pin for rate indication
greenPinRate  = 'D9';   
yellowPinRate = 'D10';  
redPinRate    = 'D11';  


% Calling temperature prediction functions
disp('Start temperature prediction system (press Ctrl+C to stop)...');
try
    temp_prediction(a, analogPin, greenPinRate, yellowPinRate, redPinRate);
catch ME
    disp('The prediction function is interrupted or has an error.');
    % Make sure the LED is off
    writeDigitalPin(a, greenPinRate, 0);
    writeDigitalPin(a, yellowPinRate, 0);
    writeDigitalPin(a, redPinRate, 0);
    disp('All rate LEDs are off.');
end

% Cleanup (optional, onCleanup is usually handled within a function)
% clear a;
disp('Task 3 terminated (or interrupted)');

% END OF TASK 3 



%% TASK 4 - REFLECTIVE STATEMENT [5 MARKS]

%
% This coursework provided a valuable opportunity to apply MATLAB knowledge
% learned in lectures to a practical hardware control problem. Overall, I managed
% to implement the core functionalities, but encountered several challenges along the way.
%
% Challenges:
% The primary challenge was managing the noise in the temperature sensor readings.
% Initially, the values fluctuated significantly, affecting the stability of the
% LED indicators and the accuracy of the rate-of-change calculation. Researching
% potential causes led me to implement both a hardware solution (adding a
% decoupling capacitor) and a software one (multi-sampling averaging), which
% noticeably improved the stability. Understanding the `onCleanup` function and
% ensuring proper resource de-allocation upon interruption (Ctrl+C) also required
% careful attention.
%
% Strengths:
% I believe I was effective in breaking down the tasks and implementing the
% required features incrementally. I focused on writing readable code, incorporating
% comments to explain the logic in key sections. Implementing the live data
% plotting using MATLAB's graphics functions was also a part I handled relatively well.
%
% Limitations:
% A key limitation is the simplistic nature of the temperature prediction in Task 3,
% which uses a linear extrapolation based only on the recent trend. This might not
% be reliable for predicting temperatures during more complex thermal events.
% Furthermore, the error handling is quite basic; for example, it doesn't specifically
% address scenarios like the Arduino becoming disconnected mid-operation. The physical
% wiring, while functional, could also be neater.
%
% Future Improvements:
% If time permitted, exploring more advanced filtering algorithms, such as a moving
% average or perhaps even an exponential smoothing filter, could yield smoother
% temperature data and potentially a more reliable rate calculation. Another enhancement
% could be to develop a basic Graphical User Interface (GUI) to display the
% temperature, status, and graph, making it more intuitive than command-line output.
% Refactoring some of the repeated code (like LED control logic) into helper
% functions could also improve code organisation.
%
% In summary, this project enhanced my programming, hardware interfacing, and
% problem-solving skills.
%

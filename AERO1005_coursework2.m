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

% Insert answers here

%% TASK 2 - LED TEMPERATURE MONITORING DEVICE IMPLEMENTATION [25 MARKS]

% Insert answers here


%% TASK 3 - ALGORITHMS – TEMPERATURE PREDICTION [25 MARKS]

% Insert answers here


%% TASK 4 - REFLECTIVE STATEMENT [5 MARKS]

% Insert answers here
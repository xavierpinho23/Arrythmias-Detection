clear
close all

cd DATPVC
mat = dir('*.mat'); 
file = {};
ecgs = {};
for q = 1:length(mat) 
    file{q} = load(mat(q).name); 
    ecgs{q} = file{1,q}.DAT.ecg;
end

fs = 250;   %.. sampling time - 250Hz
W  = 25*fs;  %.. window  = 5 seconds  

%% Normalize ecgs
for i=1:size(ecgs)
    
    ecgs{i} = normalize(ecgs{i});
end

%% Signal Processing
energy_ecgs = ecgs;
for i=1:size(ecgs)
    % Low-pass filter
    order = 4;
    wc = 15;
    fc = wc / (0.5 * fs);
    [b, a]=butter(order, fc);
    e1 = filter(b, a, ecgs{i});
    
    % High-pass filter
    wc = 5;
    fc = wc / (0.5 * fs);
    [b,a] = butter(order, fc,'High');
    e2 = filter(b, a, e1);

    % Differentiation + Potentiation (squared-root)
    e3 = diff(e2);
    e3 = abs(e3);
    
    e4 = e3.^0.5;
    
    % Moving Average
    timeWindow = 0.2;
    N = timeWindow*fs;
    b = (1/N)*ones(N,1);
    a = 1;
    energy_ecgs{i} = filter(b, a, e4);
    
end

%% Find Peaks

peak_idx = {};
for i=1:size(energy_ecgs,2)
    minPeakHeight = 1.15*mean(energy_ecgs{i}); %Changed because 0.7*mean was too low threashold
    pause1 = 0.4*fs; %Max 150 batidas/min
    [pks,locs] = findpeaks(energy_ecgs{i},'MinPeakHeight',minPeakHeight,'MinPeakDistance',pause1);
    peak_idx{i} = locs;
end

%% Solve Delay

back = 0.2*fs;
pred_peak_idx = {};


for i=1:size(peak_idx,2)
    Is = [];
    
    for j=2:size(peak_idx{i})
        [M,I] = max(ecgs{i}(peak_idx{i}(j)-back:peak_idx{i}(j)));
        I = I + peak_idx{i}(j)-back;
        Is = [Is; I];
        
    end
    pred_peak_idx{i} = Is;
    
    size(peak_idx{i})
    size(pred_peak_idx{i})
end


%% Print information

output = {};
for i=1:size(pred_peak_idx,2)
    output{i,1} = size(energy_ecgs{i},1)/fs;
    output{i,2} = size(pred_peak_idx{i},1);
    output{i,3} = (output{i,2}/output{i,1})*60;
    
    disp("For patient "+i+": ")
    disp("Duration: " + output{i,1} + " sec.")
    disp("Num Beats: " + output{i,2} + " beats.")
    disp("Beats/min: " + output{i,3})
    disp(" ")
end

%% Analyse Results

results = {};

real_peak_idx = {};
for i=1:size(file,2)
    real_peak_idx{i} = file{1,i}.DAT.ind;
end

for i=1:size(pred_peak_idx,2)
    
    TP = 0;
    FP = 0;
    FN = 0;

    for j=1:size(pred_peak_idx{i},1)
        pred_peak = pred_peak_idx{i}(j);

        diff = abs(real_peak_idx{i} - pred_peak);
        search = find(diff<30);
        
        if (~isempty(search))
            TP = TP +1;
        else 
            FP = FP +1;
        end
    end
    
    results{i,1} = TP;
    results{i,2} = FP;
    results{i,3} = abs(size(real_peak_idx{i},1)-TP);
    results{i,4} = (TP/(TP+results{i,3}))*100; %Recall
    results{i,5} = (TP/(TP+FP))*100; %Precision
    results{i,6} = 2*((results{i,5}*results{i,4})/(results{i,5}+results{i,4})); %F1-Score
end
            
%% Visualize Peaks

for i=1:size(pred_peak_idx,2)
    t = (1:size(ecgs{i},1))./fs;
    plot(t,ecgs{i})
    hold on
    idx = pred_peak_idx{i}./fs;
    
    plot(idx,ecgs{i}(pred_peak_idx{i}),'o');
    pause;
end





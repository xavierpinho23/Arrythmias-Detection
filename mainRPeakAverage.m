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

%% Peaks
real_peak_idx = {};
for i=1:size(file,2)
    real_peak_idx{i} = file{1,i}.DAT.ind;
end

%% Split signals
splitted_ecgs = {};
for i=1:size(ecgs,2)
    num_peaks = size(real_peak_idx{i},1);
    num_points = size(ecgs{i},1);
    mean_distance = num_points/num_peaks;
    go_back = round(mean_distance/3);
    go_forward = round(mean_distance*2/3);
    
    for j=2:num_peaks-1
        if (real_peak_idx{i}(j)-go_back>0)
            split = ecgs{i}((real_peak_idx{i}(j)-go_back):(real_peak_idx{i}(j)+go_forward));
            splitted_ecgs{i,j} = split;
        end
    end
end

%% Normalize Signals
for i=1:size(ecgs,2)
    for j=1:size(splitted_ecgs,2)
        if (~isempty(splitted_ecgs{i,j}))
            splitted_ecgs{i,j} = normalize(splitted_ecgs{i,j});
        end
    end
end

%% Average of signals
average_signals = {};
for i=1:size(ecgs,2)
    A = [];
    for j=1:size(splitted_ecgs,2)
        if (~isempty(splitted_ecgs{i,j}))
            A = [A;splitted_ecgs{i,j}'];
        end
    end
    M = mean(A);
    average_signals{i} = M;
end
       
%% Mean Squared Error
threshold = [0.8,0.7,0.6,0.5,0.4, 0.3, 0.2];
count = {};


cell_errors = {};
for i=1:size(ecgs,2)
    errors = [];
    
    count{i} = 0;
    
    for j=1:size(splitted_ecgs,2)
        if (~isempty(splitted_ecgs{i,j}))
            error = immse(splitted_ecgs{i,j}',average_signals{i});
            errors = [errors, error];
            count{i} = count{i} + 1;
        else
            errors = [errors, NaN];
        end
        
    end
    cell_errors{i} = errors;
end






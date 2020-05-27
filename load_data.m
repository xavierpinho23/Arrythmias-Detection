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

%-------------------------------------
fs = 250;   %.. sampling time - 250Hz
W  = 25*fs;  %.. window  = 5 seconds 
%-------------------------------------
% Low pass filter
order = 4;
wc = 15;
fc = wc / (0.5 * fs);
[b1, a1] = butter(order, fc);
%-------------------------------------
% High pass filter
order = 4;
wc = 5;
fc = wc / (0.5 * fs);
[b2,a2] = butter(order, fc,'High');
%-------------------------------------
timeWindow = 0.2;
N = 650000;
b3 = (1/N)*ones (1, N);
a3 = 1;
%-------------------------------------
ECG = {};
PVC = {};
Rpeaks = {};
for i=1:length(list)
    cmd=['load ' char(list(i)) ];
    eval(cmd);   
    ECG  = [ECG DAT.ecg];
    Rpeaks = [Rpeaks DAT.ind];
    PVC = [PVC DAT.pvc];
    e1 = filter(b1,a1,cell2mat(ECG(1,i))); %low pass
    e2 = filter(b2,a2,e1); % high pass
    e3 = diff(e2); % differentiation
    e4 = e3.^2; % potentiation
    e5 = filter (b3, a3, e4); % moving average
    N = length(e5);
    plot(1:N,e5)
    zoom on
    pause
 
end
close all;
clear;


T = readtable("bbs32_rtl_results.csv");
Bnum = height(T);

res1 = table2array(T);
res = transpose(res1);
res_ones = 2 .* res - 1;

%**************************************************************************
%Frequency (Monobit) Test (2.1)
%**************************************************************************
disp(" ")
disp("**************************************************************************");
disp("Frequency (Monobit) Test (2.1)");

sum_all = sum(res_ones, "all");
%Compute the test statistic
s_obs = abs(sum_all)/sqrt(Bnum);
%Compute P-value
p1_val = erfc(s_obs/sqrt(2));
fprintf("P-value is %f\n", p1_val);
test_p_value(p1_val);


%**************************************************************************
%Discrete Fourier Transform (Spectral) Test (2.6)
%**************************************************************************
disp(" ")
disp("**************************************************************************");
disp("Discrete Fourier Transform (Spectral) Test (2.6)");

res_fft = fft(res_ones);
res_fft_half = res_fft(1,1:Bnum/2);
f = (0:length(res_fft_half)-1)*100/length(res_fft_half);        % Frequency vector

mag = abs(res_fft_half);
phas = unwrap(angle(res_fft_half));

subplot(2,2,1);
plot(f,res_fft_half);
grid on
title('DFT raw');

subplot(2,2,2);
area(f,mag);
grid on
title('Magnitude');

subplot(2,2,3);
plot(f,phas);
grid on
title('Phase');

%Use only half of all results
%res_fft_half = res_fft(1,1:Bnum/2);
%Calculate M = modulus(S´) ≡ |S'|, where S´ is the substring consisting of the first n/2 elements
s_mod = abs(res_fft_half);
%Peak height threshold value
treshold = sqrt(log2(1/0.05)*Bnum);
fprintf("Threshold = %f\n", treshold);
%expected theoretical (95 %) number of peaks
n0 = 0.95*Bnum/2;
%the actual observed number of peaks
n1 = get_n1(s_mod, treshold);
fprintf("N0 = %u\n", n0);
fprintf("N1 = %u\n", n1);

%Compute d
d_val = (n1-n0)/sqrt(Bnum*0.95*0.05/4);
fprintf("d = %f\n", d_val);

%Compute P-value
p_val = erfc(abs(d_val)/sqrt(2));

fprintf("P-value is %f\n", p_val);
test_p_value(p_val);




%Functions definitions ****************************************************

function res = test_p_value(p_in)
    if (p_in >= 0.01)
        disp("Sequence is random, P >= 0.01");
        res = 1;
    else
        disp("Sequence is NOT random, P < 0.01");
        res = 0;
    end
end

function n1_num = get_n1(fft_abs, treshold)
    n1_num = 0;
    for itr=1:length(fft_abs)
        if fft_abs(itr) < treshold
            n1_num = n1_num + 1;
        end
    end
end
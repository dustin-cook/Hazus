function [ B_hyst_new, Sd, Sa ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av, T_vd, sa_s, sa_1, capacity_curve, capacity_curve_data )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Import Packages
import hazus.*

%% Demand Spectra Factors
R_a = 2.12/(3.21-0.68*log(B_eff));
R_v = 1.65/(2.31-0.41*log(B_eff));

% Calculate Demand Spectra 
T_av_beta = T_av .* (R_a/R_v); % hazus says to use B_tavb which is the value of effective damping at the transition period, but Beta does not seem to be a function of Period
hazus_spectra.periods = [0,linspace(T_av_beta,T_vd,45),linspace(T_vd*1.05,2*T_vd,4)];
hazus_spectra.sa = [sa_s/R_a,(sa_1./linspace(T_av_beta,T_vd,45))/R_v,(sa_1*T_vd./(linspace(T_vd*1.05,2*T_vd,4).^2))/R_v]; 
hazus_spectra.sd = 9.8 * hazus_spectra.sa .* hazus_spectra.periods .^2;

% Extend capacity curve beyond spectra
if max(capacity_curve.x) < max(hazus_spectra.sd)
    capacity_curve.x(end + 1) = max(hazus_spectra.sd)*1.1;
    capacity_curve.y(end + 1) = capacity_curve.y(end);
end

% Extend spectra beyond capacity curve
if max(capacity_curve.y) < min(hazus_spectra.sa)
    hazus_spectra.sa(end+1) = 0;
    hazus_spectra.sd(end+1) = hazus_spectra.sd(end);
    hazus_spectra.periods(end+1) = inf;
end

%% Find Perfromance Point Capacity Curve and Demand Spectra Intersection
interX_points = InterX([hazus_spectra.sd;hazus_spectra.sa],[capacity_curve.x;capacity_curve.y]);
Sd = interX_points(1);
Sa = interX_points(2); 

% %% Plot Demand Spectra and Capacity Curve
% hold on
% plot([capacity_curve.x],[capacity_curve.y])
% plot(hazus_spectra.sd,hazus_spectra.sa)
% scatter(Sd,Sa,'filled')
% xlim([0,max(hazus_spectra.sd)])

%% Re-calculate historetic factor for damping
area = max([4*Sa*(Sd-capacity_curve_data.d_y*(Sa/capacity_curve_data.a_y)),0]); % EQ 23 of Porter's "Cracking the Open Safe"
historetic_factor = area/(2*Sd*Sa);
B_hyst_new = k*historetic_factor*100/pi;

end


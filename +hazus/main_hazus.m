function [ loss ] = main_hazus( building_type, occupancy, level_of_code, spectra, analysis, vs30, period )
%
% Function to predict losses using HAZUS MH 2.1 using full demand spectrum
% and capacity curve method
%
% Created by Dustin Cook
% August 4, 2018
% 
% INPUT VARIABLES:
%

%% Initial Setup
% Import Packages
import hazus.*

%% Define Optional Inputs
% Number or Sims
if ~isfield(analysis,'num_reals')
    analysis.num_reals = 1;
end

% Hazus aebm option
if ~isfield(analysis,'aebm')
    analysis.aebm = 0;
end

% Value within range of elastic damping
if ~isfield(analysis,'Be_ratio')
    analysis.Be_ratio = 0.5;
end

%% Load Databases
load(['+hazus' filesep 'data_hazus' filesep 'data_capacity_curve.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'data_nonstructural_accel_damage_curve.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'data_nonstructural_drift_damage_curve.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'data_structural_damage_curve.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'hazus_repair_cost_damage_state.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'data_spectra_hysteretic_degradation_factor_k.mat'])
load(['+hazus' filesep 'data_hazus' filesep 'data_hazus_building_type.mat'])

% Filter hazus data tables fro this building class
build_type_data = hazus_building_type(strcmp(hazus_building_type.build_type,building_type),:);
capacity_curve_data = capacity_curve_table(strcmp(capacity_curve_table.loc,level_of_code) & strcmp(capacity_curve_table.build_type,building_type),:);
hazus_cost_ds = hazus_cost_ds_table(strcmp(hazus_cost_ds_table.hazus_label,occupancy),:);
k_raw = hysteretic_degradation_cappa_table(strcmp(hysteretic_degradation_cappa_table.loc,level_of_code) & strcmp(hysteretic_degradation_cappa_table.build_type,building_type),:);
structural_damage_curves = structural_damage_curve_table(strcmp(structural_damage_curve_table.loc,level_of_code) & strcmp(structural_damage_curve_table.build_type,building_type),:);
nonstructural_drift_damage_curves = nonstructural_drift_damage_curve_table(strcmp(nonstructural_drift_damage_curve_table.loc,level_of_code) & strcmp(nonstructural_drift_damage_curve_table.build_type,building_type),:);
nonstructural_accel_damage_curves = nonstructural_accel_damage_curve_table(strcmp(nonstructural_accel_damage_curve_table.loc,level_of_code) & strcmp(nonstructural_accel_damage_curve_table.build_type,building_type),:);

%% Calculate demand Spectra (Hazus Section 5.6.2.1)
% Calculate Hazus simplified spectra parameters 
sa_s = interp1(spectra.periods',spectra.sa',0.3);
sa_1 = interp1(spectra.periods',spectra.sa',1.0);
% sa_T = interp1(spectra.periods',spectra.sa',period);
T_av = sa_1 ./ sa_s;
% T_av = ones(1,7)*0.34;
% T_av = ones(1,7)*0.71;
T_vd = 10*ones(1,length(sa_s));

%% Select Magnitude using Boore Joyner and Fumal attenuation model
% assuming 20km distance
% assuming strike-slip fault
% period is less than 2 seconds
% mag_range = 0:10;
% for mag = 1:length(mag_range) 
%     [sa_bjf(mag), ~] = fn_BJF_1997_horiz(mag_range(mag), 20, min(period,2), 1, vs30, 0); % Limit Period to 2s for this function
% end
        
%% Run for each hazard level
for im = 1:length(sa_s)
    %% Develop Capacity Curve
    dy = capacity_curve_data.d_y;
    du = capacity_curve_data.d_u;
    ay_med = capacity_curve_data.a_y;
    au_med = capacity_curve_data.a_u;
    if strcmp(level_of_code,'pre')
        beta = 0.3;
    else
        beta = 0.25;
    end
    
    %% Simulate Capacity Curve
    for sim = 1:analysis.num_reals
%         au = lognrnd(log(au_med),beta);
        au = au_med;
        ay = ay_med*(au/au_med);
        capacity_curve.x(1:2) = [0,dy];
        capacity_curve.y(1:2) = [0,ay];
        capacity_curve.x(2:24) = linspace(dy,du,23);
        b = (dy*(ay-au)^2 - (dy-du)*ay*(ay-au))/((dy-du)*ay - 2*dy*(ay-au)); % Curve logic based on Porter paper
        a = sqrt((-dy*(dy-du)*b^2)/(ay*(ay-au+b)));
        a_0 = au - b;
        capacity_curve.y(2:24) = a_0 + b*sqrt(1-((capacity_curve.x(2:24) - capacity_curve_data.d_u).^2)/(a^2));
        capacity_curve.x(25) = du*100;
        capacity_curve.y(25) = au;

        % Determine duration based on magnitude per Porter "cracking open safe"
%         magnitude = interp1(sa_bjf, mag_range, sa_T(im));
%         if magnitude <= 5.5
%             kappa_duration = 'short';
%         elseif magnitude <= 7.5
            kappa_duration = 'moderate';
%         else
%             kappa_duration = 'long';
%         end
        
        
        %% Modification factors for PESH Spectra to Demand Spectra
        if analysis.aebm
            k = k_raw.([kappa_duration '_aebm']); % Assume ordinary quality per hazus aebm table 5.2
            B_e = build_type_data.aebm_yield_damping_low + analysis.Be_ratio*(build_type_data.aebm_yield_damping_high - build_type_data.aebm_yield_damping_low); % elastic damping based on hazus AEBM table 5.1
        else
            k = k_raw.(kappa_duration);   
            B_e = build_type_data.newmark_yield_damping_low + analysis.Be_ratio*(build_type_data.newmark_yield_damping_high - build_type_data.newmark_yield_damping_low); % elastic damping based on newmark and hall 1982 table 3 (per Hazus)
        end
        B_hyst = -1;
        tol_dec = 1;
        % Iterate to find demand spectra (need to upgrade such that it iterates to go from the point where input B > output B)
        for iter_1 = 1:50
            step = 1;
            B_hyst = B_hyst + step;
            B_eff = B_hyst+B_e;
            [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
            if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                break
            elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                B_hyst = B_hyst - step;
                for iter_2 = 1:10
                    step = 0.1;
                    B_hyst = B_hyst + step;
                    B_eff = B_hyst+B_e;
                    [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                    if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                        break
                    elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                        B_hyst = B_hyst - step;
                        for iter_3 = 1:10
                            step = 0.01;
                            B_hyst = B_hyst + step;
                            B_eff = B_hyst+B_e;
                            [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                            if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                                break
                            elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                                B_hyst = B_hyst - step;
                                for iter_4 = 1:10
                                    step = 0.001;
                                    B_hyst = B_hyst + step;
                                    B_eff = B_hyst+B_e;
                                    [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                                    if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                                        break
                                    elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                                        B_hyst = B_hyst - step;
                                        for iter_5 = 1:10
                                            step = 0.0001;
                                            B_hyst = B_hyst + step;
                                            B_eff = B_hyst+B_e;
                                            [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                                            if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                                                break
                                            elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                                               B_hyst = B_hyst - step;
                                                for iter_6 = 1:10
                                                    step = 0.00001;
                                                    B_hyst = B_hyst + step;
                                                    B_eff = B_hyst+B_e;
                                                    [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                                                    if round(B_hyst_new+B_e,1) == round(B_eff,1)
                                                        break
                                                    elseif round(B_hyst_new+B_e,tol_dec) < round(B_eff,tol_dec)
                                                       B_hyst = B_hyst - step;
                                                        for iter_7 = 1:11
                                                            step = 0.000001;
                                                            B_hyst = B_hyst + step;
                                                            B_eff = B_hyst+B_e;
                                                            [ B_hyst_new, ~, ~ ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );
                                                            if round(B_hyst_new+B_e,tol_dec) == round(B_eff,tol_dec)
                                                                break
                                                            elseif iter_7 == 11
                                                                warning('Failed to Converge')
                                                            end
                                                        end
                                                        break
                                                    end
                                                end
                                                break
                                            end
                                        end
                                        break
                                    end
                                end
                                break
                            end
                        end
                        break
                    end
                end
                break
            end
        end

        % Once Found Use Rounded B value to find Sd and Sa
        B_eff = round(B_hyst_new+B_e,1);
        [ ~, Sd, Sa ] = fn_iterate_hazus_demand_spectrum( B_eff, k, T_av(im), T_vd(im), sa_s(im), sa_1(im), capacity_curve, capacity_curve_data );

        %% Find Damage State Probabilities and Calualate Loss
        [ structural_loss(sim,im) ] = fn_calc_hazus_loss( structural_damage_curves, hazus_cost_ds, Sd, 'structural' );
        [ nonstructural_drift_loss(sim,im) ] = fn_calc_hazus_loss( nonstructural_drift_damage_curves, hazus_cost_ds, Sd, 'nonstructural_drift' );
        [ nonstructural_accel_loss(sim,im) ] = fn_calc_hazus_loss( nonstructural_accel_damage_curves, hazus_cost_ds, Sa, 'nonstructural_accel' );
    end
end

% Calculate Total Loss
total_loss = structural_loss + nonstructural_drift_loss + nonstructural_accel_loss;
loss.total.mean = total_loss;
loss.structural.mean = structural_loss;
loss.nonstructural_drift.mean = nonstructural_drift_loss;
loss.nonstructural_accel.mean = nonstructural_accel_loss;

end


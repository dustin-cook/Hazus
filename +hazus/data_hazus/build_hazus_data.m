%% Scrip to translate code factor data into matlab structures
clear
close all
clc 
rehash
rng('shuffle')

%% Load the building type data into 
capacity_curve_table = readtable('data_capacity_curve.csv','ReadVariableNames',true);
structural_damage_curve_table = readtable('data_structural_damage_curve.csv','ReadVariableNames',true);
nonstructural_drift_damage_curve_table = readtable('data_nonstructural_drift_damage_curve.csv','ReadVariableNames',true);
nonstructural_accel_damage_curve_table = readtable('data_nonstructural_accel_damage_curve.csv','ReadVariableNames',true);
hysteretic_degradation_cappa_table = readtable('data_spectra_hysteretic_degradation_factor_k.csv','ReadVariableNames',true);
hazus_cost_ds_table = readtable('hazus_repair_cost_damage_state.csv','ReadVariableNames',true);
hazus_level_of_code = readtable('data_hazus_level_of_code.csv','ReadVariableNames',true);
hazus_building_type = readtable('data_hazus_building_type.csv','ReadVariableNames',true);

%% save data to matlab file
% save('data_capacity_curve.mat','capacity_curve_table')
% save('data_structural_damage_curve.mat','structural_damage_curve_table')
% save('data_nonstructural_drift_damage_curve.mat','nonstructural_drift_damage_curve_table')
% save('data_nonstructural_accel_damage_curve.mat','nonstructural_accel_damage_curve_table')
save('data_spectra_hysteretic_degradation_factor_k.mat','hysteretic_degradation_cappa_table')
% save('hazus_repair_cost_damage_state.mat','hazus_cost_ds_table')
save('data_hazus_building_type.mat','hazus_building_type')
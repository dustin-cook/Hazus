function [ loss ] = main_hazus_rail_station( build_type, code_level, pga, pgd )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Hazus Notes
% The reference spectrum represents ground
% shaking of a large-magnitude (i.e., M ? 7.0) western United States (WUS) earthquake for soil
% sites (e.g., Site Class D) at site-to-source distances of 15 km, or greater
% uncertainty in the damage?state threshold of the structural system Beta_M(SPGA) = 0.4 for all building types and damage states),
% variability in response due to the spatial variability of ground motion demand B_D(V) = 0.5 for long?period spectral response).

%% Initial Setup
% Import packages
import hazus.sim_hazus_ds
import hazus.fn_hazus_loss

% Load data
eq_pga_data = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_eq_pga_datatable.csv']);
consequence_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_consequence.csv']);
fragility_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_fragility.csv']);

%% Pull and filter databases
% Define Building Fragility from ground shaking
filt = strcmp(eq_pga_data.loc,code_level) & strcmp(eq_pga_data.build_type,build_type);
fragility_data_eq_pga = eq_pga_data(filt,:);

% Define Building Fragility from PGD for stations
fragility_data = fragility_table(strcmp(fragility_table.lifeline_class,'RST'),:);

% Define Buildng Fragility from PGD for tunnels

% Define Consequence
consequence_data = consequence_table(strcmp(consequence_table.lifeline_type,'RST'),:);

%% Calculate Building Damage
n_sims = 10000;

% Loss from ground shaking
[ ds_pga ] = sim_hazus_ds( fragility_data_eq_pga, pga, n_sims );

% Loss from lateral spreading
fragility_data_lat_spread = fragility_data(strcmp(fragility_data.hazard,'lateral spread'),:);
[ ds_lat_spread ] = sim_hazus_ds( fragility_data_lat_spread, pgd, n_sims );

% Loss from vertical settlement
fragility_data_settlement = fragility_data(strcmp(fragility_data.hazard,'vertical settlement'),:);
[ ds_settlement ] = sim_hazus_ds( fragility_data_settlement, pgd, n_sims );

% Loss from fault rupture
fragility_data_rupture = fragility_data(strcmp(fragility_data.hazard,'fault rupture'),:);
[ ds_rupture ] = sim_hazus_ds( fragility_data_rupture, pgd, n_sims );

% Loss from landslide
fragility_data_landslide = fragility_data(strcmp(fragility_data.hazard,'landslide'),:);
[ ds_landslide ] = sim_hazus_ds( fragility_data_landslide, pgd, n_sims );

% Combine damage state probailities using total probability theorem
ds_sim_total = ds_pga | ds_lat_spread | ds_settlement | ds_rupture | ds_landslide;
prob_ds_exceed = mean(ds_sim_total);

% damage state probabilities
prob_ds = prob_ds_exceed - [prob_ds_exceed(2:end),0];

%% Calculate Building Loss
[ loss ] = fn_hazus_loss( prob_ds, consequence_data, 'mean_recovery_days' );

end


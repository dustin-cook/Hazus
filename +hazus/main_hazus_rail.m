function [ loss, prob_ds ] = main_hazus_rail( comp )
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

% Define number of sims to run for combinding pga and pgd data
n_sims = 10000;

% Load and filter eq pga data
if strcmp(comp.lifeline_type,'RST') % only for stations use equivalent pga data
    eq_pga_data = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_eq_pga_datatable.csv']);
    filt = strcmp(eq_pga_data.loc,comp.code_level) & strcmp(eq_pga_data.build_type,comp.build_type);
    fragility_data_eq_pga = eq_pga_data(filt,:);
end

% Load and filter fragility data
fragility_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_fragility.csv']);
fragility_data = fragility_table(strcmp(fragility_table.lifeline_class,comp.lifeline_class),:);

% Load and filter consequence data
consequence_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_consequence.csv']);
consequence_data = consequence_table(strcmp(consequence_table.lifeline_type,comp.lifeline_type),:);

%% Calculate Building Damage based on ground shaking
if strcmp(comp.lifeline_type,'RST') % only for stations use equivalent pga data
    [ ds_pga ] = sim_hazus_ds( fragility_data_eq_pga, comp.pga, n_sims );
elseif any(ismember(fragility_data.intensity_measure,'pga')) % for other rail network components sensitive to pga
    fragility_data_pga = fragility_data(strcmp(fragility_data.intensity_measure,'pga'),:);
    [ ds_pga ] = sim_hazus_ds( fragility_data_pga, comp.pga, n_sims );
else
    ds_pga = false(n_sims,4);
end

%% Calculate Building Damage based on ground failure
% Simulate ground failure occurances
sim_liq = rand(n_sims, 1) < comp.p_liq; % Simulate which realizations have liquefaction
sim_land = rand(n_sims, 1) < comp.p_land; % Simulate which realizations have landslide
sim_rupt = rand(n_sims, 1); % Simulate extent of surface fault rupture deformations (assuming uniform dist from 0 to max sf_rup)

% Damage from lateral spreading
filt = strcmp(fragility_data.hazard,'lateral spread') | strcmp(fragility_data.hazard,'ground failure');
fragility_data_filt = fragility_data(filt,:);
[ ds_lat_spread ] = sim_hazus_ds( fragility_data_filt, comp.pgd_lat, n_sims );

% Damage from vertical settlement
filt = strcmp(fragility_data.hazard,'vertical settlement') | strcmp(fragility_data.hazard,'ground failure');
fragility_data_filt = fragility_data(filt,:);
[ ds_settlement ] = sim_hazus_ds( fragility_data_filt, comp.pgd_set, n_sims );

% Damage from fault rupture
filt = strcmp(fragility_data.hazard,'fault rupture') | strcmp(fragility_data.hazard,'ground failure');
fragility_data_filt = fragility_data(filt,:);
pgd_rupt = comp.pgd_rup .* sim_rupt;
[ ds_rupture ] = sim_hazus_ds( fragility_data_filt, pgd_rupt, n_sims );

% Damage from landslide
filt = strcmp(fragility_data.hazard,'landslide') | strcmp(fragility_data.hazard,'ground failure');
fragility_data_filt = fragility_data(filt,:);
[ ds_landslide ] = sim_hazus_ds( fragility_data_filt, comp.pgd_lan, n_sims );

%% Combine damage state occurances
ds_sim_total = ds_pga | ds_lat_spread.*sim_liq | ds_settlement.*sim_liq | ds_rupture | ds_landslide.*sim_land;
prob_ds_exceed = mean(ds_sim_total);

% damage state probabilities
prob_ds = prob_ds_exceed - [prob_ds_exceed(2:end),0];

%% Calculate Building Loss
[ loss ] = fn_hazus_loss( prob_ds, consequence_data, 'mean_recovery_days' );

end


clear all
close all
clc
rehash


%% Intial setup
% Load model data
network_components = readtable(['inputs' filesep 'network_components.csv']);

% Load site data
site_info = readtable(['inputs' filesep 'site_info.csv']);

% Load Simupated Shakemap data
gm_sim = load(['inputs' filesep 'gms_sim_to_NIST.mat']);

% Define analysis settings
num_sites = height(site_info);
pga_idx = 1;

%% Calculate combined PGA and PGD data for each shakemap simulations
[gm_sim] = fn_map_data_add_pgd(gm_sim, site_info, pga_idx);

%% Run each model through hazus eq pga
for m = 1:height(network_components)
    asses_rail_comp(m, network_components, gm_sim, site_info, pga_idx)
end

%% Collect data into one table





function [] = asses_rail_comp(m, network_components, gm_sim, site_info, pga_idx)
    % Import Packages
    import hazus.*
    
    % Initialize parameters
    num_sims = gm_sim.n_scenarios;
    comp = table2struct(network_components(m,:));
    recovery_time_days = zeros(num_sims,1);
    
    % Pull site keys
    site_filt = site_info.locIdx == comp.locIdx;
    if any(site_filt) % no site info associated with this asset
        
        % Define site infor for this asset
        site = site_info(site_filt,:);

        % Pull Hazus building data for stations
        if strcmp(comp.lifeline_type,'RST')
            % Define transitionary Inputs
            [ building_type ] = fn_hazus_building_type( comp.building_type_id, comp.num_stories );
            comp.build_type = building_type.build_type;
            [ comp.code_level ] = fn_hazus_code_level( num2str(comp.hazus_zone), building_type, comp.year_of_construction );
        end

        for k = 1:num_sims
            fprintf('Running model %i of %i\n',k,num_sims)
            
            % Pull Simulated Shakemap Data
            comp.pga = gm_sim.imSims_combined.sa(pga_idx).imReals(k,site.locIdx);

            % Pull Shakemap data for this site
            comp.pgd_lat = gm_sim.imSims_combined.pgd_lf_spreading_expected_inches(k,site.locIdx);
            comp.pgd_set = gm_sim.imSims_combined.pgd_lf_settlment_expected_inches(k,site.locIdx);
            comp.pgd_lan = gm_sim.imSims_combined.pgd_ls_inches(k,site.locIdx);
            comp.pgd_rup = gm_sim.imSims_combined.pgd_lf_settlment_expected_inches(k,site.locIdx);
            comp.p_liq = gm_sim.imSims_combined.pgd_sf_rupt_median_inches(k,site.locIdx);
            comp.p_land = gm_sim.imSims_combined.landslide_prob(k,site.locIdx);

            % Calc losses for each asset
            [ recovery_time_days(k,1) ] = main_hazus_rail( comp );
        end
        
        % Save output data
        save_dir = ['outputs' filesep ];
        if ~exist(save_dir,'dir')
            mkdir(save_dir)
        end
        save([save_dir filesep 'modelID_' num2str(m) '.mat'], 'recovery_time_days')
    end
    
end
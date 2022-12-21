function [gm_sim] = fn_map_data_add_pgd(gm_sim, site_info, pga_idx)
%% Initial Setup
% Analysis options
% max_pga_threshold = 0.1; % remove maps with max pga smaller than this value (not used yet)
is_compute_pgd_liquefaction = 1;
is_compute_pgd_landslide = 1;
is_compute_pgd_surfacefaultrupture = 1;
dist_threshold_surface_fault_rupt = 0.25;
gmm_weights = [1 1 1]; % weighting to assign to each ground motion model for computing the final intensity map (this gets normalized later, so does not need to add up to 1.0 here)

% Define initial parameters
num_sims = gm_sim.n_scenarios;
num_sites = height(site_info);

%% Average the results from the three gm models 
%% Pre-calculations
% normalize the ground motion model (gmm) weights
if length(gmm_weights) == length(gm_sim.imSims)
    gmm_weights_norm = gmm_weights./ sum(gmm_weights);
else
    error('length of gmm wieghts not compatable with simulated IM data')
end

% Make intenisity maps for SA at each period, by computing a weighted average in log space
for period_index = 1:length(gm_sim.opensha_params.periods)
    temp_sum_logspace = zeros(size(gm_sim.imSims{1,1}(1).imReals));
    for gmm_index = 1:length(gmm_weights_norm)
        sa = gm_sim.imSims{1,gmm_index}(period_index).imReals;
        temp_sum_logspace = temp_sum_logspace + log(sa) * gmm_weights_norm(gmm_index);
    end
    gm_sim.imSims_combined.sa(period_index).imReals = exp(temp_sum_logspace);
end

% Set combined pga variable
pga_array = gm_sim.imSims_combined.sa(pga_idx).imReals;

%% compute liquefaction probability and pgd
if is_compute_pgd_liquefaction
    % moment magnitued correction factor (HAZUS 5.1 equation 4-10)
    k_m_vector = 0.0027 * gm_sim.scenarios_table.M.^3 ...
        - 0.0267 * gm_sim.scenarios_table.M.^2 ...
        - 0.2055 * gm_sim.scenarios_table.M ...
        + 2.9188;
    
    k_m_array = k_m_vector * ones(1,num_sites);
    
    % liquefaction unit fraction (HAZUS 5.1 Table 4-10)...
    % and conditional probability relationship for Liquefaction Suceptibility Catagories, P_sc_given_pga (HAZUS 5.1 Table 4-11)...
    % and proportion of map unit susceptible to liquefaciton, P_ml (HAZUS 5.1 Table 4-10)
    % and ground water correction factor, k_w (HAZUS 5.1 equation 4-11)
    % and liquefaction pga threshold, pga_threshold (HAZUS 5.1 Table 4-12)
    % and liquefaction characteristic settlement, lf_settlement (HAZUS 5.1 Table 4-13)
    
    P_sc_given_pga_array = zeros(num_sims,num_sites);
    k_w_array = zeros(num_sims,num_sites);
    P_ml_array = zeros(num_sims,num_sites);
    pga_threshold_array = zeros(num_sims,num_sites);
    lf_settlement_array = zeros(num_sims,num_sites);
    
    for i = 1:num_sites
        site = site_info(i,:);
        
        k_w_array(:, site.locIdx) = 0.022 * site.gound_water_depth + 0.93 ;
        
        if strcmp(site.liquefaction_susceptibility, 'Very High')
            P_sc_given_pga_array(:, site.locIdx) = max(min(9.09 * pga_array(:, site.locIdx) - 0.82, 1), 0);
            P_ml_array(:, site.locIdx) = 0.25;
            pga_threshold_array(:, site.locIdx) = 0.09;
            lf_settlement_array(:, site.locIdx) = 12;
        elseif strcmp(site.liquefaction_susceptibility, 'High')
            P_sc_given_pga_array(:, site.locIdx) = max(min(7.67 * pga_array(:, site.locIdx) - 0.92, 1), 0);
            P_ml_array(:, site.locIdx) = 0.20;
            pga_threshold_array(:, site.locIdx) = 0.12;
            lf_settlement_array(:, site.locIdx) = 6;
        elseif strcmp(site.liquefaction_susceptibility, 'Moderate')
            P_sc_given_pga_array(:, site.locIdx) = max(min(6.67 * pga_array(:, site.locIdx) - 1.0, 1), 0);
            P_ml_array(:, site.locIdx) = 0.10;
            pga_threshold_array(:, site.locIdx) = 0.15;
            lf_settlement_array(:, site.locIdx) = 2;
        elseif strcmp(site.liquefaction_susceptibility, 'Low')
            P_sc_given_pga_array(:, site.locIdx) = max(min(5.57 * pga_array(:, site.locIdx) - 1.18, 1), 0);
            P_ml_array(:, site.locIdx) = 0.05;
            pga_threshold_array(:, site.locIdx) = 0.21;
            lf_settlement_array(:, site.locIdx) = 1;
        elseif strcmp(site.liquefaction_susceptibility, 'Very Low')
            P_sc_given_pga_array(:, site.locIdx) = max(min(4.16 * pga_array(:, site.locIdx) - 1.08, 1), 0);
            P_ml_array(:, site.locIdx) = 0.02;
            pga_threshold_array(:, site.locIdx) = 0.26;
            lf_settlement_array(:, site.locIdx) = 0;
        elseif strcmp(site.liquefaction_susceptibility, 'None')
            P_sc_given_pga_array(:, site.locIdx) = 0;
            P_ml_array(:, site.locIdx) = 0;
            pga_threshold_array(:, site.locIdx) = 9999;
            lf_settlement_array(:, site.locIdx) = 0;
        else
            error('liquefaction susceptibility catagorie not found')
        end
        
    end
    
    gm_sim.imSims_combined.liquefaction_prob = P_sc_given_pga_array./ k_m_array./ k_w_array.* P_ml_array;
    
    % displacement correction factor (HAZUS 5.1 equation 4-13)
    k_delta_vector = 0.0086 * gm_sim.scenarios_table.M.^3 ...
        - 0.0914 * gm_sim.scenarios_table.M.^2 ...
        + 0.4698 * gm_sim.scenarios_table.M ...
        - 0.9835;
    
    k_delta_array = k_delta_vector * ones(1,num_sites);
    
    pga_ratio = pga_array ./ pga_threshold_array;
    
    % compute the expected displacment due to liquefaction lateral
    % spreading for magnitude 7.5 (HAZUS 5.1 figure 4-9)
    displacment_M75_inches = interp1([-1 1 2 3 4], [0 0 12 30 100], pga_ratio, 'linear', 'extrap');
    
    % apply the correction
    gm_sim.imSims_combined.pgd_lf_spreading_expected_inches = k_delta_array.* displacment_M75_inches; 
    
    gm_sim.imSims_combined.pgd_lf_settlment_expected_inches = gm_sim.imSims_combined.liquefaction_prob.* lf_settlement_array;
 
end

%% compute landslide  pgd
if is_compute_pgd_landslide 
    % critical accelerations for landslide from HAZUS 5.1 Table 4-16
    critical_accel_ls = [9999 0.6 0.5 0.4 0.35 0.3 0.25 0.2 0.15 0.1 0.05];
    
    % HAZUS 5.1 Table 4-17, percentage of map area having
    % landslide-susceptible deposit
    map_area_ls = [0 0.01 0.02 0.03 0.05 0.08 0.1 0.15 0.2 0.25 0.3];
    
    % number of cycles
    n = 0.3419 * gm_sim.scenarios_table.M.^3 ...
        - 5.5214 * gm_sim.scenarios_table.M.^2 ...
        + 33.6154 * gm_sim.scenarios_table.M ...
        - 70.7692;
    n_array = n * ones(1,num_sites);
    
    % expected displacment factor (from HAZUS 5.1, Figure 4-13)
    acceleration_ratio_reference = [0.1 0.2 0.3 0.4 0.5 0.6 0.7  0.8 0.9];
    displacement_factor_cm_lower_reference = [23  12  6.8 3.3 1.8 0.8 0.22 0.1 0.02];
    displacement_factor_cm_upper_reference = [41  20  11  4.2 2.9 1.4 0.5  0.2 0.04];
    
    % populate the critical accleration at each site
    critical_accel_array = zeros(num_sims,num_sites);
    gm_sim.imSims_combined.landslide_prob = zeros(num_sims,num_sites);
    for i = 1:num_sites
        site = site_info(i,:);
        critical_accel_array(:, site.locIdx) = critical_accel_ls(site.landslide_susceptibility + 1); % add one to get the vector index, becuase the catagories start at zero
        gm_sim.imSims_combined.landslide_prob(:, site.locIdx) = map_area_ls(site.landslide_susceptibility + 1); % add one to get the vector index, becuase the catagories start at zero
    end
    
    % compute the ratio of critical acceleration and induced acceleration
    accel_ratio_ls = critical_accel_array./ pga_array;
    
    displacement_factor_cm_lower = exp(interp1(acceleration_ratio_reference,log(displacement_factor_cm_lower_reference), accel_ratio_ls, 'linear', 'extrap'));
    displacement_factor_cm_upper = exp(interp1(acceleration_ratio_reference,log(displacement_factor_cm_upper_reference), accel_ratio_ls, 'linear', 'extrap'));
    
    % Simulate from upper and lower bound assuming uniform random between
    p = rand(num_sims,num_sites);
    displacement_factor_cm_sim = (displacement_factor_cm_upper-displacement_factor_cm_lower) .* p + displacement_factor_cm_lower;
    
    gm_sim.imSims_combined.pgd_ls_inches = displacement_factor_cm_sim.* pga_array.* n_array / 2.54;
end


%% compute surface fault rupture pgd
if is_compute_pgd_surfacefaultrupture
    pgd_sf_rupt_meters = zeros(num_sims,num_sites);
    for i = 1:num_sites
        site = site_info(i,:);
        filt = gm_sim.r_jb_rup_dist(:,site.locIdx) < dist_threshold_surface_fault_rupt;
        if any(filt)
            pgd_sf_rupt_meters(filt,site.locIdx) = 10.^(-5.26 + 0.79 * gm_sim.scenarios_table.M(filt)); 
        end
    end 
    gm_sim.imSims_combined.pgd_sf_rupt_median_inches = pgd_sf_rupt_meters * 39.37;
end

end % function









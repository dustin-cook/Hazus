clear all
close all
clc
rehash


%% Intial setup
% Import Packages
import hazus.*

% Load model data
network_components = readtable(['inputs' filesep 'network_components.csv']);

% Define analysis settings
n_sims = 10000;

%% Run each model through hazus eq pga
for m = 1:height(network_components)
    % Pull Shakemap data for this site
    network_components.pga(m) = 0.5; % Just fix to 0.5 for now
    network_components.pgd_lat(m) = network_components.pga(m) * 8; % estimate PGD based on very simple and very incorrect approximation
    network_components.pgd_set(m) = network_components.pga(m) * 8; % estimate PGD based on very simple and very incorrect approximation
    network_components.pgd_lan(m) = network_components.pga(m) * 8; % estimate PGD based on very simple and very incorrect approximation
    network_components.pgd_rup(m) = network_components.pga(m) * 8; % estimate PGD based on very simple and very incorrect approximation
    network_components.p_liq(m) = 0.1;  % Assume 10% prob of liquefaction associated with moderate susceptability
    network_components.p_land(m) = 0.08; % Assume 8% prob of landslide associated with moderate susceptability
%     [ network_components.pga(m) ] = fn_read_shakemap_data( network_components.lat(m), network_components.lng(m), 'mineral_VA' );

    % Define attributes and shake data fort this component
    comp = table2struct(network_components(m,:));
    
    % Pull Hazus building data for stations
    if strcmp(network_components.lifeline_type(m),'RST')
        % Define transitionary Inputs
        [ building_type ] = fn_hazus_building_type( network_components.building_type_id{m}, network_components.num_stories(m) );
        comp.build_type = building_type.build_type;
        [ comp.code_level ] = fn_hazus_code_level( num2str(network_components.hazus_zone(m)), building_type, network_components.year_of_construction(m) );
    end

    % Calc losses for each asset
    [ network_components.recovery_time_days(m) ] = main_hazus_rail( comp, n_sims );
end

%% Save output data
if ~exist('outputs','dir')
    mkdir('outputs')
end
writetable(network_components, ['outputs' filesep 'model_outputs.csv'])
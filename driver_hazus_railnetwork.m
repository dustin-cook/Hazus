clear all
close all
clc
rehash

%% Import Packages
import hazus.*

%% Load model data
network_components = readtable(['inputs' filesep 'network_components.csv']);

%% Run each model through hazus eq pga
for m = 1:height(network_components)
    %% Pull Shakemap data for this site
    [ network_components.pga(m) ] = fn_read_shakemap_data( network_components.lat(m), network_components.lng(m), 'mineral_VA' );
    
    if strcmp(network_components.lifeline_type(m),'RTR')
        % estimate PGD based on very simple and very incorrect
        % approximation based on hazas fragilities
        network_components.pgd(m) = network_components.pga(m) * 8;
        
        %% Determine Hazus Loss
        [ network_components.recovery_time_days(m) ] = main_hazus_rail_track( network_components.lifeline_type{m}, network_components.lifeline_class{m}, network_components.pgd(m) );
    else
        network_components.pgd(m) = NaN;
        
        %% Define transitionary Inputs
        [ building_type ] = fn_hazus_building_type( network_components.building_type_id{m}, network_components.num_stories(m) );
        [ network_components.code_level{m} ] = fn_hazus_code_level( num2str(network_components.hazus_zone(m)), building_type, network_components.year_of_construction(m) );

        %% Run Hazus Eq PGA method
        [ network_components.recovery_time_days(m) ] = main_hazus_rail_station( building_type.build_type, network_components.lifeline_type{m}, network_components.code_level(m), network_components.pga(m) );
    end
end

%% Save output data
if ~exist('outputs','dir')
    mkdir('outputs')
end
writetable(network_components, ['outputs' filesep 'model_outputs.csv'])
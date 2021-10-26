clear all
close all
clc
rehash

%% Import Packages
import hazus.*

%% Load model data
models = readtable(['inputs' filesep 'models.csv']);

%% Run each model through hazus eq pga
for m = 1:height(models)
    %% Pull Shakemap data for this site
    [ models.pga(m) ] = fn_read_shakemap_data( models.lat(m), models.lng(m), 'mineral_VA' );

    %% Define transitionary Inputs
    [ building_type ] = fn_hazus_building_type( models.building_type_id{m}, models.num_stories(m) );
    [ models.code_level{m} ] = fn_hazus_code_level( num2str(models.hazus_zone(m)), building_type, models.year_of_construction(m) );

    %% Run Hazus
    [ models.loss(m) ] = main_hazus_eq_pga( building_type.build_type, models.occupancy{m}, models.code_level(m), models.pga(m) );
end

%% Save output data
if ~exist('outputs','dir')
    mkdir('outputs')
end
writetable(models, ['outputs' filesep 'model_outputs.csv'])
function[ hazus_build_type ] = fn_hazus_building_type( hazus_class, num_stories )
% Description
% Find the Hazus building type ID from P-58 building type and number of
% stories
%
% Created by Katie Wade August 2017
% Modified by Dustin Cook August 2018

% INPUTS:
% building_class_id - numerical id from P58 building class table
% num_stories - numerical number of stories of building

%% Begin Method
% Load in p-58 building class and hazus building type tables
load(['+hazus' filesep 'data_hazus' filesep 'data_hazus_building_type.mat']); % pull the standard HAZUS building types

% Find hazus building types that match class and num stories
table_filt = hazus_building_type(strcmp(hazus_building_type.hazus_class,hazus_class) & hazus_building_type.min_num_stories <= num_stories,:);
hazus_build_type = table_filt(table_filt.min_num_stories == max(table_filt.min_num_stories),:);


end
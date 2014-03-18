% function [] = create_entire_training_set( )
%
% Loads parameters from text file and pass them to runDataset to execute.
%
% Parameters could define a single dataset, a set of datasets and/or a set of different parameters.
%
%   Arguments:
%
%     * [local_parameters] Filepath to file that defines the repository, data directory, results directory, and the running parameters
%     * [training_dir] path to the new raw training images
%			* [prior_training_dir] path to a previously completed dataset directory with a full training set
%			* [split_rows] number of rows to split images into for labelGUI()
%			* [split_cols] number of cols to split images into for labelGUI()
%
%   Returns:
%
%     * nothing

%%
function create_entire_training_set()
  % Parameters for selectAndSaveTrainingImages()
  label_functions_path = '/home/kyle/label_training_set/';
  addpath(label_functions_path);
  
  repository_path = '/home/kyle/grape_code_git_backup/robocrop/matlab/src/';
  current_path = pwd;
  
  cd( repository_path );
  local_parameters = load_local_parameters();
%  calibration_classify_set = {'training_dir_root', 'training_dir_name'};
%   selectAndSaveTrainingImages( local_parameters, calibration_classify_set );
  cd( current_path );
  
  % Parameters for labelTrainingImages()
  
  training_dir = '/home/kyle/Dropbox/sample_training_images_from_pinot_noir/';
  prior_dataset_dir = '/media/YIELDEST_KY/data/2013_06_17_Colony_Petite_Syrah/';
  split_rows = 3;
  split_columns = 3;
  labelTrainingImages( local_parameters, training_dir, prior_dataset_dir, split_rows, split_columns );
end

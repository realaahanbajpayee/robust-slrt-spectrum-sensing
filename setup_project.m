% SETUP_PROJECT Adds project directories to the MATLAB path
function setup_project()
    project_root = fileparts(mfilename('fullpath'));
    addpath(genpath(project_root));
    fprintf('[INFO] Project paths initialized successfully: %s\n', project_root);
end
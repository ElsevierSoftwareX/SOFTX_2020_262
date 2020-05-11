function layers=open_rdi_raw(Filename_cell,varargin)

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if isempty(Filename_cell)
    layers = [];
    return;
end

[def_path_m,~,~] = fileparts(Filename_cell{1});


addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);

dir_data=p.Results.PathToMemmap;

if ischar(Filename_cell)
    Filename_cell=cellstr(Filename_cell);
end






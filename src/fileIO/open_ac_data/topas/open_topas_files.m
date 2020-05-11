function new_layers=open_topas_files(Filename,varargin)

p = inputParser;

if ~iscell(Filename)
    Filename={Filename};
end

if isempty(Filename)
    new_layers=[];
    return;
end

[def_path_m,~,~]=fileparts(Filename{1});

addRequired(p,'Filename',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Frequencies',[],@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,Filename,varargin{:});


new_layers=read_topas(p.Results.Filename,...
    'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp);


end
function [layers,idx_empty]=create_gps_layers_from_db(Filename_cell,varargin)

p=inputParser;
addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));

parse(p,Filename_cell,varargin{:});

gps_data=get_ping_data_from_db(Filename_cell,[]);

idx_empty=find(cellfun(@isempty,gps_data));

i=0;
for ilay=1:numel(Filename_cell)
    if ~isempty(gps_data{ilay})
        i=i+1;
        layers(i)=layer_cl('Filename',Filename_cell(ilay),'GPSData',gps_data{ilay});
    end
end
if i==0
    layers=[];
end

end
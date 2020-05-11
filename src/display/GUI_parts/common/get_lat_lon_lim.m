
function [lat_lim,lon_lim,lat,lon]=get_lat_lon_lim(obj)
lat=cell(1,length(obj));
lon=cell(1,length(obj));

switch class(obj)
    case 'layer_cl'
        lat=cell(1,length(obj));
        lon=cell(1,length(obj));
        
        for i=1:length(obj)
            lat{i}=obj(i).GPSData.Lat;
            lon{i}=obj(i).GPSData.Long;
        end
    case {'mbs_cl' 'survey_cl'}
        for ii=1:length(obj)
            map_temp=map_input_cl.map_input_cl_from_obj(obj(ii));
            if ~isempty(map_temp)
                lat{ii}=[map_temp.SliceLat{:}];
                lon{ii}=[map_temp.SliceLong{:}];
            end
            lat{ii}(lat{ii}==0|lon{ii}==0)=nan;
            lon{ii}(isnan(lat{ii}))=nan;
        end
end

lat_tmp=lat;
lon_tmp=lon;

idx_empty=find(cellfun(@(x) isempty(x),lat)|cellfun(@(x) all(x==0),lat));
if ~isempty(idx_empty)
    lat_tmp{idx_empty}=nan;
    lon_tmp{idx_empty}=nan;
end

lat_lim=[nanmin(cellfun(@nanmin,lat_tmp)) nanmax(cellfun(@nanmax,lat_tmp))];
lon_lim=[nanmax(cellfun(@nanmin,lon_tmp)) nanmax(cellfun(@nanmax,lon_tmp))];


end



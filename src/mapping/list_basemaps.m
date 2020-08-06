function [basemap_list,url_list,attribution_list,basemap_dispname_list]=list_basemaps(add,online,varargin)

app_path_main=whereisEcho();
config_path=fullfile(app_path_main,'config');

basemap_struct=read_basemap_xml(fullfile(config_path,'basemaps.xml'));
basemap_list={};
url_list={};
attribution_list={};
basemap_dispname_list={};

if nargin>=3
    if ~isempty(varargin{1})
        idx= ismember({basemap_struct(:).name},varargin{1});
        if any(idx)
            basemap_struct=basemap_struct(idx);
        else
            basemap_struct={};
        end
    end
end

if isempty(basemap_struct)
    return;
end

basemap_list={basemap_struct(:).name};
url_list={basemap_struct(:).url};
attribution_list={basemap_struct(:).attribution};
basemap_dispname_list={basemap_struct(:).name_disp};

idx_rem=[];

if add>0
    basenames={'darkwater' 'none'};
    conn=online>0;
    
    for i=1:numel(basemap_struct)
        try
            
            if ~isempty(basemap_struct(i).url)
                if conn
                    addCustomBasemap(basemap_struct(i).name,basemap_struct(i).url,'Attribution',basemap_struct(i).attribution,'DisplayName',basemap_struct(i).name_disp,...
                        'MaxZoomLevel',basemap_struct(i).zoom_max,'IsDeployable',basemap_struct(i).deploy>0);
                else
                    idx_rem=union(idx_rem,i);
                end
            else
                if ~conn&&~ismember(basemap_struct(i).name,basenames)
                    idx_rem=union(idx_rem,i);
                end
            end
            
        catch
            idx_rem=union(idx_rem,i);
        end
    end
end

basemap_list(idx_rem)=[];
url_list(idx_rem)=[];
attribution_list(idx_rem)=[];
basemap_dispname_list(idx_rem)=[];
end
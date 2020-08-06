function h_in=geoplot_shp(ax,folders,h_in)
shape_f={};
for ifold=1:numel(folders)
    if isfolder(folders{ifold})
        tmp=dir(fullfile(folders{ifold},'echomaps','*.shp'));
        tmp([tmp(:).isdir]) =[];
        shape_f=union(shape_f,cellfun(@(x) fullfile(folders{ifold},'echomaps',x),{tmp(:).name},'un',0));
    elseif isfile(folders{ifold})
        shape_f=union(shape_f,folders{ifold});
    end
end

if ~isempty(h_in)
    tag_shp=arrayfun(@(x) x.Tag,h_in(isvalid(h_in)),'UniformOutput',false);
else
    tag_shp={};
end

[new_shp_f,~]=setdiff(shape_f,tag_shp);
[~,idx_rem]=setdiff(tag_shp,shape_f);
idx_rem=ismember(tag_shp,tag_shp(idx_rem));
delete(h_in(idx_rem));
h_in(idx_rem)=[];

geo_data_shp=cellfun(@(x) shaperead(x),new_shp_f,'un',0);


for uishp=1:numel(geo_data_shp)
    if ~isempty(findobj(ax,'Tag',new_shp_f{uishp}))
        continue;
    end
    
    if contains(new_shp_f{uishp},'strat')
        color = [0.6 0 0];
        sty='-';
        mark='none';
        type= 'stratum';
    elseif contains(new_shp_f{uishp},'trans')
        color = [0 0 0.6];
        sty='--';
        mark='none';
        type='transects';
    elseif contains(new_shp_f{uishp},'cont')
        color = [0.4 0.4 0.4];
        sty='-';
        mark='none';
        type='contours';
    else
        type='unknown';
        color = [0 0 0];
        sty='-';
        mark='none';
    end
    
    for i_feat=1:numel(geo_data_shp{uishp})
        try
            
            lat_disp=geo_data_shp{uishp}(i_feat).Y;
            lon_disp=geo_data_shp{uishp}(i_feat).X;
            bbox=geo_data_shp{uishp}(i_feat).BoundingBox;
            
            
            
            if numel(lat_disp)>1000
                [lat_disp,lon_disp] = reducem(lat_disp',lon_disp');
            end
            tmp_plot=geoplot(ax,lat_disp,lon_disp,...
                'color',color,...
                'linestyle',sty,...
                'marker',mark,...
                'tag',new_shp_f{uishp});
            tmp_plot.LatitudeDataMode='manual';
            h_in=[h_in tmp_plot];
            
            temp_txt=[];
            
            switch type
                
                case 'stratum'
                    if isfield(geo_data_shp{uishp}(i_feat),'Stratum')
                        if isnumeric(geo_data_shp{uishp}(i_feat).Stratum)
                            str=num2str(geo_data_shp{uishp}(i_feat).Stratum);
                        else
                            str=geo_data_shp{uishp}(i_feat).Stratum;
                        end
                        temp_txt=text(ax,nanmean(bbox(:,2)),nanmean(bbox(:,1)),str,...
                            'Fontsize',10,'Fontweight','bold','Interpreter','None','VerticalAlignment','bottom','Clipping','on','Color',color,'tag',new_shp_f{uishp});
                    end
                case 'transects'
                    if isfield(geo_data_shp{uishp}(i_feat),'Transect')
                        if isnumeric(geo_data_shp{uishp}(i_feat).Transect)
                            str=num2str(geo_data_shp{uishp}(i_feat).Transect);
                        else
                            str=geo_data_shp{uishp}(i_feat).Transect;
                        end
                        temp_txt=text(ax,nanmean(bbox(:,2)),nanmean(bbox(:,1)),str,...
                            'Fontsize',6,'Fontweight','normal','Interpreter','None','VerticalAlignment','bottom','Clipping','on','Color',color,'tag',new_shp_f{uishp});
                    end
                    
            end
            
            h_in=[h_in temp_txt];
        catch err
            fprintf('Error displaying shapefile %s \n',new_shp_f{uishp});
            print_errors_and_warnings(1,'error',err);
        end
    end
    
end
end
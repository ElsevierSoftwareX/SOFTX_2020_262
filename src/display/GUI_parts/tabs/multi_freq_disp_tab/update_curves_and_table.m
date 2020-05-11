function update_curves_and_table(main_figure,tab_tag,id_new)

layer=get_current_layer();

if isempty(layer)
    return;
end


if ~iscell(id_new)
    id_new={id_new};
end

multi_freq_disp_tab_comp=getappdata(main_figure,tab_tag);

curves=layer.get_curves_per_type(tab_tag);

for i=1:numel(id_new)
    av=1;
    id_c=multi_freq_disp_tab_comp.ax.Children;
    id_c=id_c(arrayfun(@(x) strcmp(x.Type,'errorbar'),id_c));
    if ~isempty(id_c)
        id_c=id_c(arrayfun(@(x) contains(x.Tag,id_new{i}),id_c));
    end
    
    idx=find(contains({curves(:).Unique_ID},id_new{i})&strcmp({curves(:).Type},tab_tag));
    
    if isempty(idx)
        continue;
    end
    
    if multi_freq_disp_tab_comp.show_sd_bar.Value>0
        sd=curves(idx).SD;
    else
        sd=[];
    end
    if ~isempty(id_c)
        for ui=1:numel(id_c)
            idx_disp=~isnan(curves(idx(ui)).YData);
            if multi_freq_disp_tab_comp.detrend_cbox.Value>0
                av=nanmean(db2pow_perso(curves(idx(ui)).YData));
                 av=av(idx_disp);
            end
            if multi_freq_disp_tab_comp.detrend_cbox.Value>0
                av=nanmean(db2pow_perso(curves(idx(ui)).YData));
                av=av(idx_disp);
            end
            if ~isempty(sd)
                sd=sd(idx_disp);
            end
            set(id_c(ui),'XData',curves(idx(ui)).XData(idx_disp),'YData',curves(idx(ui)).YData(idx_disp)-pow2db_perso(av),'YNegativeDelta',sd,'YPositiveDelta',sd,'Tag',curves(idx(ui)).Unique_ID);
        end
    else
        for ui=1:numel(idx)
            idx_disp=~isnan(curves(idx(ui)).YData);
            if multi_freq_disp_tab_comp.detrend_cbox.Value>0
                av=nanmean(db2pow_perso(curves(idx(ui)).YData));
                %av=av(idx_disp);
            end
            if ~isempty(sd)
                sd=curves(idx(ui)).SD(idx_disp);
            end
        id_c(ui)=errorbar(multi_freq_disp_tab_comp.ax,curves(idx(ui)).XData(idx_disp),curves(idx(ui)).YData(idx_disp)-av,sd,...
            'Tag',curves(idx(ui)).Unique_ID,'ButtonDownFcn',{@display_line_cback,main_figure,tab_tag});
        end
    end
    if ~isempty(multi_freq_disp_tab_comp.table.Data)
        u=find(contains(multi_freq_disp_tab_comp.table.Data(:,4),id_new{i}));
    else
        u=[];
    end
    
    if isempty(u)
        for ui=1:numel(idx)
            u=size(multi_freq_disp_tab_comp.table.Data,1)+1;
            color_str=sprintf('rgb(%.0f,%.0f,%.0f)',floor(get(id_c(ui),'Color')*255));
            multi_freq_disp_tab_comp.table.Data{u,1}=strcat('<html><FONT color="',color_str,'">',curves(idx(ui)).Name,'</html>');
            multi_freq_disp_tab_comp.table.Data{u,2}=curves(idx(ui)).Tag;
            multi_freq_disp_tab_comp.table.Data{u,3}=true;
            multi_freq_disp_tab_comp.table.Data{u,4}=curves(idx(ui)).Unique_ID;
        end
    else
        for ui=1:numel(u)
                color_str=sprintf('rgb(%.0f,%.0f,%.0f)',floor(get(id_c(ui),'Color')*255));
                idx=find(strcmp({curves(:).Unique_ID}, multi_freq_disp_tab_comp.table.Data{u(ui),4})&strcmp({curves(:).Type},tab_tag));
               multi_freq_disp_tab_comp.table.Data{u(ui),1}=strcat('<html><FONT color="',color_str,'">',curves(idx).Name,'</html>');
               multi_freq_disp_tab_comp.table.Data{u(ui),2}=curves(idx).Tag;
        end
    end
end

end


function display_line_cback(src,evt,main_figure,tab_tag)
multi_freq_disp_tab_comp=getappdata(main_figure,tab_tag);
layer=get_current_layer();
cp=multi_freq_disp_tab_comp.ax.CurrentPoint;
x1 = cp(1,1);
y1 = cp(1,2);

idx_data=strcmp(src.Tag,multi_freq_disp_tab_comp.table.Data(:,4));
idx_c=strcmp(src.Tag,{layer.Curves(:).Unique_ID});
if any(idx_data)&&any(idx_c)
    text_obj=findobj(multi_freq_disp_tab_comp.ax,'Tag','DataText');
    txt_disp=sprintf('%s:   %.1fdB @ %.0fkHz,',layer.Curves(idx_c).Name,y1,x1);
    if ~isempty(text_obj)
        set(text_obj,'Position',[x1,y1,0],'String',txt_disp,'Color',src.Color);
    else
        text(multi_freq_disp_tab_comp.ax,x1,y1,txt_disp,'Tag','DataText','Color',src.Color)
    end
end

end


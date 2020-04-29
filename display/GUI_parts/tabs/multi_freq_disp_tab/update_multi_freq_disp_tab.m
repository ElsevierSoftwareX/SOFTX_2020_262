function update_multi_freq_disp_tab(main_figure,tab_tag,replot)

multi_freq_disp_tab_comp=getappdata(main_figure,tab_tag);
if isempty(multi_freq_disp_tab_comp)
    opt_panel=getappdata(main_figure,'option_tab_panel');
    load_multi_freq_disp_tab(main_figure,opt_panel,tab_tag);
    return;
end


setappdata(main_figure,tab_tag,multi_freq_disp_tab_comp);
layer=get_current_layer();
if isempty(layer)
     multi_freq_disp_tab_comp.table.Data=[];
     delete(findobj(multi_freq_disp_tab_comp.ax,{'Type','errorbar'}));
    return;
end

fLim=layer.get_flim();
flim=fLim/1e3.*[0.9 1.1];

set(multi_freq_disp_tab_comp.ax,'XLim',flim);

[f_min,f_max,f_nom,f_start,f_end]=layer.get_freq_min_max_nom_start_end();
multi_freq_disp_tab_comp.ax.XTick=unique([f_nom f_start f_end])/1e3;

%set(multi_freq_disp_tab_comp.ax,'XTick',unique(layer.Frequencies/1e3));
lines=findobj(multi_freq_disp_tab_comp.ax,'Type','errorbar');
reg_uid=union(layer.get_layer_reg_uid(),layer.get_layer_tracks_uid());

if ~isempty(layer.Curves)
    idx_rem_c=cellfun(@(x) ~contains(x,union(reg_uid,{'select_area','single_target'})),{layer.Curves(:).Unique_ID});
    layer.Curves(idx_rem_c)=[];
end

if ~isempty(layer.Curves) 
    if ~isempty(lines)&&replot==0
        idx_rem=cellfun(@(x) ~contains(x,reg_uid),{lines(:).Tag});
    else
        idx_rem=1:numel(lines);
    end
else
    idx_rem=1:numel(lines); 
end
delete(lines(idx_rem));

lines(idx_rem)=[];
if isempty(lines)
    tag_lines={};
else
    tag_lines=get(lines,'Tag');
end


if isempty(layer.Curves)
    multi_freq_disp_tab_comp.table.Data={};    
    set(multi_freq_disp_tab_comp.table,'Data',multi_freq_disp_tab_comp.table.Data);
    return;
else
    curves=layer.get_curves_per_type(tab_tag);
    if ~isempty(multi_freq_disp_tab_comp.table.Data)&&~isempty(tag_lines)
        
        idx_rem=~(ismember(multi_freq_disp_tab_comp.table.Data(:,4),{curves(:).Unique_ID})|...
            ismember(multi_freq_disp_tab_comp.table.Data(:,4),tag_lines)|...
            (cellfun(@(x) contains(x,reg_uid),multi_freq_disp_tab_comp.table.Data(:,4))))|...
            contains(multi_freq_disp_tab_comp.table.Data(:,4),'select_area');
        
        multi_freq_disp_tab_comp.table.Data(idx_rem,:)=[];
        idx_new=find(~ismember({curves(:).Unique_ID},multi_freq_disp_tab_comp.table.Data(:,4)));
    else
        multi_freq_disp_tab_comp.table.Data(:,:)=[];
        idx_new=1:numel(curves);
    end 
    id_new={curves(idx_new).Unique_ID};
    %id_new={curves(:).Unique_ID};
end

update_curves_and_table(main_figure,tab_tag,id_new);

nb_lines=size(multi_freq_disp_tab_comp.table.Data,1);

for il=1:nb_lines
    line_obj=findobj(multi_freq_disp_tab_comp.ax,{'Type','errorbar','-and','Tag',multi_freq_disp_tab_comp.table.Data{il,4}});
    if ~isempty(line_obj)
        switch multi_freq_disp_tab_comp.table.Data{il,3}
            case true
                set(line_obj,'Visible','on');
            case false
                set(line_obj,'Visible','off');
        end
    end
end

cax=get(multi_freq_disp_tab_comp.ax,'YLim');
set(multi_freq_disp_tab_comp.thr_up,'String',num2str(cax(2),'%.0f'));
set(multi_freq_disp_tab_comp.thr_down,'String',num2str(cax(1),'%.0f'));

end

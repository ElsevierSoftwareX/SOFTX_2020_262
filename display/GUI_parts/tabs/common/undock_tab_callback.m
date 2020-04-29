function undock_tab_callback(~,~,main_figure,tab,dest)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');

switch tab
    case 'st_tracks'
        st_tracks_tab_comp=getappdata(main_figure,'ST_Tracks');
        tab_h=st_tracks_tab_comp.st_tracks_tab;
        tt='St&Tracks';
    case 'map'
        map_tab_comp=getappdata(main_figure,'Map_tab');
        if ~isempty(map_tab_comp)
            if isvalid(map_tab_comp.map_tab)
                tab_h=map_tab_comp.map_tab;
            else
                tab_h=[];
            end
            basemap_str=curr_disp.Basemap;
            all_lays=map_tab_comp.all_lays;
            cont_disp=map_tab_comp.cont_disp;
            cont_val=map_tab_comp.cont_val;
            idx_lays=map_tab_comp.idx_lays;
        else
            cont_disp=0;
            cont_val=500;
            idx_lays=[];
            basemap_str=curr_disp.Basemap;
            all_lays=0;
            tab_h=[];
        end
        tt='Map';
    case 'reglist'
        tab_comp=getappdata(main_figure,'Reglist_tab');
        tab_h=tab_comp.reglist_tab;
        tt='Region List';
    case 'laylist'
        tab_comp=getappdata(main_figure,'Layer_tree_tab');
        tab_h=tab_comp.layer_tree_tab;
        tt='Layers';       
    case 'sv_f'
        tab_comp=getappdata(main_figure,tab);
        tab_h=tab_comp.multi_freq_disp_tab;
        tt='Sv(f)';
    case 'ts_f'
        tab_comp=getappdata(main_figure,tab);
        tab_h=tab_comp.multi_freq_disp_tab;
        tt='TS(f)';
    case 'echoint_tab'
        tab_comp=getappdata(main_figure,'EchoInt_tab');
        tab_h=tab_comp.echo_int_tab;        
        tt='Echo-Integration';
end
pos_fig=getpixelposition(main_figure);
if ~isempty(tab_h)
    if~isvalid(tab_h)
        return;
    end
    if strcmpi(class(tab_h),'matlab.ui.Figure')
        figure(tab_h);
        return;
    end
    pos_tab=getpixelposition(tab_h);  
    delete(tab_h);
    pos_out=pos_tab+[0 0 pos_tab(3)/2 2*pos_tab(4)];
    pos_out=nanmin(pos_out,pos_fig);
else
    pos_out=pos_fig/2;
end
switch dest
    case 'opt_tab'
        dest_fig=getappdata(main_figure,'option_tab_panel');
    case 'echo_tab'
        dest_fig=getappdata(main_figure,'echo_tab_panel');
    case 'new_fig'    
        dest_fig=new_echo_figure(main_figure,...
            'Units','pixels',...
            'Position',pos_out,...
            'Name',tt,...
            'Resize','on',...
            'UiFigureBool',false,...
            'CloseRequestFcn',@close_tab,...
            'Tag',tab);
end


switch tab
    case 'st_tracks'
        load_st_tracks_tab(main_figure,dest_fig);
    case 'map'
        load_map_tab(main_figure,dest_fig,'cont_disp',cont_disp,'cont_val',cont_val,'basemap',basemap_str,'idx_lays',idx_lays,'all_lays',all_lays);
    case 'reglist'
        load_reglist_tab(main_figure,dest_fig);
    case 'laylist'
        load_tree_layer_tab(main_figure,dest_fig);
    case 'echoint_tab'
        load_echo_int_tab(main_figure,dest_fig);
        init_link_prop(main_figure);
    case {'sv_f' 'ts_f'}
        load_multi_freq_disp_tab(main_figure,dest_fig,tab);
end


switch dest
    case 'opt_tab'
        order_option_tab(main_figure);
    case 'echo_tab'
        
    case 'new_fig'
        
end
curr_disp=get_esp3_prop('curr_disp');

format_color_gui(dest_fig,curr_disp.Font,curr_disp.Cmap);

end

function close_tab(src,~,main_figure)
tag=src.Tag;


dest_fig=getappdata(main_figure,'option_tab_panel');
switch tag
    case 'st_tracks'
        delete(src);
        load_st_tracks_tab(main_figure,dest_fig);
    case 'map'
        map_tab_comp=getappdata(main_figure,'Map_tab');
        cont_disp=map_tab_comp.cont_disp;
        cont_val=map_tab_comp.cont_val;
        idx_lays=map_tab_comp.idx_lays;
        basemap_str=map_tab_comp.basemap_list.UserData{map_tab_comp.basemap_list.Value};
        all_lays=map_tab_comp.all_lays;
        war_str='Do you want close the map or dock it?';
        choice=question_dialog_fig(main_figure,'Close or Dock?',war_str,'opt',{'Close' 'Dock'},'timeout',5);
        delete(src);
        switch choice
            case 'Dock'      
                load_map_tab(main_figure,dest_fig,'cont_disp',cont_disp,'cont_val',cont_val,'basemap',basemap_str,'idx_lays',idx_lays,'all_lays',all_lays);
            case 'Close'
                rmappdata(main_figure,'Map_tab');
        end
    case 'reglist'
        delete(src);
        load_reglist_tab(main_figure,dest_fig);
    case 'laylist'
        delete(src);
        load_tree_layer_tab(main_figure,dest_fig);
    case 'echoint_tab'

        dest_fig=getappdata(main_figure,'echo_tab_panel');
        delete(src);
        load_echo_int_tab(main_figure,dest_fig);
        init_link_prop(main_figure);
    case {'sv_f' 'ts_f'}
        delete(src);
        load_multi_freq_disp_tab(main_figure,dest_fig,tag);
end

order_option_tab(main_figure);
curr_disp=get_esp3_prop('curr_disp');
format_color_gui(dest_fig,curr_disp.Font,curr_disp.Cmap);


end
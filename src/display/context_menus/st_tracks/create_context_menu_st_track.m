%% Function
function create_context_menu_st_track(main_figure,track_plot)
% curr_disp=get_esp3_prop('curr_disp');
% layer=get_current_layer();
% 

context_menu=uicontextmenu(ancestor(track_plot,'figure'),'Tag','stTrackCtxtMenu','UserData',track_plot.UserData);
track_plot.UIContextMenu=context_menu;
uimenu(context_menu,'Label','Get Frequency Response','Callback',{@add_ts_curves_from_tracks_cback,main_figure,track_plot.UserData});
uimenu(context_menu,'Label','Remove track','Callback',{@rm_tracks_cback,main_figure,track_plot.UserData});
uimenu(context_menu,'Label','Create bad data region around track','Callback',{@create_regs_from_tracks_callback,'Bad Data',main_figure,track_plot.UserData});
uimenu(context_menu,'Label','Create data region around track','Callback',{@create_regs_from_tracks_callback,'Data',main_figure,track_plot.UserData});

end


function rm_tracks_cback(~,~,main_figure,uid)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[trans_obj,~]=layer.get_trans(curr_disp);
tracks = trans_obj.Tracks;
if isempty(tracks)
    return;
end
if ~iscell(uid)
   uid={uid}; 
end

idx_tracks=ismember(tracks.uid,uid);

ifield=fieldnames(tracks);

for ifif=1:numel(ifield)
   tracks.(ifield{ifif})(idx_tracks)=[]; 
end

axes_panel_comp=getappdata(main_figure,'Axes_panel');

for i=1:numel(uid)
    delete(findobj(main_figure,'Type','UIContextMenu','-and','Tag','stTrackCtxtMenu','-and','UserData',uid{i}));
    id_reg=findobj(axes_panel_comp.echo_obj.main_ax,'tag','track','-and','UserData',uid{i});
    delete(id_reg);

end

objt=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','tooltipt');
delete(objt);

trans_obj.Tracks=tracks;

update_st_tracks_tab(main_figure,'histo',1,'st',1);

delete_region_callback([],[],main_figure,uid);

end
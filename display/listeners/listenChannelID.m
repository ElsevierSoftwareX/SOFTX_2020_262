
function listenChannelID(~,~,main_figure)

load_bar_comp=getappdata(main_figure,'Loading_bar');
load_bar_comp.progress_bar.setText('Changing Channel...');

%replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',1);
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

%remove_interactions(main_figure);

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
curr_disp.Freq=layer.Frequencies(idx_freq);

%names={'BottomDetection' 'BottomDetectionV2' 'BadPingsV2' 'SpikeRemoval' 'SchoolDetection' 'TrackTarget'};
update_algo_panels(main_figure,{});
update_processing_tab(main_figure);
update_display_tab(main_figure);
update_calibration_tab(main_figure);
update_environnement_tab(main_figure,1);
update_st_tracks_tab(main_figure);

load_info_panel(main_figure);

range=trans_obj.get_transceiver_range();
[~,y_lim]=nanmin(abs(range-curr_disp.R_disp'));

if curr_disp.R_disp(2)==Inf
    y_lim(2)=numel(range);
end

if diff(y_lim)<=0
    y_lim=[1 numel(range)];
end

clear_regions(main_figure,{},{'main' 'mini'});

[~,found_ori]=find_field_idx(trans_obj.Data,curr_disp.Fieldname);

if found_ori==0
    [~,found]=find_field_idx(trans_obj.Data,'sv');
    if found==0
        field=trans_obj.Data.Fieldname{1};
    else
        field='sv';
    end
    rm_listeners(main_figure);
    curr_disp.setField(field);
    init_listeners(getappdata(groot,'esp3_obj'));
    curr_disp.ChannelID=curr_disp.ChannelID;

    return;
end

delete(findobj(axes_panel_comp.main_axes,'Tag','SelectLine','-or','Tag','SelectArea'));

update_axis(main_figure,0,'main_or_mini','mini');
set_alpha_map(main_figure,'main_or_mini','mini');
display_regions(main_figure,'both');
display_lines(main_figure);
set(axes_panel_comp.main_axes,'ylim',y_lim);

curr_disp.setActive_reg_ID({});
update_reglist_tab(main_figure,1);

update_info_panel([],[],1);

order_stacks_fig(main_figure);
%eplace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@update_info_panel,0});
load_bar_comp.progress_bar.setText('');


end


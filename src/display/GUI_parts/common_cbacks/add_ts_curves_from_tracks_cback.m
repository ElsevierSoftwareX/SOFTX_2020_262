function add_ts_curves_from_tracks_cback(~,~,main_figure,uid)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
tracks = trans_obj.Tracks;
if ~iscell(uid)&&~isempty(uid)
    uid={uid};
end
if~isempty(layer.Curves)
    if isempty(uid)
        
        layer.Curves(contains({layer.Curves(:).Name},'Track'))=[];
        
    else
        for i=1:numel(uid)
            layer.Curves(contains({layer.Curves(:).Unique_ID},uid{i}))=[];
        end
    end
    
end

if isempty(tracks)
    return;
end

if isempty(tracks.target_id)
    return;
end

if isempty(uid)
    uid=tracks.uid;
end
show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');

load_bar_comp.progress_bar.setText('Copying tracks across frequencies');
reg_obj=trans_obj.create_track_regs('uid',uid,'Add',false);

set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(reg_obj), 'Value',0);

for k=1:length(reg_obj)
    load_bar_comp.progress_bar.setText(sprintf('Processing TS(f) for tracks %d',reg_obj(k).ID));
    
    layer.TS_freq_response_func('reg_obj',reg_obj(k),'idx_freq',idx_freq);
    
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(reg_obj),'Value',k);
end

hide_status_bar(main_figure)
update_multi_freq_disp_tab(main_figure,'ts_f',0);
end

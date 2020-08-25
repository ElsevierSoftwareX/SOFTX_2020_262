function display_st_or_track_pos(main_figure,ax)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

if isempty(trans_obj)
    return;
end
ST = trans_obj.ST;
if isempty(ST)
    c=[];
    y=[];
    x=[];
else
    switch ax.Tag
        case 'st_comp'
            c = ST.TS_comp;
            y=ST.Angle_minor_axis;
            x=ST.Angle_major_axis;
        case 'st_uncomp'
            c = ST.TS_uncomp;
            y=ST.Angle_minor_axis;
            x=ST.Angle_major_axis;
        case 'tracks_comp'
            tracks = trans_obj.Tracks;
            c=[];
            y=[];
            x=[];
            if ~isempty(tracks)
                for k=1:length(tracks.target_id)
                    idx_targets=tracks.target_id{k};
                    c=[c ST.TS_comp(idx_targets)];
                    y=[y ST.Angle_minor_axis(idx_targets)];
                    x=[x ST.Angle_major_axis(idx_targets)];
                end
            end
        case 'tracks_uncomp'
            tracks = trans_obj.Tracks;
            c=[];
            y=[];
            x=[];
            if ~isempty(tracks)
                
                for k=1:length(tracks.target_id)
                    idx_targets=tracks.target_id{k};
                    c=[c ST.TS_uncomp(idx_targets)];
                    y=[y ST.Angle_minor_axis(idx_targets)];
                    x=[x ST.Angle_major_axis(idx_targets)];
                end
            end
    end
end

obj=findobj(ax,'Tag','scat_data');
delete(obj);
if ~isempty(x)
    cax=curr_disp.getCaxField('sp');
    c(c<cax(1))=nan;
    scat_plot=scatter(ax,x(~isnan(c)),y(~isnan(c)),8,c(~isnan(c)),'filled','Tag','scat_data');
    uistack(scat_plot,'bottom');
end



end
function update_st_tracks_tab(main_figure,varargin)

p = inputParser;
addRequired(p,'main_figure',@(obj) isa(obj,'matlab.ui.Figure'));

addParameter(p,'st',1,@isnumeric);
addParameter(p,'histo',1,@isnumeric);

parse(p,main_figure,varargin{:});

st_tracks_tab_comp=getappdata(main_figure,'ST_Tracks');
layer=get_current_layer();


if isempty(layer)
    return;
end


if p.Results.histo
    display_st_or_track_hist(main_figure,st_tracks_tab_comp.ax_hist,st_tracks_tab_comp.ax_pdf,st_tracks_tab_comp.pc_pdf,{'tracks','st','track_ts_mean'});   
end

if p.Results.st
    delete(st_tracks_tab_comp.ax_pos.Children);
    init_st_ax(main_figure,st_tracks_tab_comp.ax_pos);
    display_st_or_track_pos(main_figure,st_tracks_tab_comp.ax_pos);
end

setappdata(main_figure,'ST_Tracks',st_tracks_tab_comp);

end
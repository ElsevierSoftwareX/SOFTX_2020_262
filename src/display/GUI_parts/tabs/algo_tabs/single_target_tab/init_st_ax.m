function init_st_ax(main_figure,ax)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

if isempty(trans_obj)
    return;
end
cax=curr_disp.getCaxField('sp');
cmap_name=curr_disp.Cmap;

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(cmap_name);
caxis(ax,cax);
colormap(ax,cmap);

x0=trans_obj.Config.AngleOffsetAthwartship;
y0=trans_obj.Config.AngleOffsetAlongship;
[faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

[x1,y1]=get_ellipse_xy(psBW,faBW,...
    x0,y0,100);
[x2,y2]=get_ellipse_xy(psBW/2,faBW/2,...
    x0,y0,100);

ax.Color=col_ax;
ax.YRuler.Color=col_grid;
ax.XRuler.Color=col_grid;
ax.YRuler.FirstCrossoverValue = x0;
ax.XRuler.FirstCrossoverValue = y0;

plot(ax,x2,y2,'--','Color',col_grid);
plot(ax,x1,y1,'Color',col_grid);

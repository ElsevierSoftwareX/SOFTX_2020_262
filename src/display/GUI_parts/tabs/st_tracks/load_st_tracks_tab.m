function load_st_tracks_tab(main_figure,tab_panel)

switch tab_panel.Type
    case 'uitabgroup'
        st_tracks_tab_comp.st_tracks_tab=new_echo_tab(main_figure,tab_panel,'Title','ST&tracks','UiContextMenuName','st_tracks');
    case 'figure'
        st_tracks_tab_comp.st_tracks_tab=tab_panel;
end

 st_tracks_tab_comp.ax_hist=axes('Parent',st_tracks_tab_comp.st_tracks_tab,'Units','normalized',...
     'OuterPosition',[2/3 0 1/3 1],'visible','on','NextPlot','add','box','on','tag','tt_ax');
 
 st_tracks_tab_comp.ax_hist.XAxis.TickLabelFormat='%.0fdB';
 grid(st_tracks_tab_comp.ax_hist,'on');
 
 st_tracks_tab_comp.ax_pdf=axes('Parent',st_tracks_tab_comp.st_tracks_tab,'Units','normalized',...
     'OuterPosition',[1/3 0 1/3 1],'YDir','reverse','visible','on','GridAlpha',0.05,'NextPlot','add','TickLength',[0 0],'box','on','tag','pdf_ax');

 
 st_tracks_tab_comp.ax_pdf.YAxis.TickLabelFormat='%.0fm';
 st_tracks_tab_comp.ax_pdf.XAxis.TickLabelFormat='%.0fdB';
 
 st_tracks_tab_comp.pc_pdf=pcolor(st_tracks_tab_comp.ax_pdf,zeros(2,2));
 set(st_tracks_tab_comp.pc_pdf,'Facealpha','flat','FaceColor','flat','LineStyle','-','AlphaDataMapping','scaled','LineWidth',0.1,'Tag','transducer');
 
 ifig=ancestor(st_tracks_tab_comp.pc_pdf,'figure');
 menu = uicontextmenu(ifig);
 uimenu(menu,'Label','Reference to transducer','Tag','transducer', 'Checked', 'on','Callback',@change_pdf_ref);
 uimenu(menu,'Label','Reference to bottom','Tag','bottom', 'Checked', 'off','Callback',@change_pdf_ref);
 
 st_tracks_tab_comp.pc_pdf.UIContextMenu =  menu;
 
 
st_tracks_tab_comp.ax_pos=axes('Parent',st_tracks_tab_comp.st_tracks_tab,'Units','normalized',...
    'OuterPosition',[0 0 1/3 1],'visible','on','box','on','tag','st_ax','nextplot','add','Yaxislocation','origin','Xaxislocation','origin');
st_tracks_tab_comp.ax_pos.YRuler.Axle.LineStyle = 'solid';
st_tracks_tab_comp.ax_pos.XRuler.Axle.LineStyle = 'solid';

st_tracks_tab_comp.ax_pos.XRuler.TickLabelFormat='%.1f^\\circ';
st_tracks_tab_comp.ax_pos.YRuler.TickLabelFormat='%.1f^\\circ';

rm_axes_interactions(st_tracks_tab_comp.ax_pos);
rm_axes_interactions(st_tracks_tab_comp.ax_hist);
rm_axes_interactions(st_tracks_tab_comp.ax_pdf);
daspect(st_tracks_tab_comp.ax_pos,[1 1 1]);

st_tracks_tab_comp.tracks=[];

setappdata(main_figure,'ST_Tracks',st_tracks_tab_comp);

update_st_tracks_tab(main_figure,'st',1,'histo',1);
end


function change_pdf_ref(src,~)

esp3_obj=getappdata(groot,'esp3_obj');

main_figure = esp3_obj.main_figure;

uimenu_parent=get(src,'Parent');
childs=findobj(uimenu_parent,'Type','uimenu');  

for i=1:length(childs)
    if src~=childs(i)
        set(childs(i), 'Checked', 'off');
    end
end

set(src, 'Checked', 'on');

st_tracks_tab_comp = getappdata(main_figure,'ST_Tracks');

st_tracks_tab_comp.pc_pdf.Tag = src.Tag;
update_st_tracks_tab(main_figure,'st',0,'histo',1);

end

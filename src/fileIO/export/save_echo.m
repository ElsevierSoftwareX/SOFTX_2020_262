function save_echo(main_figure,path_echo,fileN,tag_ax)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[trans_obj,idx]=layer.get_trans(curr_disp);


axes_panel_comp=getappdata(main_figure,'Axes_panel');

switch tag_ax
    case 'main'
        main_axes=axes_panel_comp.main_axes;
        haxes=axes_panel_comp.haxes;
        vaxes=axes_panel_comp.vaxes;
    case 'sec_ax'
        secondary_freq=getappdata(main_figure,'Secondary_freq');
        main_axes=secondary_freq.axes(idx);
        haxes=secondary_freq.top_ax(idx);
        vaxes=secondary_freq.side_ax(idx);
end

switch fileN
    case '-clipboard'
        vis='off';
    otherwise
        vis='on';
end

size_max = get(0, 'MonitorPositions');
pos_main=getpixelposition(main_figure);
[~,id_screen]=nanmin(abs(size_max(:,1)-pos_main(1)));

new_fig=new_echo_figure(main_figure,'Units','Pixels','Position',size_max(id_screen,:),...
    'Name','','Tag','save_echo','visible',vis);

set(new_fig,'Alphamap',main_figure.Alphamap);
new_axes=copyobj(main_axes,new_fig);
set(new_axes,'units','norm','XAxisLocation','bottom','XTickLabelRotation',90,'outerposition',[0 0 1 1],'YTickLabel',vaxes.YTickLabel,'XTickLabel',haxes.XTickLabel);

layers_Str=list_layers(layer,'nb_char',80);
title(new_axes,sprintf('%s : %s',deblank(trans_obj.Config.ChannelID),layers_Str{1}),'interpreter','none');
cb=colorbar(new_axes);
cb.UIContextMenu=[];
format_color_gui(new_fig,curr_disp.Font,curr_disp.Cmap,1);

text_obj=findobj(new_fig,'-property','Fontsize');
set(text_obj,'Fontsize',12);

line_obj=findobj(new_fig,'Type','Line');
set(line_obj,'Linewidth',1.5);

linkprop([axes_panel_comp.main_axes new_axes],{'YColor','XColor','GridLineStyle','XTick','Clim','GridColor','MinorGridColor','YDir'});

drawnow;

switch fileN
    case '-clipboard'
         print(new_fig,'-clipboard','-dbitmap');
         %hgexport(new_fig,'-clipboard');
         delete(new_fig);
         disp_done_figure(main_figure,'Echogram copied to clipboard...');
    otherwise
        if isempty(path_echo)
            [path_echo,~,~]=fileparts(layer.Filename{1});
        end
        
        if isempty(fileN)
            fileN=[layers_Str{1} '.png'];
        end
        
        print(new_fig,fullfile(path_echo,fileN),'-dpng','-r300');
        disp_done_figure(main_figure,'Finished, Echogram has been saved... Check it and close the figure, otherwise, get a screenshot of the new figure...');
end


end